#!/bin/bash
###################################################################################
# mkusbinstall.sh --target=/dev/sdb --platform=D02 --distros=Ubuntu,OpenSuse --capacity=50,50 --bindir=./workspace
###################################################################################
TOPDIR=$(cd `dirname $0` ; pwd)
. $TOPDIR/usb-func.sh

###################################################################################
# Global variable
###################################################################################
TARGET=
PLATFORM=
DISTROS=
CAPACITY=
BINARY_DIR=
DISK_LABEL="Estuary"

BOOT_PARTITION_SIZE=200
WORKSPACE=

D02_CMDLINE="rdinit=/init crashkernel=256M@32M console=ttyS0,115200 earlycon=uart8250,mmio32,0x80300000"
D03_CMDLINE="rdinit=/init console=ttyS0,115200 earlycon=hisilpcuart,mmio,0xa01b0000,0,0x2f8"

###################################################################################
# Usage
###################################################################################
Usage()
{
cat << EOF
###################################################################
# mkusbinstall.sh usage
###################################################################
Usage: mkusbinstall.sh [OPTION]... [--OPTION=VALUE]...
	-h, --help              display this help and exit
	--target=xxx            deploy usb device
	--platform=xxx          which platform to deploy (D02, D03)
	--distros=xxx,xxx       which distros to deploy (Ubuntu, Fedora, OpenSuse, Debian, CentOS)
	--capacity=xxx,xxx      capacity for distros on install disk, unit GB (suggest 50GB)
	--bindir=xxx            binary directory
	--disklabel=xxx         rootfs partition label on usb device (Default is Estuary)
  
for example:
	mkusbinstall.sh --target=/dev/sdb --platform=D02 --distros=Ubuntu,OpenSuse \\
	--capacity=50,50 --bindir=./workspace
	mkusbinstall.sh --target=/dev/sdb --platform=D02 --distros=Ubuntu,OpenSuse \\
	--capacity=50,50 --bindir=./workspace --disklabel=Estuary

EOF
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
		--distros) DISTROS=$ac_optarg ;;
		--capacity) CAPACITY=$ac_optarg ;;
		--bindir) BINARY_DIR=$(cd $ac_optarg ; pwd) ;;
		--disklabel) DISK_LABEL=$ac_optarg ;;
		*) echo "Unknow option $ac_option!" ; Usage ; exit 1 ;;
	esac

	shift
done

###################################################################################
# Check parameters
###################################################################################
if  [ x"$PLATFORM" = x"" ] || [ x"$DISTROS" = x"" ] || [ x"$CAPACITY" = x"" ] || [ x"$BINARY_DIR" = x"" ]; then
	echo "target: $TARGET, platform: $PLATFORMS, distros: $DISTROS, capacity: $CAPACITY, bindir: $BINARY_DIR"
	echo "Error! Please all parameters are right!" >&2
	Usage ; exit 1
fi

if ! check_usb_device $TARGET || ! get_default_usb TARGET; then
	echo "Error! Can't find available usb device!" >&2 ; exit 1
fi

