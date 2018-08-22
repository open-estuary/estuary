#!/bin/bash
set -ex

build_dir=$(cd $2 && pwd) # build workspace
version=$1 # branch or tag
version=${version:-master}

TOPDIR=$(cd `dirname $0` ; pwd)
LOCALARCH=`uname -m`

###################################################################################
# Include
###################################################################################
. $TOPDIR/submodules-common.sh

###################################################################################
# build arguments
###################################################################################
OUTPUT_DIR=${TOPDIR}/../../common
BINARY_DIR=${build_dir}/out/release/${version}/binary/arm64
SOURCE_DIR=${TOPDIR}/../../kernel

###################################################################################
# Check args
###################################################################################
if [ x"$LOCALARCH" = x"x86_64" ]; then
    CROSS_COMPILE="aarch64-linux-gnu-"
    if [ x"$CROSS_COMPILE" != x"" ]; then
        export CROSS_COMPILE=$CROSS_COMPILE
    else
        echo -e "\033[31mError! --cross must be specified!\033[0m"
        exit 1
    fi
fi

###################################################################################
# build_kernel <output_dir>
###################################################################################
build_kernel()
{
    (
    output_dir=$1
    core_num=`cat /proc/cpuinfo | grep "processor" | wc -l`

    export ARCH=arm64
    rm -rf $output_dir/kernel
    kernel_dir=$output_dir/kernel
    kernel_bin=$kernel_dir/arch/arm64/boot/Image

    pushd $SOURCE_DIR
    make O=$kernel_dir estuary_defconfig
    make O=$kernel_dir -j${core_num} -s ${kernel_bin##*/}
    popd

    )
}
rsync_kernel()
{
    (
    output_dir=$1
    kernel_dir=$output_dir/kernel
    kernel_bin=$kernel_dir/arch/arm64/boot/Image

    mkdir -p $BINARY_DIR 2>/dev/null
    cp -f $kernel_bin $kernel_dir/{vmlinux,System.map} $BINARY_DIR
    return 0

    )
}

###################################################################################
# build_check  <output_dir>
###################################################################################
build_check()
{
    (
    output_dir=$1
    kernel_dir=$output_dir/kernel

    if [ ! -f $kernel_dir/arch/arm64/boot/Image ] || [ ! -f $BINARY_DIR/Image ] \
        || [ ! -f $kernel_dir/vmlinux ] || [ ! -f $BINARY_DIR/vmlinux ] \
        || [ ! -f $kernel_dir/System.map ] || [ ! -f $BINARY_DIR/System.map ]; then
        return 1
    fi

    return 0
    )
}

###################################################################################
# Build kernel
###################################################################################
# check update
mkdir -p $OUTPUT_DIR/kernel && cd $OUTPUT_DIR
if update_module_check kernel $OUTPUT_DIR && rsync_kernel $OUTPUT_DIR ; then
    exit 0
fi

# build kernel and check result
rm_module_build_log kernel $OUTPUT_DIR
if build_kernel $OUTPUT_DIR && rsync_kernel $OUTPUT_DIR && build_check $OUTPUT_DIR; then
    gen_module_build_log kernel $OUTPUT_DIR ; exit 0
else
    exit 1
fi
