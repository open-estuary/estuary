#!/bin/bash

KERNEL_DIR=kernel
LOCALARCH=`uname -m`

###################################################################################
# install arguments
###################################################################################
CROSS_COMPILE=
KERNEL_DIR=
ROOTFS=
CROSS=

###################################################################################
# build_modules_usage
###################################################################################
build_modules_usage()
{
cat << EOF
Usage: build-modules.sh --kerneldir=xxx --rootfs=xxx --cross=xxx
    --kerneldir: kernel target object directory
    --rootfs: target reoof file system directory to install modules and firmware
    --cross: cross compile prefix (if the host is not arm architecture, it must be specified.)

Example:
    build-modules.sh --kerneldir=./workspace/kernel --rootfs=./workspace/distro/Ubuntu
    build-modules.sh --kerneldir=./workspace/kernel --rootfs=./workspace/distro/Ubuntu --cross=aarch64-linux-gnu-

EOF
}

###################################################################################
# build_modules <kernel_dir> <rootfs> <cross>
###################################################################################
build_modules()
{
    (
    output_dir=$(cd $1; pwd)
    rootfs=$(cd $2; pwd)
    cross_compile=$3
    core_num=`cat /proc/cpuinfo | grep "processor" | wc -l`

    export ARCH=arm64
    export CROSS_COMPILE=$cross_compile
    mkdir -p $output_dir/kernel
    kernel_dir=$(cd $output_dir/kernel; pwd)

    pushd kernel
    make O=$kernel_dir estuary_defconfig
    make O=$kernel_dir include/config/kernel.release
    kernel_version=$(cat $kernel_dir/include/config/kernel.release)
    popd
    if [ ! -d "${rootfs}/lib/modules/${kernel_version}" ]; then
        pushd kernel
        make O=$kernel_dir -j${core_num} -s modules INSTALL_MOD_PATH=$rootfs \
        && make PATH=$PATH O=$kernel_dir -j${core_num} -s INSTALL_MOD_STRIP=1 modules_install INSTALL_MOD_PATH=$rootfs
        if [ ! $? ]; then
            return 1
        fi
        popd
    fi

    return 0
    )
}

###################################################################################
# get args
###################################################################################
while test $# != 0
do
    case $1 in
        --*=*) ac_option=`expr "X$1" : 'X\([^=]*\)='` ; ac_optarg=`expr "X$1" : 'X[^=]*=\(.*\)'` ;;
        *) ac_option=$1 ;;
    esac

    case $ac_option in
    --kerneldir) KERNEL_DIR=$ac_optarg ;;
            --rootfs) ROOTFS=$ac_optarg ;;
    --cross) CROSS=$ac_optarg ;;
            *) echo -e "\033[31mUnknown option $ac_option!\033[0m"
        build_modules_usage ; exit 1 ;;
    esac

    shift
done

###################################################################################
# Check args
###################################################################################
if [ x"$LOCALARCH" = x"x86_64" ] && [ x"" = x"$CROSS" ]; then
    echo -e "\033[31mError! Cross compile must be specified!\033[0m"
        build_modules_usage ; exit 1
fi

if [ -z $KERNEL_DIR ] || [ -z $ROOTFS ]; then
    echo -e "\033[31mError! kernel dir and rootfs must be specified!\033[0m"
    build_modules_usage ; exit 1
fi

if [ ! -d $KERNEL_DIR ] || [ ! -d $ROOTFS ]; then
    echo -e "\033[31mError! Please check kernel object directory and rootfs directory exist!\033[0m" ; exit 1
fi

###################################################################################
# build and install modules
###################################################################################
if build_modules $KERNEL_DIR $ROOTFS $CROSS; then
    exit 0
else
    exit 1
fi

