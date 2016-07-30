#!/bin/bash

KERNEL_DIR=kernel
LOCALARCH=`uname -m`
TOPDIR=$(cd `dirname $0` ; pwd)

###################################################################################
# Include
###################################################################################
. $TOPDIR/submodules-common.sh

###################################################################################
# build arguments
###################################################################################
PLATFORM=
CROSS_COMPILE=
OUTPUT_DIR=
CLEAN=

###################################################################################
# target files
###################################################################################
HiKey_DTB="hi6220-hikey.dtb"
D02_DTB="hip05-d02.dtb"
D03_DTB="hip06-d03.dtb"

###################################################################################
# build_kernel_usage
###################################################################################
build_kernel_usage()
{
cat << EOF
Usage: build-kernel.sh [clean] --platform=xxx --cross=xxx --output=xxx
	clean: clean the kernel binary files (include dtb)
	--platform: which platform to build (D02, D03, HiKey, QEMU)
	--cross: cross compile prefix (if the host is not arm architecture, it must be specified.)
	--output: target binary output directory

Example:
	build-kernel.sh --platform=HiKey --output=workspace
	build-kernel.sh --platform=HiKey --output=workspace --cross=aarch64-linux-gnu-
	build-kernel.sh --platform=D02 --output=workspace
	build-kernel.sh --platform=D02 --output=workspace --cross=aarch64-linux-gnu-
	build-kernel.sh clean --platform=HiKey --output=workspace

EOF
}

###################################################################################
# build_kernel <platform> <output_dir>
###################################################################################
build_kernel()
{
	(
	platform=$1
	output_dir=$2
	core_num=`cat /proc/cpuinfo | grep "processor" | wc -l`

	export ARCH=arm64
	mkdir -p $output_dir/kernel
	kernel_dir=$(cd $output_dir/kernel; pwd)
	kernel_bin=$kernel_dir/arch/arm64/boot/Image

	pushd $KERNEL_DIR
	./scripts/kconfig/merge_config.sh -O $kernel_dir -m arch/arm64/configs/defconfig \
		arch/arm64/configs/distro.config arch/arm64/configs/estuary_defconfig
	mv -f $kernel_dir/.config $kernel_dir/.merged.config
	make O=$kernel_dir KCONFIG_ALLCONFIG=$kernel_dir/.merged.config alldefconfig
	make O=$kernel_dir -j${core_num} ${kernel_bin##*/}

	# build dtb
	eval dtb_bin=$kernel_dir/arch/arm64/boot/dts/hisilicon/\$${platform}_DTB
	if [ x"$dtb_bin" != x"" ]; then
		make O=$kernel_dir ${dtb_bin#*/boot/dts/}
	fi
	popd

	mkdir -p $output_dir/binary/arm64/ 2>/dev/null
	cp $kernel_bin $output_dir/binary/arm64/

	if [ x"$dtb_bin" != x"" ]; then
		mkdir -p $output_dir/binary/$platform/
		cp $dtb_bin $output_dir/binary/$platform/
	fi
	)
}

###################################################################################
# build_check <platform> <output_dir>
###################################################################################
build_check()
{
	(
	platform=$1
	output_dir=$2
	if [ x"$platform" != x"qemu" ]; then
		kernel_dir=$output_dir/kernel
		eval dtb_bin=\$${platform}_DTB
		if [ x"$dtb_bin" != x"" ] && [ ! -f $output_dir/binary/$platform/$dtb_bin ]; then
			return 1
		fi
	else
		kernel_dir=$output_dir/kernel_qemu
		if [ ! -f $output_dir/binary/arm64/Image_QEMU ]; then
			return 1
		fi
	fi

	if [ ! -f $kernel_dir/arch/arm64/boot/Image ]; then
		return 1
	fi

	return 0
	)
}

###################################################################################
# clean_kernel <platform> <output_dir>
###################################################################################
clean_kernel()
{
	(
	platform=$1
	output_dir=$2

	echo "Clean kernel ......"
	eval dtb_bin=\$${platform}_DTB

	if [ x"$dtb_bin" != x"" ]; then
		rm -f $output_dir/binary/$platform/$dtb_bin
	fi

	if [ x"$platform" = x"QEMU" ]; then
		sudo rm -rf $output_dir/kernel-qemu
		rm -f $output_dir/binary/$platform/Image_$platform
	else
		sudo rm -rf $output_dir/kernel
		rm -f $output_dir/binary/arm64/Image
	fi
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
                clean) CLEAN="yes" ;;
                --platform) PLATFORM=$ac_optarg ;;
		--cross) CROSS_COMPILE=$ac_optarg ;;
                --output) OUTPUT_DIR=$ac_optarg ;;
                *) build_kernel_usage ; exit 1 ;;
        esac

        shift
done

###################################################################################
# Check args
###################################################################################
if [ x"" = x"$PLATFORM" ] || [ x"" = x"$OUTPUT_DIR" ]; then
        build_kernel_usage ; exit 1
fi

if [ x"$LOCALARCH" = x"x86_64" ]; then
	if [ x"$CROSS_COMPILE" != x"" ]; then
		export CROSS_COMPILE=$CROSS_COMPILE
	else
		echo -e "\033[31mError! --cross must be specified!\033[0m"
		build_kernel_usage ; exit 1
	fi
fi

###################################################################################
# Clean kernel
###################################################################################
if [ x"yes" = x"$CLEAN" ]; then
	gen_module_build_log kernel $OUTPUT_DIR
        clean_kernel $PLATFORM $OUTPUT_DIR
	exit 0
fi

###################################################################################
# Build kernel
###################################################################################
# check update
if build_check $PLATFORM $OUTPUT_DIR && update_module_check kernel $OUTPUT_DIR; then
	exit 0
fi

# build kernel and check result
rm_module_build_log kernel $OUTPUT_DIR
if build_kernel $PLATFORM $OUTPUT_DIR && build_check $PLATFORM $OUTPUT_DIR; then
	gen_module_build_log kernel $OUTPUT_DIR ; exit 0
else
	exit 1
fi

