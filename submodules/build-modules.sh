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
	build-modules.sh --kerneldir=build/kernel --rootfs=build/distro/Ubuntu
	build-modules.sh --kerneldir=build/kernel --rootfs=build/distro/Ubuntu --cross=aarch64-linux-gnu-

EOF
}

###################################################################################
# build_modules <kernel_dir> <rootfs> <cross>
###################################################################################
build_modules()
{
	(
	kernel_dir=$(cd $1; pwd)
	rootfs=$(cd $2; pwd)
	cross_compile=$3
	core_num=`cat /proc/cpuinfo | grep "processor" | wc -l`

	modules_file=`find ${rootfs}/lib/modules -name modules.dep 2>/dev/null`
	if [ x"$modules_file" = x"" ]; then
		pushd kernel
		make ARCH=arm64 CROSS_COMPILE=$cross_compile O=$kernel_dir -j${core_num} modules INSTALL_MOD_PATH=$rootfs \
		&& sudo make ARCH=arm64 CROSS_COMPILE=$cross_compile O=$kernel_dir -j${core_num} modules_install INSTALL_MOD_PATH=$rootfs \
		&& sudo make ARCH=$ARCH CROSS_COMPILE=$cross_compile O=$kernel_dir -j${core_num} firmware_install INSTALL_FW_PATH=$rootfs/lib/firmware
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

