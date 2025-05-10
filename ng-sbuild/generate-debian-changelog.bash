#!/bin/bash

### BASH SCRIPT SETUP ##############################################################################
export DEBIAN_FRONTEND=noninteractive
arch="amd64" # Host architecture (Arch we are building for)
arch_options=("amd64" "arm64" "riscv64")
os_codename="$(. /etc/os-release && echo $VERSION_CODENAME)"
os_codename_options=("noble")
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
src_dir="."
help_prompt=$(cat <<EOF
Usage: $0 [OPTIONS]

Options:
  -a, --arch          Host architecture for which the package is being built (default: $arch) [${arch_options[*]}]
  -o, --os-codename   Debian/Ubuntu distribution (default: $os_codename) [${os_codename_options[*]}]
  -s, --src           Source directory (default: $src_dir)
  -h, --help          Show this help message and exit

Example:
  $0 -h
---
EOF
)
while [[ "$#" -gt 0 ]]; do # Parse command line arguments and override defaults as required
    case $1 in
        # --special-arg) SPECIAL_ARG="$2"; shift ;;   # Handle `--<option> <value>`
        # -a|--arch) arch="$2"; shift ;;
        -o|--os-codename) os_codename="$2"; shift ;;
        -s|--src) src_dir="$2"; shift ;;
        -h|--help) echo "$help_prompt"; exit 0 ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    #shellcheck disable=SC2317
    shift
done
echo "$help_prompt" # Always remind the user of this scripts usage
# Func runs given command with sudo if not already root, allows for running without
# sudo in a root context (ie. in docker containers). Falls back to sudo on error
# shellcheck disable=SC2015
function runSudo(){ [[ "${USER:-root}" == "root" ]] && "$@" || sudo "$@"; }
set -x # print each command and its arguments as they are executed
set -euo pipefail
### END BASH SCRIPT SETUP ##########################################################################

cd "$src_dir" || { echo "Failed to change directory to $src_dir"; exit 1; }

CONTROL_FILE="debian/control"
CHANGELOG_FILE="debian/changelog"
DEFAULT_VERSION="0.1.0-1"
DEFAULT_DIST="$os_codename"
DEFAULT_URGENCY="medium"
DEFAULT_MESSAGE="Initial release"

# Extract package name and maintainer from control file
if [[ ! -f $CONTROL_FILE ]]; then
  echo "Error: debian/control not found."
  exit 1
fi
PACKAGE_NAME="$(grep -m1 '^Source:' "$CONTROL_FILE" | cut -d ':' -f2- | xargs)"
MAINTAINER="$(grep -m1 '^Maintainer:' "$CONTROL_FILE" | cut -d ':' -f2- | xargs)"
EMAIL=$(echo "$MAINTAINER" | grep -oP '(?<=<)[^>]+(?=>)') # Extract email (text between < and >)
NAME=$(echo "$MAINTAINER" | sed -E "s/ <$EMAIL>//") # Extract name (everything before the email part)
# Set required environment variables
if [ -n "$NAME" ]; then
    export DEBFULLNAME="$NAME"
    echo "Set DEBFULLNAME to '$DEBFULLNAME'"
fi
if [ -n "$EMAIL" ]; then
    export DEBEMAIL="$EMAIL"
    echo "Set DEBEMAIL to '$DEBEMAIL'"
fi

# Get the latest tag or default to 0.1.0-1
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "$DEFAULT_VERSION")
LATEST_COMMIT_DATE=$(git log -1 --format=%cd --date=format:'%a, %d %b %Y %H:%M:%S %z')
# Update the Debian revision (e.g., 1.0.0-YYYYMMDD.HHMMSS → 1.0.0-YYYYMMDD.HHMMSS)
BASE_VERSION=$(echo "$LATEST_TAG" | cut -d '-' -f1)
NEW_VERSION="${BASE_VERSION}-$(date +"%Y%m%d.%H%M%S")"

# Override the default message with the latest commit messages
while read -r commit; do
  DEFAULT_MESSAGE="$commit"
  break
done < <(git log --oneline)

# If changelog exists, update the Debian revision
if [[ -f $CHANGELOG_FILE ]]; then
  echo "Changelog already exists at $CHANGELOG_FILE"

  echo "Updating version to $NEW_VERSION..."

  # Update the changelog using dch
  dch -v "$NEW_VERSION" -D "$DEFAULT_DIST" -M "$DEFAULT_MESSAGE $LATEST_COMMIT_DATE"

else
  # Create the changelog with the new version tag as the base version
  echo "Creating changelog for package '$PACKAGE_NAME' with version $NEW_VERSION..."

  # Create the changelog using dch
  dch --create \
      -v "$NEW_VERSION" \
      --package "$PACKAGE_NAME" \
      -D "$DEFAULT_DIST" \
      -M "$DEFAULT_MESSAGE $LATEST_COMMIT_DATE"
fi

# Set the date and maintainer in the latest changelog entry
dch --release ""

echo "Changelog updated successfully with version $NEW_VERSION."

cd -

echo "$0 FINISHED"
