### BASH SCRIPT SETUP ##############################################################################
export DEBIAN_FRONTEND=noninteractive
arch="amd64"
arch_options=("amd64" "arm64" "riscv64")
os_codename="$(. /etc/os-release && echo $VERSION_CODENAME)"
os_codename_options=("noble")
ros_distro="rolling"
ros_distro_options=("rolling" "jazzy")
src_dir="."
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

# Add ROS Repo
## Install ROS deps
pkgs=("software-properties-common" "curl")
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
if [[ ! -f /usr/share/keyrings/ros-archive-keyring.gpg || ! -f /etc/apt/sources.list.d/ros2.list ]]; then
  echo "Adding ROS Repo"
  runSudo add-apt-repository -y universe
  runSudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | runSudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
fi

# Install application(s)
pkgs=("sbuild" "ubuntu-dev-tools" "ros-dev-tools" "python3-bloom" "python3-rosdep" "fakeroot" "debhelper" "dh-python" "ros-$ros_distro-ros-base")
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

cd $src_dir || { echo "Failed to change directory to $src_dir"; exit 1; }

source "/opt/ros/$ros_distro/setup.bash"

rosdep install --from-paths . --ignore-src --rosdistro "$ros_distro" -y || runSudo rosdep init && rosdep update && rosdep install --from-paths . --ignore-src --rosdistro "$ros_distro" -y

bloom-generate rosdebian

dch -i   # Increment the Debian changelog without a message
sbuild -d "$os_codename-$arch" --no-create -j8

echo "$0 FINISHED"
