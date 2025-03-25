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

cd "$src_dir" || { echo "Failed to change directory to ${src_dir}"; exit 1; }

# Check if debian directory exists, if not, create it
if [[ ! -d "debian" ]]; then
  echo "Creating debian directory..."
  mkdir -p debian
fi

# setup debian/control
if [[ ! -f "debian/control" ]]; then
  pkg_name=$(basename "$src_dir" | tr ' _' '-') # Extract the last directory name and replace underscores and spaces with hyphens
  cat << EOF > debian/control
Source: $pkg_name
Section: misc
Priority: optional
Maintainer: Nathanael Gandhi <nat11public@gmail.com>
Build-Depends:
Standards-Version: 4.7.2

Package: $pkg_name
Architecture: any
Depends:
Description: Hello World test package
EOF
else
  echo "debian/control already exists, skipping..."
fi

# Create the debian/rules file
if [[ ! -f "debian/rules" ]]; then
  cat << 'EOF' > debian/rules
#!/usr/bin/make -f

# Uncomment this to turn on verbose mode.
#export DH_VERBOSE=1

%:
	dh $@ --no-source
EOF
  # Make sure the rules file is executable
  chmod +x debian/rules
else
  echo "debian/rules already exists, skipping..."
fi

# Create the debian/compat file
if [[ ! -f "debian/compat" ]]; then
  # Create the debian/compat file with compatibility level 13 (adjustable)
  echo "13" > debian/compat

  # Make sure the compat file is executable
  chmod +x debian/compat
else
  echo "debian/compat already exists, skipping..."
fi

cd -

if [[ -f "${script_dir}"/generate-debian-changelog.bash ]]; then
  echo "Running generate-debian-changelog.bash..."
  "${script_dir}"/generate-debian-changelog.bash --src "$src_dir" --os-codename "$os_codename"
else
  echo "Error: generate-debian-changelog.bash not found." && exit 1
fi

echo "$0 FINISHED"
