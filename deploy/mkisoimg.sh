#!/bin/bash
###################################################################################
# mkisoimg.sh --platforms=D02 --distros=Ubuntu,OpenSuse --capacity=50,50 --bindir=./workspace
# mkisoimg.sh --platforms=D02,D03 --distros=Ubuntu,OpenSuse --capacity=50,50 --bindir=./workspace
###################################################################################
TOPDIR=$(cd `dirname $0` ; pwd)

###################################################################################
# Global variable
###################################################################################
TARGET=
PLATFORMS=
DISTROS=
CAPACITY=
BINARY_DIR=
DISK_LABEL="Estuary"

BOOT_PARTITION_SIZE=200
WORKSPACE=

D02_CMDLINE="rdinit=/init crashkernel=256M@32M console=ttyS0,115200 earlycon=uart8250,mmio32,0x80300000 pcie_aspm=off acpi=force"
D03_CMDLINE="rdinit=/init console=ttyS0,115200 earlycon=hisilpcuart,mmio,0xa01b0000,0,0x2f8 pcie_aspm=off acpi=force"
D05_CMDLINE="rdinit=/init console=ttyAMA0,115200 earlycon=pl011,mmio,0x602B0000 pcie_aspm=off crashkernel=256M@32M acpi=force"
HiKey_CMDLINE="rdinit=/init console=tty0 console=ttyAMA3,115200 rootwait rw loglevel=8 efi=noruntime"

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
	--platforms=xxx,xxx     which platforms to deploy (D02, D03)
	--distros=xxx,xxx       which distros to deploy (Ubuntu, Fedora, OpenSuse, Debian, CentOS)
	--capacity=xxx,xxx      capacity for distros on install disk, unit GB (suggest 50GB)
	--bindir=xxx            binary directory
	--disklabel=xxx         rootfs partition label on usb device (Default is Estuary)
  
for example:
	mkisoimg.sh --platforms=D02 --distros=Ubuntu,OpenSuse \\
	--capacity=50,50 --bindir=./workspace
	mkisoimg.sh --platforms=D02,D03 --distros=Ubuntu,OpenSuse \\
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
		--platforms) PLATFORMS=$ac_optarg ;;
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
if [ x"$PLATFORMS" = x"" ] || [ x"$DISTROS" = x"" ] || [ x"$CAPACITY" = x"" ] || [ x"$BINARY_DIR" = x"" ]; then
	echo "target: $TARGET, platforms: $PLATFORMS, distros: $DISTROS, capacity: $CAPACITY, bindir: $BINARY_DIR"
	echo "Error! Please all parameters are right!" >&2
	Usage ; exit 1
fi

distros=($(echo "$DISTROS" | tr ',' ' '))
capacity=($(echo "$CAPACITY" | tr ',' ' '))
if [[ ${#distros[@]} != ${#capacity[@]} ]]; then
	echo "Error! Number of capacity is not eq the distros!" >&2
	Usage ; exit 1
fi

###################################################################################
# Create Workspace and Switch to Workspace!!!
###################################################################################
WORKSPACE=`mktemp -d workspace.XXXX`
rm -f ${DISK_LABEL}.iso
pushd $WORKSPACE >/dev/null

cat > estuary.txt << EOF
PLATFORM=$PLATFORMS
DISTRO=$DISTROS
CAPACITY=$CAPACITY
EOF

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
echo "Copy distros to $WORKSPACE......"

distros=($(echo $DISTROS | tr ',' ' '))
for distro in ${distros[*]}; do
	echo "Copy distro ${distro}_ARM64.tar.gz to $WORKSPACE......"
	cp $BINARY_DIR/${distro}_ARM64.tar.gz ./ || exit 1
done

echo "Copy distros to $WORKSPACE done!"
echo ""

###################################################################################
# Create initrd file
###################################################################################
user=`whoami`
group=`groups | awk '{print $1}'`
mkdir rootfs

pushd rootfs >/dev/null
zcat ../mini-rootfs.cpio.gz | sudo cpio -dimv || exit 1
rm -f ../mini-rootfs.cpio.gz
sudo chown -R ${user}:${group} *

tar jxvf ../deploy-utils.tar.bz2 -C ./ || exit 1
rm -f ../deploy-utils.tar.bz2

if ! (grep "/usr/bin/setup.sh" etc/init.d/rcS); then
	echo "/usr/bin/setup.sh" >> etc/init.d/rcS || exit 1
fi

sed -i "s/\(DISK_LABEL=\"\).*\(\"\)/\1$DISK_LABEL\2/g" ../setup.sh
mv ../setup.sh ./usr/bin/
sudo chmod 755 ./usr/bin/setup.sh

sudo chown -R root:root *
find | sudo cpio -o -H newc | gzip -c > ../initrd.gz || exit 1

popd >/dev/null
sudo rm -rf rootfs

###################################################################################
# Create grub.cfg
###################################################################################
Image="`ls Image*`"
Initrd="`ls initrd*.gz`"
platforms=(`echo $PLATFORMS | tr ',' ' '`)
default_plat=`echo ${platforms[0]} | tr "[:upper:]" "[:lower:]"`

cat > grub.cfg << EOF
# NOTE: Please remove the unused boot items according to your real condition.
# Sample GRUB configuration file
#

# Boot automatically after 5 secs.
set timeout=5

# By default, boot the Linux
set default=${default_plat}_minilinux

EOF

for plat in ${platforms[*]}; do
	eval cmd_line=\$${plat}_CMDLINE
	platform=`echo $plat | tr "[:upper:]" "[:lower:]"`
	cat >> grub.cfg << EOF
# Booting initrd for $plat
menuentry "Install $plat estuary" --id ${platform}_minilinux {
	linux /$Image $cmd_line
	initrd /$Initrd
}

EOF

done

###################################################################################
# Create EFI System
###################################################################################
mkdir -p EFI/GRUB2/
cp grubaa64.efi EFI/GRUB2/grubaa64.efi || exit 1

sudo dd if=/dev/zero of=boot.img bs=1M count=4 2>/dev/null || exit 1
sudo mkfs.vfat boot.img || exit 1
sudo mount boot.img /mnt/ || exit 1
sudo cp -r EFI /mnt/ || exit 1
# sync
sudo umount /mnt/

###################################################################################
# Create bootable iso
###################################################################################
genisoimage -e boot.img -no-emul-boot -J -R -c boot.catalog -hide boot.catalog -hide boot.img -V "$DISK_LABEL" -o ${DISK_LABEL}.iso . || exit 1
mv ${DISK_LABEL}.iso ../ || exit 1

###################################################################################
# Pop Workspace!!!
###################################################################################
popd >/dev/null

###################################################################################
# Delete workspace
###################################################################################
sudo rm -rf $WORKSPACE 2>/dev/null
echo "Create ISO deployment environment successful!"
echo ""

exit 0

