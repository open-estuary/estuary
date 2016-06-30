#!/bin/bash

TOPDIR=$(cd `dirname $0` ; pwd)

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
WORKSPACE=`mktemp -d workspace.XXXX`

###################################################################################
# Usage
###################################################################################
Usage()
{
cat << EOF
###################################################################
# mkisoimg.sh usage
###################################################################
Usage: mkisoimg.sh [OPTION]... [--OPTION=VALUE]...
	-h, --help              display this help and exit
	--platform=xxx          which platform to deploy (D02, D03)
	--distros=xxx,xxx       which distros to deploy (Ubuntu, Fedora, OpenSuse, Debian, CentOS)
	--capacity=xxx,xxx      capacity for distros on install disk, unit GB (default 50GB)
	--bindir=xxx            binary directory
	--disklabel=xxx         rootfs partition label on usb device (Default is Estuary)
  
for example:
	mkisoimg.sh --platform=D02 -distros=Ubuntu,OpenSuse \\
	--capacity=50,50 --bindir=./workspace/binary
	mkisoimg.sh --platform=D02 -distros=Ubuntu,OpenSuse \\
	--capacity=50,50 --bindir=./workspace/binary --disklabel=Estuary

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
if [ x"$PLATFORM" = x"" ] || [ x"$DISTROS" = x"" ] || [ x"$BINARY_DIR" = x"" ]; then
	echo "Error! Please check the parameters!" >&2
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
cp $BINARY_DIR/arm64/grub*.efi ./
cp $BINARY_DIR/arm64/Image ./
cp $BINARY_DIR/arm64/mini-rootfs-arm64.cpio.gz ./
cp $BINARY_DIR/arm64/deploy-utils.tar.bz2 ./

cp $TOPDIR/setup.sh ./

###################################################################################
# Copy distros
###################################################################################
echo "Copy distributions to workspace configured by estuarycfg.json ......"

distros=`echo $DISTROS | tr ',' ' '`
for distro in ${distros[*]}; do
	echo "Copy distribution ${distro}_ARM64.tar.gz to workspace ......"
	cp $BINARY_DIR/arm64/${distro}_ARM64.tar.gz ./
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

cat > ./usr/bin/Estuary.txt << EOF
PLATFORM=$PLATFORM
DISTROS=$DISTROS
CAPACITY=$CAPACITY
EOF

cp ../estuarycfg.json ./usr/bin/
mv ../setup.sh ./usr/bin/
tar jxvf ../deploy-utils.tar.bz2 -C ./
rm -f ../deploy-utils.tar.bz2
sudo chmod 755 ./usr/bin/setup.sh

sudo chown -R root:root *
find | sudo cpio -o -H newc | gzip -c > ../initrd.gz

popd
sudo rm -rf rootfs

###################################################################################
# Create grub.cfg
###################################################################################
distros=`echo $DISTROS | tr ',' ' '`
platform=$(echo $PLATFORM | tr "[:upper:]" "[:lower:]")

if [ x"D02" = x"$PLATFORM" ]; then
	cmd_line="rdinit=/init crashkernel=256M@32M console=ttyS0,115200 earlycon=uart8250,mmio32,0x80300000"
elif [ x"D03" = x"$PLATFORM" ]; then
	cmd_line="rdinit=/init console=ttyS0,115200 earlycon=hisilpcuart,mmio,0xa01b0000,0,0x2f8"
else
	echo "Error! Unsupport platform!" ; exit 1
fi

Image="`ls Image*`"
Initrd="`ls initrd*.gz`"

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
cp grubaa64.efi EFI/GRUB2/grubaa64.efi

sudo dd if=/dev/zero of=boot.img bs=1M count=4 2>/dev/null
sudo mkfs.vfat boot.img
sudo mount boot.img /mnt/
sudo cp -r EFI /mnt/
# sync
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


