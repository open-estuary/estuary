#!/bin/bash

###################################################################################
# Global variable
###################################################################################
DISK_LABEL=
BINARY_DIR=
CONF_DIR=
DISK=
BOOT_PARTITION_SIZE=200

WORKSPACE="Workspace"

###################################################################################
# Usage
###################################################################################
Usage()
{
cat << EOF
###################################################################
# mkusbinstall.sh usage
###################################################################
Usage: ./mkusbinstall.sh [OPTION]... [--OPTION=VALUE]...
  -h, --help              display this help and exit
  --disklabel=LABEL       rootfs partition label
  --bindir=DIR            binary directory (the kernel image, grub image distributions)
  --confdir=DIR           estuarycfg.json directory
  --disk=DISK             target disk
  
for example:
  ./mkusbinstall.sh --disk=/dev/sdb --disklabel=label \\
  --bindir=./build/D02/binary --confdir=./estuary
EOF
}

###################################################################################
# Get parameters
###################################################################################
while test $# != 0
do
	case $1 in
	--*=*)
		ac_option=`expr "X$1" : 'X\([^=]*\)='`
		ac_optarg=`expr "X$1" : 'X[^=]*=\(.*\)'`
		ac_shift=:
		;;
	*)
		ac_option=$1
		ac_optarg=$2
		ac_shift=shift
		;;
	esac
	
	case $ac_option in
	-h | --help)
		Usage ; exit ;;
	--disklabel)
		DISK_LABEL=$ac_optarg ;;
	--bindir)
		BINARY_DIR=$(cd $ac_optarg ; pwd) ;;
	--confdir)
		CONF_DIR=$(cd $ac_optarg ; pwd) ;;
	--disk)
		DISK=$ac_optarg ;;
	*)
		echo "Unknow option $ac_option!"
		Usage ; exit 1 ;;
	esac

	shift
done

###################################################################################
# Notice the user to continue this operation
###################################################################################
echo "Please note this operation will format the device $DISK!"
read -p "Continue to create the usb install disk on $DISK?(y/n)" choice
if [ x"$choice" != x"y" ]; then
	echo "exit ......"
fi

###################################################################################
# Check parameters
###################################################################################
if [ x"$DISK" = x"" ] || [ x"$DISK_LABEL" = x"" ] || [ x"$BINARY_DIR" = x"" ] \
	|| [ x"$CONF_DIR" = x"" ]; then
	Usage ; exit 1
fi

###################################################################################
# Partition USB disk
###################################################################################
read -a mounted_partition <<< $(mount | grep -Po "(${DISK}.)")
for partition in ${mounted_partition[@]}
do
	sudo umount $partition
done

yes | sudo mkfs.ext4 $DISK
echo -e "n\n\n\n\n+${BOOT_PARTITION_SIZE}M\nw\n" | sudo fdisk $DISK
echo -e "t\nef\nw\n" | sudo fdisk $DISK
yes | sudo mkfs.vfat ${DISK}1

echo -e "n\n\n\n\n\nw\n" | sudo fdisk $DISK
yes | sudo mkfs.ext4 -L $DISK_LABEL ${DISK}2

###################################################################################
# Create Workspace
###################################################################################
sudo rm -rf $WORKSPACE 2>/dev/null
mkdir $WORKSPACE
sudo mount ${DISK}2 $WORKSPACE
sudo chmod a+w $WORKSPACE
pushd $WORKSPACE

###################################################################################
# Copy kernel, grub, mini-rootfs, setup.sh, estuarycfg.json ...
###################################################################################
cp $BINARY_DIR/grub*.efi ./
cp $BINARY_DIR/hip*.dtb ./
cp $BINARY_DIR/Image* ./
cp $BINARY_DIR/mini-rootfs-arm64.cpio.gz ./

cp $CONF_DIR/estuarycfg.json ./
cp $CONF_DIR/setup.sh ./

###################################################################################
# Copy distributions
###################################################################################
echo "Copy distributions to workspace configured by estuarycfg.json ......"
index=0
install=`jq -r ".distros[$index].install" ./estuarycfg.json 2>/dev/null`
while [ x"$?" = x"0" ] && [ x"$install" != x"null" ] && [ x"$install" != x"" ];
do
	if [ x"yes" = x"$install" ]; then
		idx=${#distributions[@]}
		distro=`jq -r ".distros[$index].name" ./estuarycfg.json`
		echo "Copy distribution ${distro}_ARM64.tar.gz to workspace ......"
		cp $BINARY_DIR/${distro}_ARM64.tar.gz ./
	fi
	((index = index + 1))
	install=`jq -r ".distros[$index].install" ./estuarycfg.json 2>/dev/null`
done

echo "Copy distributions to workspace done!"
echo ""

###################################################################################
# Create initrd file
###################################################################################
sed -i "s/\(DISK_LABEL=\"\).*\(\"\)/\1$DISK_LABEL\2/g" setup.sh

user=`whoami`
group=`groups | awk '{print $1}'`
mkdir rootfs

pushd rootfs
zcat ../mini-rootfs-arm64.cpio.gz | sudo cpio -dimv

sudo chown -R ${user}:${group} *

if ! (grep "/usr/bin/setup.sh" etc/init.d/rcS); then
	echo "/usr/bin/setup.sh" >> etc/init.d/rcS
fi

cp ../estuarycfg.json ./usr/bin/
mv ../setup.sh ./usr/bin/
sudo chmod 755 ./usr/bin/setup.sh

sudo chown -R root:root *
find | cpio -o -H newc | gzip -c > ../initrd.gz

popd
sudo rm -rf rootfs

###################################################################################
# Create grub.cfg
###################################################################################
Image="`ls Image*`"
Dtb="`ls hip*.dtb`"
Initrd="`ls initrd*.gz`"

cat > grub.cfg << EOF
# NOTE: Please remove the unused boot items according to your real condition.
# Sample GRUB configuration file
#

# Boot automatically after 0 secs.
set timeout=3

# By default, boot the Euler/Linux
set default=d02_minilinux

# Booting from PXE with mini rootfs
menuentry "D02 minilinux" --id d02_minilinux {
    linux /$Image rdinit=/init crashkernel=256M@32M console=ttyS0,115200 earlycon=uart8250,mmio32,0x80300000 ip=dhcp
    initrd /$Initrd
    devicetree /$Dtb
}

EOF

###################################################################################
# Create EFI System
###################################################################################
mkdir -p EFI/GRUB2/
cp grubaa64.efi EFI/GRUB2/

sudo mount ${DISK}1 /mnt/
sudo cp -r EFI /mnt/
sudo cp Image* hip*.dtb initrd*.gz grub.cfg /mnt/
sync
sudo umount /mnt/

###################################################################################
# Pop Workspace
###################################################################################
sudo chown -R root:root *
popd

sync
sudo umount ${DISK}2
###################################################################################
# Delete workspace
###################################################################################
sudo rm -rf $WORKSPACE 2>/dev/null
echo "Write to USB disk successful!"
echo ""

