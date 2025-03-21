#!/bin/bash

### BASH SCRIPT SETUP ##############################################################################
export DEBIAN_FRONTEND=noninteractive
arch="amd64"
arch_options=("amd64" "arm64" "riscv64")
os_codename="$(. /etc/os-release && echo $VERSION_CODENAME)"
os_codename_options=("noble")
proxy=""
help_prompt=$(cat <<EOF
Usage: $0 [OPTIONS]

Options:
  -a, --arch          Host architecture for which the package is being built (default: $arch) [${arch_options[*]}]
  -o, --os-codename   Debian/Ubuntu distribution (default: $os_codename) [${os_codename_options[*]}]
  -p, --proxy         Proxy address for debootstrap (default: $proxy) [ie: "http://<proxy-ip>:<proxy-port>"]
  -h, --help          Show this help message and exit

Example:
  $0 -h

Notes: Enables cross-arch package builds via sbuild to create a dedicated clean build environment using chroot, to 
---
EOF
)
while [[ "$#" -gt 0 ]]; do # Parse command line arguments and override defaults as required
    case $1 in
        # --special-arg) SPECIAL_ARG="$2"; shift ;;   # Handle `--<option> <value>`
        -a|--arch) arch="$2"; shift ;;
        -d|--os-codename) os_codename="$2"; shift ;;
        -p|--proxy) proxy="$2"; shift ;;
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
# set -x # print each command and its arguments as they are executed
### END BASH SCRIPT SETUP ##########################################################################

# Guard on valid options
if [[ ! " ${arch_options[*]} " =~ $arch ]]; then
  echo "Invalid architecture: $arch"
  exit 1
fi
if [[ ! " ${os_codename_options[*]} " =~ $os_codename ]]; then
  echo "Invalid distribution: $os_codename"
  exit 1
fi
if [[ -n $proxy ]]; then
  # Conditionally enable debootstrap proxy
  export DEBOOTSTRAP_PROXY=$proxy
fi

# Install application(s)
pkgs=("debhelper" "sbuild" "schroot" "debootstrap" "ubuntu-dev-tools")
for pkg in "${pkgs[@]}"; do
  if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
      echo "$pkg is already installed."
  else
      echo "$pkg is not installed. Installing now..."
      sudo apt-get update
      sudo apt-get install -y "$pkg"
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
    sg $group
fi

# List available chroots
echo "Existing chroots (/var/lib/schroot/chroots/):"
if [[ -d /var/lib/schroot/chroots/ ]]; then
  ls /var/lib/schroot/chroots/
fi

# Create the schroots
echo "Running: mk-sbuild --arch=${arch} $os_codename"
mk-sbuild "--arch=${arch}" "$os_codename"

# List available chroots
echo "Available chroots (/var/lib/schroot/chroots/):"
ls /var/lib/schroot/chroots/

echo "$0 FINISHED"
