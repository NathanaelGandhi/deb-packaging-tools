#!/bin/bash

set -x

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
src_dir=$1

# build package
mkdir -p "${src_dir}/build"
cd "${src_dir}/build" || { echo "Failed to change directory to ${src_dir}/build"; exit 1; }
cmake ..
make DESTDIR="$(pwd)/../" install
cd -

# setup build env
"${script_dir}"/create-schroots.bash

# setup debian/control
cd "$src_dir" || { echo "Failed to change directory to ${src_dir}"; exit 1; }
mkdir -p debian
cat << 'EOF' > debian/control
Source: hello-world-cpp
Maintainer: Nathanael Gandhi <nat11public@gmail.com>
Priority: optional
Standards-Version: 4.7.2

Package: hello-world-cpp
Architecture: any
Depends:
Description: Hello World test package
EOF
cd -

# build source & binary packages
"${script_dir}"/sourcedeb.bash --src "$src_dir"


echo "$0 FINISHED"
