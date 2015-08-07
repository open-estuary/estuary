#!/bin/bash
#author: justin.zhao
#date: March 2, 2015

TOOLCHAIN_DIR=toolchain
DISTRO_DIR=distro
BINARY_DIR=binary
GCC32=gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux.tar.xz
GCC64=gcc-linaro-aarch64-linux-gnu-4.9-2014.09_linux.tar.xz

# obtain toolchains
if [ ! -d "$TOOLCHAIN_DIR" ]; then
mkdir -p "$TOOLCHAIN_DIR" 2> /dev/null

curl http://releases.linaro.org/14.09/components/toolchain/binaries/$GCC32 > ./$TOOLCHAIN_DIR/$GCC32
curl http://releases.linaro.org/14.09/components/toolchain/binaries/$GCC64 > ./$TOOLCHAIN_DIR/$GCC64
fi

#Install some dependencies about grub for ubuntu/debian
sudo apt-get build-dep grub -y
sudo apt-get install build-essential automake -y

#Install some dependencies about uefi for ubuntu/debian
sudo apt-get install uuid-dev build-essential gcc-arm-linux-gnueabi
sudo apt-get install gcc-arm-linux-gnueabihf

