#!/bin/bash

###################################################################################
# Const variables
###################################################################################
TOPDIR=`pwd`
SUPPORTED_PLATFORM=(D03 D05)
ESTUARY_HTTP_ADDR="http://download.open-estuary.org/?dir=AllDownloads/DownloadsEstuary/releases"
ESTUARY_FTP_ADDR="ftp://117.78.41.188/releases/"
D03_CMDLINE="rdinit=/init console=ttyS0,115200 earlycon=hisilpcuart,mmio,0xa01b0000,0,0x2f8 pcie_aspm=off acpi=force"
D05_CMDLINE="rdinit=/init console=ttyAMA0,115200 earlycon=pl011,mmio,0x602B0000 pcie_aspm=off crashkernel=256M@32M acpi=force"

BOOT_PARTITION_SIZE=4
DISK_LABEL="Estuary"

###################################################################################
# Global variables
###################################################################################
TARGET=
VERSION=2.3
PLATFORM=D05
DISTRO=CentOS
CAPACITY=50
BINDIR=

WORKSPACE=Workspace
ESTUARY_WEB_ADDR=$ESTUARY_FTP_ADDR

###################################################################################
# Usage
###################################################################################
Usage() {
cat << EOF
###################################################################
# mkdeploydisk.sh usage
###################################################################
Usage: mkdeploydisk.sh [OPTION]... [--OPTION=VALUE]...
	-h, --help              display this help and exit
	--target=xxx            target usb device which is used to make a bootable install usb disk
                                If not specified, the first usb storage device will be default
	--version=xxx           target estuary release version. If not specified, the latest will be default
	--platform=xxx          target platform to install
	--distro=xxx            target distro to install
	--capacity=xxx          target root file system partition size (GB)

for example:
	mkdeploydisk.sh --help
	mkdeploydisk.sh
	mkdeploydisk.sh --target=/dev/sdc --platform=D05 --distro=CentOS

EOF
}

###################################################################################
# string[] get_usb_devices(void)
###################################################################################
get_usb_devices() {
	(
	root=$(mount | grep " / " | grep  -Po "(/dev/sd[^ ])")
	if [ $? -ne 0 ]; then
		root="/dev/sdx"
	fi
	
	usb_devices=(`sudo lshw 2>/dev/null | grep "bus info: usb" -A 12 | grep "logical name: /dev/sd" | \
		grep -v $root | grep -Po "(/dev/sd.*)" | sort`)
	
	echo ${usb_devices[*]}
	)
}

###################################################################################
# int get_default_usb(sting &__usb_device)
###################################################################################
get_default_usb() {
	local __usb_device=$1
	local usb_devices=(`get_usb_devices`)
	local first_usb=${usb_devices[0]}
	if [ x"$first_usb" != x"" ]; then
		eval $__usb_device="'$first_usb'" ; return 0
	else
		return 1
	fi
}

###################################################################################
# int check_usb_device(string usb_device)
###################################################################################
check_usb_device() {
	(
	usb_device=$1
	if [ x"$usb_device" = x"" ] || [ ! -b $usb_device ]; then
		echo "Device $usb_device is not exist!" ; return 1
	else
		if sudo lshw 2>/dev/null | grep "bus info: usb" -A 12 | grep "logical name: /dev/sd" | grep $usb_device >/dev/null; then
			return 0
		else
			echo "Device $usb_device is not an usb device!" ; return 1
		fi
	fi
	)
}

###################################################################################
# int umount_device(string device)
###################################################################################
umount_device() {
	(
	device=$1
	mounted_partition=(`mount | grep -Po "^(${device}[^ ]*)"`)
	for part in ${mounted_partition[@]}; do
		sudo umount $part || return 1
	done
	)

	return 0
}

###################################################################################
# string get_proto_type(string web_addr)
###################################################################################
get_proto_type() {
	local web_addr=$1
	echo $web_addr | grep -Po "^(http|ftp)(?=\:.*)"
}

###################################################################################
# string[] get_ftp_dir(string ftp_addr)
###################################################################################
get_ftp_dir() {
	# local ftp_addr=`echo $1 | sed 's/\/\+/\//g' | sed 's/[^\/]$/&\//g'`
	local ftp_addr=`echo $1 | sed 's/\/\{2,\}$/\//g' | sed 's/[^\/]$/&\//g'`
	curl -s $ftp_addr | grep "^d.*" | awk '{print $NF}'
}

