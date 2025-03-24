#!/bin/bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

cd $1 || { echo "Failed to change directory to $1"; exit 1; }

# Check if debian directory exists, if not, create it
if [ ! -d "debian" ]; then
  echo "Creating debian directory..."
  mkdir debian
fi

# Create the debian/rules file
cat << 'EOF' > debian/rules
#!/usr/bin/make -f

# Uncomment this to turn on verbose mode.
#export DH_VERBOSE=1

%:
	dh $@ --no-source
EOF

# Make sure the rules file is executable
chmod +x debian/rules

# Create the debian/compat file with compatibility level 10 (adjustable)
echo "13" > debian/compat

# Make sure the compat file is executable
chmod +x debian/compat

cd -

if [[ -f "${script_dir}"/init-debian-changelog.bash ]]; then
  echo "Running init-debian-changelog.bash..."
  "${script_dir}"/init-debian-changelog.bash "$1" "$2"
else
  echo "Error: init-debian-changelog.bash not found."
fi

sleep 1

echo "$0 FINISHED"