distros=($(echo "$DISTROS" | tr ',' ' '))
capacity=($(echo "$CAPACITY" | tr ',' ' '))
if [[ ${#distros[@]} != ${#capacity[@]} ]]; then
	echo "Error! Number of capacity is not eq the distros!" >&2
	Usage ; exit 1
fi

###################################################################################
# Notice the user to continue this operation
###################################################################################
if mount | grep -Po "^($TARGET[^ ]* on / ).*" >/dev/null 2>&1; then
	echo "Error!!! Target device $TARGET is mounted as root system! Please use another usb device!" >&2 ; exit 1
fi

device_info=`sudo fdisk -l 2>/dev/null | grep -Po "^(Disk $TARGET: ).*"`
if [ x"$device_info" = x"" ]; then
	echo "Error! Target device $TARGET is not exist!" >&2 ; exit 1
fi

echo "---------------------------------------------------------------"
echo "- Please note this operation will format the device $TARGET!!!"
echo "- $device_info"
echo "---------------------------------------------------------------"
read -p "Continue to create the usb install disk on $TARGET? (y/n)" choice
if [ x"$choice" != x"y" ]; then
	echo "Exit ......" ; exit 1
fi

###################################################################################
# Partition USB disk
###################################################################################
read -a mounted_partition <<< $(mount | grep -Po "(${TARGET}.)")
for partition in ${mounted_partition[@]}
do
	sudo umount $partition
done

yes | sudo mkfs.ext4 $TARGET
echo -e "n\n\n\n\n+${BOOT_PARTITION_SIZE}M\nw\n" | sudo fdisk $TARGET
echo -e "t\nef\nw\n" | sudo fdisk $TARGET
yes | sudo mkfs.vfat ${TARGET}1

echo -e "n\n\n\n\n\nw\n" | sudo fdisk $TARGET
yes | sudo mkfs.ext4 -L $DISK_LABEL ${TARGET}2

###################################################################################
# Create Workspace and Switch to Workspace!!!
###################################################################################
WORKSPACE=`mktemp -d workspace.XXXX`
sudo mount ${TARGET}2 $WORKSPACE
sudo chmod a+w $WORKSPACE
pushd $WORKSPACE >/dev/null

###################################################################################
# Copy kernel, grub, mini-rootfs, setup.sh ...
###################################################################################
cp $BINARY_DIR/grub*.efi ./ || exit 1
cp $BINARY_DIR/Image ./ || exit 1
cp $BINARY_DIR/mini-rootfs.cpio.gz ./ || exit 1
cp $BINARY_DIR/deploy-utils.tar.bz2 ./ || exit 1
cp $TOPDIR/setup.sh ./ || exit 1

###################################################################################
# Copy distros
###################################################################################
echo "Copy distributions to $WORKSPACE......"

distros=($(echo $DISTROS | tr ',' ' '))
for distro in ${distros[*]}; do
	echo "Copy distribution ${distro}_ARM64.tar.gz to $WORKSPACE......"
	cp $BINARY_DIR/${distro}_ARM64.tar.gz ./ || exit 1
done

echo "Copy distributions to $WORKSPACE done!"
echo ""

###################################################################################
# Create initrd file
###################################################################################
sed -i "s/\(DISK_LABEL=\"\).*\(\"\)/\1$DISK_LABEL\2/g" setup.sh

user=`whoami`
group=`groups | awk '{print $1}'`
mkdir rootfs

pushd rootfs >/dev/null
zcat ../mini-rootfs.cpio.gz | sudo cpio -dimv || exit 1
rm -f ../mini-rootfs.cpio.gz
sudo chown -R ${user}:${group} *

if ! (grep "/usr/bin/setup.sh" etc/init.d/rcS); then
	echo "/usr/bin/setup.sh" >> etc/init.d/rcS || exit 1
fi

cat > ./usr/bin/Estuary.txt << EOF
PLATFORM=$PLATFORM
DISTROS=$DISTROS
CAPACITY=$CAPACITY
EOF

mv ../setup.sh ./usr/bin/
tar jxvf ../deploy-utils.tar.bz2 -C ./ || exit 1
rm -f ../deploy-utils.tar.bz2
sudo chmod 755 ./usr/bin/setup.sh

sudo chown -R root:root *
find | sudo cpio -o -H newc | gzip -c > ../initrd.gz || exit 1

popd >/dev/null
sudo rm -rf rootfs

###################################################################################
# Create grub.cfg
###################################################################################
distros=`echo $DISTROS | tr ',' ' '`
platform=$(echo $PLATFORM | tr "[:upper:]" "[:lower:]")

Image="`ls Image*`"
Initrd="`ls initrd*.gz`"
eval cmd_line=\$${PLATFORM}_CMDLINE

cat > grub.cfg << EOF
# NOTE: Please remove the unused boot items according to your real condition.
# Sample GRUB configuration file
#

# Boot automatically after 0 secs.
set timeout=3

# By default, boot the Linux
set default=${platform}_minilinux

# Booting from PXE with mini rootfs
menuentry "Install estuary" --id ${platform}_minilinux {
    linux /$Image $cmd_line
    initrd /$Initrd
}

EOF

###################################################################################
# Create EFI System
###################################################################################
mkdir -p EFI/GRUB2/
cp grubaa64.efi EFI/GRUB2/grubaa64.efi || exit 1

sudo mount ${TARGET}1 /mnt/ || exit 1
sudo cp -r EFI /mnt/ || exit 1
sudo cp Image* initrd*.gz grub.cfg /mnt/ || exit 1
# sync
sudo umount /mnt/

###################################################################################
# Pop Workspace!!!
###################################################################################
sudo chown -R root:root *
popd >/dev/null

# sync
sudo umount ${TARGET}2
###################################################################################
# Delete workspace
###################################################################################
sudo rm -rf $WORKSPACE 2>/dev/null
echo "Create USB disk deployment environment successful!"
echo ""

exit 0