###################################################################################
# string[] get_http_dir(string http_addr)
###################################################################################
get_http_dir() {
	local http_addr=$1
	curl -s $http_addr 2>/dev/null | grep 'class="item dir"' | sed 's/<[^<>]*>//g'
}

###################################################################################
# string[] get_all_version(string web_addr)
###################################################################################
get_all_version()
{
	local web_addr=$1
	local proto_type=`get_proto_type $web_addr`
	eval get_${proto_type}_dir $web_addr 2>/dev/null
}

###################################################################################
# string[] get_all_distro(string web_addr)
###################################################################################
get_all_distro()
{
	local web_addr=$1
	local proto_type=`get_proto_type $web_addr`
	eval get_${proto_type}_dir $web_addr 2>/dev/null | grep -Pv "Common|Minirootfs" | sort
}

###################################################################################
# int download_file(string target_file, string target_dir)
###################################################################################
download_file() {
	(
	target_file=$1
	target_dir=$2
	
	pushd $target_dir >/dev/null
	target_file_name=`basename $target_file`
	md5sum --quiet --check .${target_file_name}.sum >/dev/null 2>&1 && return 0

	rm -f ${target_file_name}.sum .${target_file_name}.sum >/dev/null 2>&1
	wget -c ${target_file}.sum || return 1
	mv ${target_file_name}.sum .${target_file_name}.sum
	md5sum --quiet --check .${target_file_name}.sum >/dev/null 2>&1 && return 0
	rm -f $target_file_name >/dev/null 2>&1
	wget -c $target_file && md5sum --quiet --check .${target_file_name}.sum >/dev/null 2>&1 && return 0
	popd >/dev/null

	return 1
	)
}

###################################################################################
# int create_partition(string device, int efi_partition_size, string rootfs_label)
###################################################################################
create_partition() {
	(
	device=$1
	efi_partition_size=$2
	rootfs_label=$3

	umount_device $device || return 1
	yes | sudo mkfs.ext4 $device >/dev/null || return 1
	echo -e "n\n\n\n\n+${efi_partition_size}M\nw\n" | sudo fdisk $device >/dev/null || return 1
	echo -e "t\nef\nw\n" | sudo fdisk $device >/dev/null || return 1
	yes | sudo mkfs.vfat ${device}1 >/dev/null || return 1

	echo -e "n\n\n\n\n\nw\n" | sudo fdisk $device >/dev/null || return 1
	yes | sudo mkfs.ext4 -L $rootfs_label ${device}2 >/dev/null || return 1
	)

	return 0
}

###################################################################################
# int create_grub_header(string grub_cfg_file)
###################################################################################
create_grub_header() {
	(
	grub_cfg_file=$1
cat > $grub_cfg_file << EOF
# NOTE: Please remove the unused boot items according to your real condition.
# Sample GRUB configuration file
#

# Boot automatically after 5 secs.
set timeout=5

# By default, boot the Linux
set default=xxxx

EOF
	)
}

###################################################################################
# int create_grub_menuentry(string grub_cfg_file, string title, string menuentry_id, sting image, string cmdline, string initrd)
###################################################################################
create_grub_menuentry() {
	(
	grub_cfg_file=$1
	title=$2
	menuentry_id=$3
	image=$4
	cmdline=$5
	initrd=$6
cat >> $grub_cfg_file << EOF
# Booting initrd for $plat
menuentry "$title" --id $menuentry_id {
	search --no-floppy --label --set=root $DISK_LABEL
	linux $image $cmdline
	initrd $initrd
}

EOF
	return 0
	)
}

###################################################################################
# int download_common_binary(string common_bin_dir)
###################################################################################
download_common_binary() {
	local common_bin_dir=$1
	download_file ${common_bin_dir}/Image ./ || return 1
	download_file ${common_bin_dir}/grubaa64.efi ./ || return 1
	download_file ${common_bin_dir}/mini-rootfs.cpio.gz ./ || return 1
	download_file ${common_bin_dir}/deploy-utils.tar.bz2 ./ || return 1
	return 0
}

###################################################################################
# int download_distro(string distro_dir, string[] distro)
###################################################################################
download_distro() {
	(
	distro_dir=$1
	distro=$2
	for dist in ${distro[@]}; do
		download_file ${distro_dir}/${dist}/Common/${dist}_ARM64.tar.gz ./ || return 1
	done

	return 0
	)
}

