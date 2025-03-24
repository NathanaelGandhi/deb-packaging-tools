#!/bin/bash
set -e

cd $1 || { echo "Failed to change directory to $1"; exit 1; }

CONTROL_FILE="debian/control"
CHANGELOG_FILE="debian/changelog"
DEFAULT_VERSION="0.1.0-1"
DEFAULT_DIST="$2"
DEFAULT_URGENCY="medium"
DEFAULT_MESSAGE="Initial release"

# Extract package name and maintainer from control file
if [[ ! -f $CONTROL_FILE ]]; then
  echo "Error: debian/control not found."
  exit 1
fi
PACKAGE_NAME="$(grep -m1 '^Source:' "$CONTROL_FILE" | cut -d ':' -f2- | xargs)"
MAINTAINER="$(grep -m1 '^Maintainer:' "$CONTROL_FILE" | cut -d ':' -f2- | xargs)"

# Get the latest tag or default to 0.1.0-1
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "$DEFAULT_VERSION")
LATEST_COMMIT_DATE=$(git log -1 --format=%cd --date=format:'%a, %d %b %Y %H:%M:%S %z')
# Update the Debian revision (e.g., 1.0.0-YYYYMMDD.HHMMSS → 1.0.0-YYYYMMDD.HHMMSS)
BASE_VERSION=$(echo "$LATEST_TAG" | cut -d '-' -f1)
NEW_VERSION="${BASE_VERSION}-$(date +'%Y%m%d.%H%M%S')"

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
  dch -v "$NEW_VERSION" -D "$DEFAULT_DIST" -M "$DEFAULT_MESSAGE"

else
  # Create the changelog with the new version tag as the base version
  echo "Creating changelog for package '$PACKAGE_NAME' with version $NEW_VERSION..."

  # Create the changelog using dch
  dch --create \
      -v "$NEW_VERSION" \
      --package "$PACKAGE_NAME" \
      -D "$DEFAULT_DIST" \
      -M "$DEFAULT_MESSAGE"

fi

# Set the date and maintainer in the latest changelog entry
sed -i "s/ -- .*$/ -- $MAINTAINER  $LATEST_COMMIT_DATE/" "$CHANGELOG_FILE"

echo "Changelog updated successfully with version $NEW_VERSION."

cd -

echo "$0 FINISHED"
