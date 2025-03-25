#!/bin/bash

### BASH SCRIPT SETUP ##############################################################################
export DEBIAN_FRONTEND=noninteractive
arch="amd64" # Host architecture (Arch we are building for)
arch_options=("amd64" "arm64" "riscv64")
os_codename="$(. /etc/os-release && echo $VERSION_CODENAME)"
os_codename_options=("noble")
proxy=""
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
src_dir="."
help_prompt=$(cat <<EOF
Usage: $0 [OPTIONS]

Options:
  -a, --arch          Host architecture for which the package is being built (default: $arch) [${arch_options[*]}]
  -o, --os-codename   Debian/Ubuntu distribution (default: $os_codename) [${os_codename_options[*]}]
  -p, --proxy         Proxy address for debootstrap (default: $proxy) [ie: "http://<proxy-ip>:<proxy-port>"]
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
        -a|--arch) arch="$2"; shift ;;
        -o|--os-codename) os_codename="$2"; shift ;;
        -p|--proxy) proxy="$2"; shift ;;
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
# set -x # print each command and its arguments as they are executed
### END BASH SCRIPT SETUP ##########################################################################

# Guard on valid options
if [[ ! " ${arch_options[*]} " =~ $arch ]]; then
  echo "Unsupported architecture: $arch"
  exit 1
fi
if [[ ! " ${os_codename_options[*]} " =~ $os_codename ]]; then
  echo "Unsupported os_codename: $os_codename"
  exit 1
fi

# build cpp package
mkdir -p "${src_dir}/build"
cd "${src_dir}/build" || { echo "Failed to change directory to ${src_dir}/build"; exit 1; }
cmake ..
make DESTDIR="$(pwd)/../" install
cd -

# setup build env
cmd="${script_dir}/create-schroots.bash"
cmd+=" --arch $arch"
cmd+=" --os-codename $os_codename"
if [ -n "$proxy" ]; then
  cmd+=" --proxy \"$proxy\""
fi
eval "$cmd" # Execute command

# build source & binary packages
cmd="${script_dir}/sbuild-sourcebinary.bash"
cmd+=" --host $arch"
cmd+=" --os-codename $os_codename"
cmd+=" --src $src_dir"
if [ -n "$proxy" ]; then
  cmd+=" --proxy \"$proxy\""
fi
eval "$cmd" # Execute command

echo "$0 FINISHED"