###################################################################################
# int create_initrd(string rootfs, string deploy_utils)
###################################################################################
create_initrd() {
	(
	rootfs=$1
	deploy_utils=$2

	user=`whoami`
	group=`groups | awk '{print $1}'`

	zcat $rootfs | sudo cpio -dimv >/dev/null 2>/dev/null || return 1
	sudo tar xf $deploy_utils -C ./ || return 1

	sudo chown -R ${user}:${group} *
	if ! (grep "/usr/bin/setup.sh" etc/init.d/rcS); then
		echo "/usr/bin/setup.sh" >> etc/init.d/rcS || exit 1
	fi

	sed -i "s/\(DISK_LABEL=\"\).*\(\"\)/\1$DISK_LABEL\2/g" ./usr/bin/setup.sh
	sudo chmod 755 ./usr/bin/setup.sh

	sudo chown -R root:root *
	find | sudo cpio -o -H newc | gzip -c > ../initrd.gz || return 1

	return 0
	)
}

###################################################################################
# int clean_workspace(void)
###################################################################################
clean_workspace() {
	cd $TOPDIR
	umount_device $TARGET
	rmdir $WORKSPACE 2>/dev/null

	return 0
}

###################################################################################
# Get parameters
###################################################################################
while test $# != 0
do
	case $1 in
		--*=*) ac_option=`expr "X$1" : 'X\([^=]*\)='` ; ac_optarg=`expr "X$1" : 'X[^=]*=\(.*\)'` ; ac_shift=:
			;;
		*) ac_option=$1 ; ac_optarg=$2 ; ac_shift=shift
			;;
	esac
	
	case $ac_option in
		-h | --help) Usage ; exit ;;
		--target) TARGET=$ac_optarg ;;
		--platform) PLATFORM=$ac_optarg ;;
		--distro) DISTRO=$ac_optarg ;;
		--capacity) CAPACITY=$ac_optarg ;;
		--version) VERSION=$ac_optarg ;;
		*) echo "Unknow option $ac_option!" ; Usage ; exit 1 ;;
	esac

	shift
done

###################################################################################
# Get/Check platform info
###################################################################################
if [ x"$PLATFORM" = x"" ] || !(echo ${SUPPORTED_PLATFORM[@]} | grep -w $PLATFORM >/dev/null 2>&1); then
	echo "------------------------------------------------------"
	echo "- supported platform list"
	echo "------------------------------------------------------"
	old_ps3="$PS3"
	PS3="Input the platform index to install: "
	select PLATFORM in ${SUPPORTED_PLATFORM[*]}; do break; done
	PS3="$old_ps3"
fi

