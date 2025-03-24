#!/bin/bash

### BASH SCRIPT SETUP ##############################################################################
export DEBIAN_FRONTEND=noninteractive
arch="amd64"
arch_options=("amd64" "arm64" "riscv64")
os_codename="$(. /etc/os-release && echo $VERSION_CODENAME)"
os_codename_options=("noble")
ros_distro="rolling"
ros_distro_options=("rolling" "jazzy")
src_dir="."
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
help_prompt=$(cat <<EOF
Usage: $0 [OPTIONS]

Options:
  -a, --arch          Host architecture for which the package is being built (default: $arch) [${arch_options[*]}]
  -o, --os-codename   Debian/Ubuntu distribution (default: $os_codename) [${os_codename_options[*]}]
  -r, --ros-distro    ROS distribution (default: $ros_distro) [${ros_distro_options[*]}]
  -s, --src           Source directory (default: $src_dir)
  -h, --help          Show this help message and exit

Example:
  $0 -h

Notes: Enables cross-arch package builds via a pre-built sbuild chroot
---
EOF
)
while [[ "$#" -gt 0 ]]; do # Parse command line arguments and override defaults as required
    case $1 in
        # --special-arg) SPECIAL_ARG="$2"; shift ;;   # Handle `--<option> <value>`
        -a|--arch) arch="$2"; shift ;;
        -o|--os-codename) os_codename="$2"; shift ;;
        -r|--ros-distro) ros_distro="$2"; shift ;;
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
### END BASH SCRIPT SETUP ##########################################################################

# Install application(s)
pkgs=("sbuild" "ubuntu-dev-tools" "debhelper")
for pkg in "${pkgs[@]}"; do
  if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
      echo "$pkg is already installed."
  else
      echo "$pkg is not installed. Installing now..."
      runSudo apt-get update
      runSudo apt-get install -y "$pkg"
  fi
  # Guard on successful application install
  if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
    echo "Error: Installing $pkg"
    exit 1
  fi
done

# Check if the user is in the group
group="sbuild"
if id -nG "$USER" | grep -qw "$group"; then
  echo "User $USER is already a member of the $group group."
else
  echo "User $USER is not in the $group group. Adding..."
  runSudo usermod -aG "$group" "$USER"
  echo "User $USER has been added to the $group group."
  echo "Note: You will need to rerun this script to continue..."
  sg $group
fi

bash "${script_dir}"/generate-debian-files.bash "$src_dir" "$os_codename"

cd "$src_dir" || { echo "Failed to change directory to $src_dir"; pwd; exit 1; }

# dpkg-buildpackage -S -d -us -uc
if [[ ! -d sbuild ]]; then
  mkdir -p sbuild
fi

# https://manpages.debian.org/buster/sbuild/sbuild.1.en.html
sbuild \
  --dist="$os_codename" \
  --chroot="$os_codename-$arch" \
  -j8 \
  --source \
  --verbose \
  --build-dir=sbuild \
  --no-run-lintian \
  --debbuildopt=--no-check-builddeps --debbuildopt=--no-sign
# dpkg-buildpackage args: --no-check-builddeps --no-sign
# --extra-package=package.deb|directory
# sbuild -d "$os_codename-$arch" -j8 --source --verbose --run-lintian --add-depends=debhelper --add-depends=cmake --build-dir=build --dsc-dir=dsc

cd -

echo "$0 FINISHED"
