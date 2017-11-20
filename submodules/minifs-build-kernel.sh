#!/bin/bash
set -ex

build_dir=$(cd /root/$2 && pwd) # build workspace
version=$1 # branch or tag
version=${version:-master}

TOPDIR=$(cd `dirname $0` ; pwd)
distro_dir=${build_dir}/tmp/minifs
workspace=${distro_dir}/kernel

###################################################################################
# Include
###################################################################################
. $TOPDIR/submodules-common.sh

###################################################################################
# build arguments
###################################################################################
OUTPUT_DIR=${build_dir}/out/release/${version}
KERNEL_DIR=${workspace}/kernel

# Checkout source code
mkdir -p ${workspace} && cd ${workspace}
rsync -avq $build_dir/../kernel/ ${KERNEL_DIR}

###################################################################################
# build_kernel <output_dir>
###################################################################################
build_kernel()
{
    (
    output_dir=$1
    core_num=`cat /proc/cpuinfo | grep "processor" | wc -l`

    export ARCH=arm64
    mkdir -p $output_dir/kernel
    kernel_dir=$(cd $output_dir/kernel; pwd)
    kernel_bin=$kernel_dir/arch/arm64/boot/Image

    pushd $KERNEL_DIR
    make O=$kernel_dir estuary_defconfig
    make O=$kernel_dir -j${core_num} ${kernel_bin##*/}

    pwd
    popd

    mkdir -p $output_dir/binary/arm64/ 2>/dev/null
    cp $kernel_bin $output_dir/binary/arm64/
    cp $kernel_dir/vmlinux $output_dir/binary/arm64/
    cp $kernel_dir/System.map $output_dir/binary/arm64/

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

    if [ ! -f $kernel_dir/arch/arm64/boot/Image ] || [ ! -f $output_dir/binary/arm64/Image ] \
        || [ ! -f $kernel_dir/vmlinux ] || [ ! -f $output_dir/binary/arm64/vmlinux ] \
        || [ ! -f $kernel_dir/System.map ] || [ ! -f $output_dir/binary/arm64/System.map ]; then
        return 1
    fi

    return 0
    )
}

###################################################################################
# Build kernel
###################################################################################
# check update
if build_check $OUTPUT_DIR && update_module_check kernel $OUTPUT_DIR; then
    exit 0
fi

# build kernel and check result
rm_module_build_log kernel $OUTPUT_DIR
if build_kernel  $OUTPUT_DIR && build_check $OUTPUT_DIR; then
    gen_module_build_log kernel $OUTPUT_DIR ; rm -rf $OUTPUT_DIR/kernel ; exit 0
else
    exit 1
fi
