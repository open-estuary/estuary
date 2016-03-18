#!/bin/bash

###################################################################################
# Global variable
###################################################################################
DISK_LABEL=
BINARY_DIR=
CONF_DIR=
GRUB_DIR=

PLATFORM=
WORKSPACE="Workspace"

###################################################################################
# Usage
###################################################################################
Usage()
{
cat << EOF
###################################################################
# mkisoimg.sh usage
###################################################################
Usage: ./mkisoimg.sh [OPTION]... [--OPTION=VALUE]...
  -h, --help              display this help and exit
  --disklabel=LABEL       ISO image Volume ID
  --bindir=DIR            binary directory (the kernel image, grub image distributions)
  --confdir=DIR           estuarycfg.json directory
  --grubdir=DIR           grub directory (where the grub has been installed in)
  
for example:
  ./mkisoimg.sh --grubdir=./build/D02/grub --disklabel=label \\
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
	--grubdir)
		GRUB_DIR=$(cd $ac_optarg ; pwd) ;;
	*)
		echo "Unknow option $ac_option!"
		Usage ; exit 1 ;;
	esac

	shift
done

###################################################################################
# Check parameters
###################################################################################
if [ x"$GRUB_DIR" = x"" ] || [ x"$DISK_LABEL" = x"" ] || [ x"$BINARY_DIR" = x"" ] \
	|| [ x"$CONF_DIR" = x"" ]; then
	Usage ; exit 1
fi

###################################################################################
# Create Workspace
###################################################################################
sudo rm -rf $WORKSPACE 2>/dev/null
rm -f ${DISK_LABEL}.iso
mkdir $WORKSPACE
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
PLATFORM=`jq -r ".system.platform" ./estuarycfg.json`
platform=$(echo $PLATFORM | tr "[:upper:]" "[:lower:]")

if [ x"D02" = x"$PLATFORM" ]; then
	cmd_line="rdinit=/init crashkernel=256M@32M console=ttyS0,115200 earlycon=uart8250,mmio32,0x80300000 ip=dhcp"
else
	cmd_line="rdinit=/init console=ttyS1,115200 earlycon=hisilpcuart,mmio,0xa01b0000,0,0x2f8"
fi

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
set default=${platform}_minilinux

# Booting from PXE with mini rootfs
menuentry "${PLATFORM} minilinux" --id ${platform}_minilinux {
    linux /$Image $cmd_line
    initrd /$Initrd
    devicetree /$Dtb
}

EOF

###################################################################################
# Create EFI System
###################################################################################
mkdir -p EFI/BOOT/
$GRUB_DIR/bin/grub-mkimage -v -o EFI/BOOT/BOOTAA64.EFI -O arm64-efi -p / boot chain configfile configfile efinet ext2 fat \
iso9660 gettext help hfsplus loadenv lsefi normal normal ntfs ntfscomp part_gpt part_msdos part_msdos read search search_fs_file \
search_fs_uuid search_label terminal terminfo tftp linux >/dev/null 2>&1

sudo dd if=/dev/zero of=boot.img bs=1M count=4 2>/dev/null
sudo mkfs.vfat boot.img
sudo mount boot.img /mnt/
sudo cp -r EFI /mnt/
sync
sudo umount /mnt/

###################################################################################
# Create bootable iso
###################################################################################
rm -f mini-rootfs-arm64.cpio.gz
genisoimage -e boot.img -no-emul-boot -J -R -c boot.catalog -hide boot.catalog -hide boot.img -V "$DISK_LABEL" -o /tmp/${DISK_LABEL}.iso .
mv /tmp/${DISK_LABEL}.iso ../

###################################################################################
# Pop Workspace
###################################################################################
popd

###################################################################################
# Delete workspace
###################################################################################
sudo rm -rf $WORKSPACE 2>/dev/null
echo "mkisoimg successful!"
echo ""

exit 0