###################################################################################
# Get/Check version info
###################################################################################
# echo -e "\nGet version info from $ESTUARY_WEB_ADDR. Please wait!"
version_list=(`get_all_version $ESTUARY_WEB_ADDR | sort -r`)
if [ ${#version_list[@]} -eq 0 ]; then
	echo "Get version info from $ESTUARY_WEB_ADDR failed!"; exit 1
fi

if [ x"$VERSION" = x"" ] || !(echo ${version_list[@]} | grep -w $VERSION >/dev/null 2>&1); then
	echo "------------------------------------------------------"
	echo "- released version list"
	echo "------------------------------------------------------"
	old_ps3="$PS3"
	PS3="Input the version index to install: "
	select VERSION in ${version_list[*]}; do break; done
	PS3="$old_ps3"
fi

###################################################################################
# Get/Check distro info
###################################################################################
# echo -e "\nGet distro info from ${ESTUARY_WEB_ADDR}/${VERSION}/linux. Please wait!"
distro_list=(`get_all_distro ${ESTUARY_WEB_ADDR}/${VERSION}/linux`)
if [ ${#distro_list[@]} -eq 0 ]; then
	echo "Get distro info from ${ESTUARY_WEB_ADDR}/${VERSION}/linux failed!"; exit 1
fi

if [ x"$DISTRO" = x"" ] || !(echo ${distro_list[@]} | grep -w $DISTRO >/dev/null 2>&1); then
	echo "------------------------------------------------------"
	echo "- supported distro list"
	echo "------------------------------------------------------"
	old_ps3="$PS3"
	PS3="Input the distro index to install: "
	select dis in ${distro_list[*]}; do DISTRO=$dis; break; done
	PS3="$old_ps3"
fi

###################################################################################
# Check/Set parameters
###################################################################################
BINDIR=${ESTUARY_WEB_ADDR}/${VERSION}/linux

###################################################################################
# check/get USB storage device
###################################################################################
if [ x"$TARGET" != x"" ]; then
	echo -e "\nCheck the target USB storage device. Please wait a moment."
	check_usb_device $TARGET || { echo "Error!!! Device $TARGET is not a USB device or not exist!"; exit 1;}
else
	echo -e "\nNotice. No USB storage device is specified.\nUse the first USB storage device by default."
	get_default_usb TARGET || { echo "Error!!! Can't find an available USB storage device!"; exit 1;}
fi

###################################################################################
# Display install info
###################################################################################
cat << EOF
------------------------------------------------------
- PLATFROM: $PLATFORM, VERSION: $VERSION, DISTRO: $DISTRO, TARGET: $TARGET
------------------------------------------------------

EOF

sleep 1

###################################################################################
# Create and format usb storage
###################################################################################
cat << EOF
------------------------------------------------------
- Format and create usb storage partisions
------------------------------------------------------
EOF
echo -e "Notice! The device $TARGET will be formatted."
read -p "Continue to do this? (y/N) " c
if ! create_partition $TARGET $BOOT_PARTITION_SIZE $DISK_LABEL; then
	echo "Error!!! Create partition on $TARGET failed!"; exit 1
fi

###################################################################################
# create workspace and switch into workspace
###################################################################################
if [ -d $WORKSPACE ]; then
	WORKSPACE=`mktemp -d Workspace.XXXX`
fi

mkdir -p $WORKSPACE
WORKSPACE=`cd $WORKSPACE; pwd`
trap 'trap EXIT; clean_workspace; exit 1' INT EXIT

sudo mount ${TARGET}2 $WORKSPACE || exit 1
sudo chmod a+rw $WORKSPACE
pushd $WORKSPACE >/dev/null

cat > estuary.txt << EOF
PLATFORM=$PLATFORM
DISTRO=$DISTRO
CAPACITY=$CAPACITY
EOF

###################################################################################
# download all binary file from estuary
###################################################################################
cat << EOF
------------------------------------------------------
- Download binary files from server
------------------------------------------------------
EOF
if ! download_common_binary ${BINDIR}/Common; then
	echo "Error!!! Download common binary failed!"; exit 1
fi

if ! download_distro ${BINDIR} "${DISTRO[@]}"; then
	echo "Error!!! Download distro failed!"; exit 1
fi

###################################################################################
# create grub.cfg
###################################################################################
create_grub_header grub.cfg
platform=(`echo $PLATFORM | tr ',' ' '`)
default_menuentry="`echo ${platform[0]} | tr "[:upper:]" "[:lower:]"`_menuentry"
sed -i "s/\(set default=\)\(.*\)/\1${default_menuentry}/g" grub.cfg
for plat in ${platform[@]}; do
	eval cmd_line=\$${plat}_CMDLINE
	title="Install Estuary $plat"
	menuentry_id="`echo $plat | tr "[:upper:]" "[:lower:]"`_menuentry"
	create_grub_menuentry grub.cfg "$title" $menuentry_id /Image "$cmd_line" /initrd.gz
done

###################################################################################
# copy grub to efi partition
###################################################################################
sudo mount ${TARGET}1 /mnt || exit 1
sudo cp grub.cfg /mnt/
mkdir -p EFI/GRUB2/
cp grubaa64.efi EFI/GRUB2/grubaa64.efi || exit 1
sudo cp -r EFI /mnt/ || exit 1
sudo umount ${TARGET}1 || exit 1

###################################################################################
# create initrd.gz
###################################################################################
cat << EOF
------------------------------------------------------
- Generate initrd
------------------------------------------------------
EOF
user=`whoami`
group=`groups | awk '{print $1}'`
mkdir rootfs

pushd rootfs >/dev/null
if ! create_initrd ../mini-rootfs.cpio.gz ../deploy-utils.tar.bz2; then
	echo "Error!!! Create initrd.gz failed!"; exit 1
fi
popd >/dev/null
echo "Clear temporary files. Please wait!"
sudo rm -rf rootfs
rm -f mini-rootfs.cpio.gz deploy-utils.tar.bz2

###################################################################################
# switch out from workspace...
###################################################################################
popd >/dev/null
cat << EOF
------------------------------------------------------
- Umount usb install device
------------------------------------------------------
EOF

trap EXIT
echo "umount ${TARGET}2...... Please wait!"
(
trap 'echo ""; exit' SIGINT
while :; do echo -n "."; sleep 3; done
) &
child_pid=$!
sudo umount ${TARGET}2 || exit 1
kill -s SIGINT ${child_pid} 2>/dev/null
wait ${child_pid}

rmdir $WORKSPACE
exit 0

