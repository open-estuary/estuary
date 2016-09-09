#!/bin/bash
###################################################################################
# mkdeploydisk.sh --target=/dev/sdb --platforms=D05 --distros=CentOS --capacity=50 \
#   --server=http://download.open-estuary.org/AllDownloads/DownloadsEstuary/pre-releases/2.3/rc1/linux
###################################################################################
TOPDIR=$(cd `dirname $0` ; pwd)

###################################################################################
# Global variable
###################################################################################
TARGET=
PLATFORMS=
DISTROS=
CAPACITY=
ESTUARY_FTP=
DISK_LABEL="Estuary"

BOOT_PARTITION_SIZE=200
WORKSPACE=

D02_CMDLINE="rdinit=/init crashkernel=256M@32M console=ttyS0,115200 earlycon=uart8250,mmio32,0x80300000 pcie_aspm=off"
D03_CMDLINE="rdinit=/init console=ttyS0,115200 earlycon=hisilpcuart,mmio,0xa01b0000,0,0x2f8 pcie_aspm=off"
D05_CMDLINE="rdinit=/init console=ttyAMA0,115200 earlycon=pl011,mmio,0x602B0000 pcie_aspm=off crashkernel=256M@32M acpi=force"
HiKey_CMDLINE="rdinit=/init console=tty0 console=ttyAMA3,115200 rootwait rw loglevel=8 efi=noruntime"

###################################################################################
# Usage
###################################################################################
Usage()
{
cat << EOF
###################################################################
# mkdeploydisk.sh usage
###################################################################
Usage: mkdeploydisk.sh [OPTION]... [--OPTION=VALUE]...
	-h, --help              display this help and exit
	--target=xxx            deploy usb device
	--platforms=xxx,xxx     which platforms to deploy (D02, D03)
	--distros=xxx,xxx       which distros to deploy (Ubuntu, Fedora, OpenSuse, Debian, CentOS)
	--capacity=xxx,xxx      capacity for distros on install disk, unit GB (suggest 50GB)
	--server=xxx            release binary version files http address, see example for detials
	--workspace=            workspace directory
	--disklabel=xxx         rootfs partition label on usb device (Default is Estuary)
  
for example:
	mkdeploydisk.sh --target=/dev/sdb --platforms=D05 --distros=CentOS \\
	--capacity=50 --server=http://download.open-estuary.org/AllDownloads/DownloadsEstuary/pre-releases/2.3/rc1/linux

	mkdeploydisk.sh --target=/dev/sdb --platforms=D05 --distros=CentOS \\
	--capacity=50 --server=http://download.open-estuary.org/AllDownloads/DownloadsEstuary/releases/2.2/linux

EOF
}

###################################################################################
# int download_binary(string file_name, string http_addr)
###################################################################################
download_binary()
{
	local file_name=$1
	local http_addr=$2
	
	rm -f .${file_name}.sum 2>/dev/null
	wget -c ${http_addr}/${file_name}.sum || return 1
	mv ${file_name}.sum .${file_name}.sum

	if ! md5sum --quiet --check .${file_name}.sum 2>/dev/null; then
		rm -f ${file_name} 2>/dev/null
		wget -c ${http_addr}/${file_name} || return 1
		md5sum --quiet --check .${file_name}.sum 2>/dev/null || return 1
	fi
	
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
		--platforms) PLATFORMS=$ac_optarg ;;
		--distros) DISTROS=$ac_optarg ;;
		--capacity) CAPACITY=$ac_optarg ;;
		--server) ESTUARY_FTP=`echo $ac_optarg | sed 's/?dir=//g' | sed 's/\/*$//g'` ;;
		--workspace) WORKSPACE=$ac_optarg ;;
		--disklabel) DISK_LABEL=$ac_optarg ;;
		*) echo "Unknow option $ac_option!" ; Usage ; exit 1 ;;
	esac

	shift
done

###################################################################################
# Check parameters
###################################################################################
if [ x"$PLATFORMS" = x"" ] || [ x"$DISTROS" = x"" ] || [ x"$CAPACITY" = x"" ] || [ x"$ESTUARY_FTP" = x"" ]; then
	echo "target: $TARGET, platforms: $PLATFORMS, distros: $DISTROS, capacity: $CAPACITY, server: $ESTUARY_FTP"
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
# Check target usb device
###################################################################################
usb_devices=(`sudo lshw 2>/dev/null | grep "bus info: usb" -A 12 | grep "logical name: /dev/sd" | grep -Po "(/dev/sd.*)" | sort`)
if [ ${#usb_devices[@]} -eq 0 ]; then
	echo "Error! No usb device found!" >&2 ; exit 1
fi

if [ x"$TARGET" = x"" ]; then
	TARGET=${usb_devices[0]}
else
	if ! echo ${usb_devices[*]} | grep $TARGET >/dev/null 2>&1; then
		echo "Error! $TARGET is not a usb device!" >&2 ; exit 1
	fi
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
read -p "Continue to create the usb install disk on $TARGET? (y/n) " choice
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
if [ x"$WORKSPACE" = x"" ]; then
	WORKSPACE=`mktemp -d workspace.XXXX`
fi
sudo mount ${TARGET}2 $WORKSPACE
sudo chmod a+w $WORKSPACE
pushd $WORKSPACE >/dev/null

###################################################################################
# Download kernel, grub, mini-rootfs, setup.sh ...
###################################################################################
download_binary grubaa64.efi $ESTUARY_FTP/Common || exit 1
download_binary Image $ESTUARY_FTP/Common || exit 1
download_binary mini-rootfs.cpio.gz $ESTUARY_FTP/Common || exit 1
download_binary deploy-utils.tar.bz2 $ESTUARY_FTP/Common || exit 1
wget -c https://raw.githubusercontent.com/open-estuary/estuary/master/deploy/setup.sh || exit 1

###################################################################################
# Download distros
###################################################################################
echo "Download distros to $WORKSPACE......"

distros=($(echo $DISTROS | tr ',' ' '))
for distro in ${distros[*]}; do
	echo "Download distro ${distro}_ARM64.tar.gz to $WORKSPACE......"
	download_binary ${distro}_ARM64.tar.gz $ESTUARY_FTP/${distro}/Common || exit 1
done

echo "Download distros to $WORKSPACE done!"
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

cat > ./usr/bin/estuary.txt << EOF
PLATFORMS=$PLATFORMS
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

