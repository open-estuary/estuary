#!/bin/bash
###################################################################################
# mkisoimg.sh --platforms=D03 --distros=Ubuntu,OpenSuse --capacity=50,50 --bindir=./workspace
# mkisoimg.sh --platforms=D03,D05 --distros=Ubuntu,OpenSuse,CentOS --capacity=50,50 --bindir=./workspace
###################################################################################
TOPDIR=$(cd `dirname $0` ; pwd)
. $TOPDIR/../include/file-check.sh

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

D03_VGA_CMDLINE="console=tty0 pcie_aspm=off pci=pci_bus_perf"
D03_CMDLINE="console=ttyS0,115200 pcie_aspm=off pci=pci_bus_perf"
D05_VGA_CMDLINE="console=tty0 pcie_aspm=off pci=pci_bus_perf"
D05_CMDLINE="pcie_aspm=off pci=pci_bus_perf"

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
    --platforms=xxx,xxx     which platforms to deploy (D03, D05)
    --distros=xxx,xxx       which distros to deploy (Ubuntu, Fedora, OpenSuse, Debian, CentOS)
    --capacity=xxx,xxx      capacity for distros on install disk, unit GB (suggest 50GB)
    --bindir=xxx            binary directory
    --disklabel=xxx         rootfs partition label on usb device (Default is Estuary)

for example:
    mkisoimg.sh --platforms=D03 --distros=Ubuntu,OpenSuse \\
    --capacity=50,50 --bindir=./workspace
    mkisoimg.sh --platforms=D03,D05 --distros=Ubuntu,OpenSuse \\
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
# Check update
###################################################################################
if [ -f $BINARY_DIR/${DISK_LABEL}.iso ] && [ -f $BINARY_DIR/.${DISK_LABEL}.iso.txt ]; then
    while true; do
        platforms=`grep -Po "(?<=PLATFORMS=)(.*)" 2>/dev/null $BINARY_DIR/.${DISK_LABEL}.iso.txt`
        distros=`grep -Po "(?<=DISTROS=)(.*)" 2>/dev/null $BINARY_DIR/.${DISK_LABEL}.iso.txt`
        capacity=`grep -Po "(?<=CAPACITY=)(.*)" 2>/dev/null $BINARY_DIR/.${DISK_LABEL}.iso.txt`
        if [ x"$platforms" != x"$PLATFORMS" ] || [ x"$distros" != x"$DISTROS" ] || [ x"$capacity" != x"$CAPACITY" ]; then
            break
        fi
        distros=`echo ${DISTROS} | tr ',' ' '`
        distro_files=($(for f in $distros; do echo $BINARY_DIR/${f}_ARM64.tar.gz; done))
        check_file_update $BINARY_DIR/${DISK_LABEL}.iso $BINARY_DIR/Image ${distro_files[@]} && exit 0
        break
    done
fi

rm -f $BINARY_DIR/${DISK_LABEL}.iso $BINARY_DIR/.${DISK_LABEL}.iso.txt

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

sed -i '/eth0/s/^/#/g' ./etc/network/interfaces

sudo chown -R root:root *
sudo find | sudo cpio -o -H newc | gzip -c > ../initrd.gz || exit 1

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
set default=${default_plat}_minilinux_vga

EOF

for plat in ${platforms[*]}; do
    eval vga_cmd_line=\$${plat}_VGA_CMDLINE
    eval console_cmd_line=\$${plat}_CMDLINE
    platform=`echo $plat | tr "[:upper:]" "[:lower:]"`
    cat >> grub.cfg << EOF
# Booting initrd for $plat (VGA)
menuentry "Install $plat estuary (VGA)" --id ${platform}_minilinux_vga {
    linux /$Image $vga_cmd_line
    initrd /$Initrd
}

# Booting initrd for $plat (Console)
menuentry "Install $plat estuary (Console)" --id ${platform}_minilinux_console {
    linux /$Image $console_cmd_line
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
mv ${DISK_LABEL}.iso $BINARY_DIR/ || exit 1

cat > $BINARY_DIR/.${DISK_LABEL}.iso.txt << EOF
PLATFORMS=$PLATFORMS
DISTROS=$DISTROS
CAPACITY=$CAPACITY
EOF

###################################################################################
# Delete workspace
###################################################################################
sudo rm -rf $WORKSPACE 2>/dev/null
echo "Create ISO deployment environment successful!"
echo ""

exit 0

