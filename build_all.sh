#!/bin/bash
set -ex
user=`whoami`
if [ x"$user" != x"root" ]; then
    echo -e "\033[31mInsufficient permissions! please use sudo to run script!\033[0m"
    exit 1
fi
ALL_SHELL_DISTRO="centos fedora ubuntu opensuse debian"
BUILD_DIR="./workspace"
for DISTRO in $ALL_SHELL_DISTRO;do
    ./build.sh --build_dir=${BUILD_DIR} -d "${DISTRO,,}" > ${DISTRO}.log 2>&1 &
done
./build.sh --build_dir=${BUILD_DIR} -d common > common.log 2>&1 &
wait
