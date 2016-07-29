#!/bin/bash

UEFI_DIR=uefi
TOPDIR=$(cd `dirname $0` ; pwd)

###################################################################################
# build arguments
###################################################################################
PLATFORM=
OUTPUT_DIR=
CLEAN=

###################################################################################
# Include
###################################################################################
. $TOPDIR/submodules-common.sh

###################################################################################
# build_uefi_usage
###################################################################################
build_uefi_usage()
{
cat << EOF
Usage: build-uefi.sh [clean] --platform=xxx --output=xxx
	clean: clean the uefi binary files
	--platform: which platform to build (D02, D03, HiKey)
	--output: target binary output directory

Example:
	build-uefi.sh --platform=D02 --output=workspace
	build-uefi.sh --platform=HiKey --output=workspace
	build-uefi.sh clean --platform=HiKey --output=workspace

EOF
}

###################################################################################
# build_check <platform> <output_dir>
###################################################################################
build_check()
{
	(
	platform=$1
	output_dir=$2
	inst_dir=$output_dir/binary/$platform
	if [ x"HiKey" = x"$platform" ]; then
		if [ ! -f $inst_dir/l-loader.bin ] || [ ! -f $inst_dir/ptable-linux.img ] || [ ! -f $inst_dir/AndroidFastbootApp.efi ]; then
			return 1
		fi
	fi

	uefi_bin=UEFI_${platform}.fd
	if [ ! -f $inst_dir/$uefi_bin ]; then
		return 1
	fi

	return 0
	)
}

###################################################################################
# build_uefi_for_all <platform> <output_dir>
###################################################################################
build_uefi_for_all()
{
	(
	local platform=$1
	local output_dir=$(cd $2 ; pwd)
	local target_platform=$(echo $platform | tr "[:upper:]" "[:lower:]")
	local uefi_bin=

	pushd $UEFI_DIR
	git reset --hard
	git clean -fdx
	git checkout open-estuary/estuary-rp

	export LC_CTYPE=C
	git submodule init
	git submodule update

	local local_arch=`uname -m`
	if [[ $local_arch = arm* || $local_arch = aarch64 ]]; then
		if [ x"D02" = x"$platform" ]; then
			hisi_dsc_file="OpenPlatformPkg/Platforms/Hisilicon/D02/Pv660D02.dsc"
		elif [ x"D03" = x"$platform" ]; then
			hisi_dsc_file="OpenPlatformPkg/Platforms/Hisilicon/D03/D03.dsc"
		fi

		grep -P "AARCH64_PLATFORM_FLAGS.*-fno-stack-protector" $hisi_dsc_file
		if [ x"$?" != x"0" ]; then
			sed -i '/AARCH64_PLATFORM_FLAGS.*$/s//& -fno-stack-protector/g' $hisi_dsc_file
		fi
	fi

	uefi-tools/uefi-build.sh -c LinaroPkg/platforms.config $target_platform
	if [ x"D02" = x"$platform" ]; then
		uefi_bin=`find Build/Pv660D02 -name "*.fd" 2>/dev/null`
	elif [ x"D03" = x"$platform" ]; then
		uefi_bin=`find Build/D03 -name "*.fd" 2>/dev/null`
	fi
	mkdir -p $output_dir/binary/$platform/
	cp $uefi_bin $output_dir/binary/$platform/UEFI_${platform}.fd
	popd
	)
}

