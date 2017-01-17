#!/bin/bash

TOPDIR=$(cd `dirname $0` ; pwd)
CORE_NUM=`cat /proc/cpuinfo | grep "processor" | wc -l`

###################################################################################
# Include
###################################################################################
. $TOPDIR/../include/file-check.sh
. $TOPDIR/submodules-common.sh

###################################################################################
# global vars
###################################################################################
CLEAN=
OUTPUT_DIR=
DISTROS=

QEMU_DIR=
KERNEL_BIN=
ROOTFS=

CMDLINE="console=ttyAMA0 root=/dev/vda rw"

###################################################################################
# build_qemu_usage
###################################################################################
build_qemu_usage()
{
cat << EOF
Usage: build-grub.sh [clean] --output=xxx --distros=xxx,xxx
	clean: clean the grub binary files
	--output: build output top directory
	--distros: which distros to build for qemu
	
Example:
	build-qemu.sh --output=./workspace --distros=Ubuntu,OpenSuse
	build-qemu.sh clean --output=./workspace --distros=Ubuntu,OpenSuse

EOF
}

###################################################################################
#
###################################################################################

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
                --output) OUTPUT_DIR=$ac_optarg ;;
                --distros) DISTROS=$ac_optarg ;;
                *) echo -e "\033[31mUnknown option $ac_option!\033[0m"
			build_pcakages_usage ; exit 1 ;;
        esac

        shift
done

if [ x"$OUTPUT_DIR" = x"" ] || [ x"$DISTROS" = x"" ]; then
	build_qemu_usage; exit 1
fi

QEMU_DIR=$OUTPUT_DIR/qemu
DISTRO_DIR=$OUTPUT_DIR/distro
KERNEL_BIN=$OUTPUT_DIR/binary/arm64/Image

###################################################################################
# clean qemu img
###################################################################################
if [ x"$CLEAN" = x"yes" ]; then
	echo "Clean qemu ..."
	distros=(`echo $DISTROS | tr ',' ' '`)
	for distro in ${distros[*]}; do
		rm -f $DISTRO_DIR/${distro}_ARM64.img 2>/dev/null
	done
	
	pushd qemu/ >/dev/null
	make clean
	popd >/dev/null

	exit 0
fi

###################################################################################
# build and install qemu
###################################################################################
mkdir -p $QEMU_DIR 2>/dev/null
qemu_dir=`cd $QEMU_DIR ; pwd`
if [ ! -f $qemu_dir/bin/qemu-system-aarch64 ] || ! update_module_check qemu $OUTPUT_DIR; then
	pushd qemu/ >/dev/null
	[ -d $qemu_dir ] && rm -rf $qemu_dir
	if [ "`uname -m`" = "aarch64" ]; then
		./configure --prefix=$qemu_dir --target-list=aarch64-softmmu --enable-kvm || exit 1
	else
		./configure --prefix=$qemu_dir --target-list=aarch64-softmmu || exit 1
	fi

	if ! (make -j${CORE_NUM} && make install); then
		exit 1
	fi
	popd >/dev/null
	gen_module_build_log qemu $OUTPUT_DIR
fi

export PATH=$qemu_dir/bin:$PATH

###################################################################################
# create rootfs image
###################################################################################
distros=(`echo $DISTROS | tr ',' ' '`)
for distro in ${distros[*]}; do
	rootfs=`ls $DISTRO_DIR/$distro*.img 2>/dev/null || ls $DISTRO_DIR/$distro*.raw 2>/dev/null`
	if [ x"$rootfs" != x"" ]; then
		if check_file_update "$rootfs" $DISTRO_DIR/${distro}_ARM64.tar.gz; then
			continue
		fi
		rm -f $rootfs
	fi

	if ! (sudo find $DISTRO_DIR/$distro -name "etc" | grep --quiet "etc"); then
		exit 1
	fi

	echo "Creating new rootfs image file for QEMU..."
	pushd $DISTRO_DIR >/dev/null
	imagefile="$distro"_ARM64."img"
	dd if=/dev/zero of=$imagefile bs=1M count=10240
	mkfs.ext4 $imagefile -F
	mkdir -p tempdir 2>/dev/null
	sudo mount $imagefile tempdir

	echo "Producing the rootfs image file ${distro}_ARM64.img for QEMU..."
	sudo cp -a $distro/* tempdir/
	sudo umount tempdir
	rm -rf tempdir
	popd >/dev/null
done

###################################################################################
# get rootfs
###################################################################################
index=
distro_index=0
distros=(`echo $DISTROS | tr ',' ' '`)
if [ ${#distros[@]} -gt 1 ]; then
	echo "/*---------------------------------------------------------------"
	echo "- Please select the distro to run for QEMU!"
	echo "---------------------------------------------------------------*/"
	for ((i=0; i<${#distros[@]}; i++)); do
		printf "%d) %s " $[i+1] ${distros[$i]}
	done
	echo ""
	read -t 5 -p "Input the index: " index
	if [ x"$index" = x"" ]; then
		index=1
	elif ! expr $index + 0 >/dev/null 2>&1; then
		echo "Invalid input!" ; exit 1
	elif [ $index -gt ${#distros[@]} ] || [ $index -lt 1 ]; then
		echo "Outside of the valid range!" ; exit 1
	fi
	distro_index=$[index-1]
fi
distro=${distros[$distro_index]}
ROOTFS=$DISTRO_DIR/${distro}_ARM64.img

###################################################################################
# start and run qemu
###################################################################################
qemu-system-aarch64 -machine virt -cpu cortex-a57 \
	-m 2048 \
	-kernel $KERNEL_BIN \
	-drive if=none,file=$ROOTFS,id=fs \
	-device virtio-blk-device,drive=fs \
	-append "$CMDLINE" \
	-nographic