###################################################################################
# build_uefi_for_HiKey <platform> <output_dir>
###################################################################################
build_uefi_for_HiKey()
{
	(
	local platform=$1
	local output_dir=$(cd $2 ; pwd)

	pushd $UEFI_DIR
	rm `find l-loader -name "fip.bin" 2>/dev/null` 2>/dev/null
	export EDK2_DIR=${PWD}
	export UEFI_TOOLS_DIR=${PWD}/uefi-tools
	mkdir -p $output_dir/binary/$platform/

	git reset --hard
	git clean -fdx
	git checkout open-estuary/estuary-rp
	git submodule init
	git submodule update

	local local_arch=`uname -m`
	grep -P "PLATFORM_FLAGS.*-fno-stack-protector" OpenPlatformPkg/Platforms/Hisilicon/HiKey/HiKey.dsc
	if [ x"$?" != x"0" ] && [[ $local_arch == arm* || $local_arch == aarch64 ]]; then
		sed -i '/_PLATFORM_FLAGS.*$/s//& -fno-stack-protector/g' OpenPlatformPkg/Platforms/Hisilicon/HiKey/HiKey.dsc
	fi

	${UEFI_TOOLS_DIR}/uefi-build.sh -b DEBUG -a arm-trusted-firmware hikey

	cd l-loader
	cp ${EDK2_DIR}/Build/HiKey/DEBUG_GCC49/FV/bl1.bin ./
	cp ${EDK2_DIR}/Build/HiKey/DEBUG_GCC49/FV/fip.bin ./

	arm-linux-gnueabihf-gcc -c -o start.o start.S
	arm-linux-gnueabihf-gcc -c -o debug.o debug.S
	arm-linux-gnueabihf-ld -Bstatic -Tl-loader.lds -Ttext 0xf9800800 start.o debug.o -o loader
	arm-linux-gnueabihf-objcopy -O binary loader temp
	python gen_loader.py -o l-loader.bin --img_loader=temp --img_bl1=bl1.bin

	sudo PTABLE=linux-8g bash -x generate_ptable.sh
	python gen_loader.py -o ptable-linux.img --img_prm_ptable=prm_ptable.img --img_sec_ptable=sec_ptable.img

	cp l-loader.bin $output_dir/binary/$platform/
	cp ptable-linux.img $output_dir/binary/$platform/
	cp ${EDK2_DIR}/Build/HiKey/DEBUG_GCC49/AARCH64/AndroidFastbootApp.efi $output_dir/binary/$platform/
	cd ..

	uefi_hikey_bin=`find "${EDK2_DIR}/l-loader" -name "fip.bin" 2>/dev/null`
	if [ x"$uefi_hikey_bin" != x"" ]; then
		cp $uefi_hikey_bin $output_dir/binary/$platform/UEFI_${platform}.fd
	fi
	# roll back submodule
	git submodule deinit -f .
	popd
	)
}

###################################################################################
# build_uefi <platform> <output_dir>
###################################################################################
build_uefi()
{
	local platform=$1
	local output_dir=$2

	if [ ! -d $output_dir ]; then
		mkdir -p $output_dir
	fi
	output_dir=$(cd $output_dir; pwd)

	if [ x"HiKey" = x"$platform" ]; then
		build_uefi_for_HiKey $platform $output_dir
	elif [ x"D02" = x"$platform" ] || [ x"D03" = x"$platform" ]; then
		build_uefi_for_all $platform $output_dir
	fi
}

###################################################################################
# clean_uefi <platform> <output_dir>
###################################################################################
clean_uefi()
{
	local platform=$1
	local output_dir=$2

	local inst_dir=$output_dir/binary/$platform
	local uefi_bin=UEFI_${platform}.fd
	rm -f $inst_dir/$uefi_bin
	if [ x"HiKey" = x"$platform" ]; then
		rm -f $inst_dir/l-loader.bin
		rm -f $inst_dir/ptable-linux.img
		rm -f $inst_dir/AndroidFastbootApp.efi
	fi
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
		--output) OUTPUT_DIR=$ac_optarg ;;
		*) echo -e "\033[31mUnknown option $ac_option!\033[0m"
			build_uefi_usage ; exit 1 
			;;
	esac

	shift
done

###################################################################################
# Check args
###################################################################################
if [ x"$PLATFORM" = x"QEMU" ]; then
	exit 0
fi

if [ x"" = x"$PLATFORM" ] || [ x"" = x"$OUTPUT_DIR" ]; then
	echo -e "\033[31mError! Platform: $PLATFORM, Output: $OUTPUT_DIR!\033[0m"
	build_uefi_usage ; exit 1
fi

###################################################################################
# Clean uefi
###################################################################################
if [ x"yes" = x"$CLEAN" ]; then
	rm_module_build_log uefi $OUTPUT_DIR
	clean_uefi $PLATFORM $OUTPUT_DIR
	exit 0
fi

###################################################################################
# Build UEFI
###################################################################################
# check update
if build_check $PLATFORM $OUTPUT_DIR && update_module_check uefi $OUTPUT_DIR; then
	exit 0
fi

# build uefi and check result
rm_module_build_log uefi $OUTPUT_DIR
if build_uefi $PLATFORM $OUTPUT_DIR && build_check $PLATFORM $OUTPUT_DIR; then
	gen_module_build_log uefi $OUTPUT_DIR ; exit 0
else
	exit 1
fi

