#!/bin/bash
###################################################################################
# mkpxe.sh --platforms=D02 --distros=Ubuntu,OpenSuse --boardmac=01-00-18-82-05-00-7f,01-00-18-82-05-00-68 --capacity=50,50 --bindir=./workspace
# mkpxe.sh --platforms=D02,D03 --distros=Ubuntu,OpenSuse --boardmac=01-00-18-82-05-00-7f,01-00-18-82-05-00-68 --capacity=50,50 --bindir=./workspace --net=eth0
###################################################################################
TOPDIR=$(cd `dirname $0` ; pwd)
export PATH=$TOPDIR:$PATH
. pxe-func.sh

###################################################################################
# Global variable
###################################################################################
BOARDSMAC=
PLATFORMS=
DISTROS=
CAPACITY=
BINARY_DIR=

WORKSPACE=

TFTP_ROOT=
NFS_ROOT=
NETCARD_NAME=
SERVER_IP=

D02_CMDLINE="rdinit=/init crashkernel=256M@32M console=ttyS0,115200 earlycon=uart8250,mmio32,0x80300000 pcie_aspm=off"
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
# mkusbinstall.sh usage
###################################################################
Usage: mkpxe.sh [OPTION]... [--OPTION=VALUE]...
	-h, --help              display this help and exit
	--boardmac=xxx,xxx      target boards mac
	--platforms=xxx,xxx     which platforms to deploy (D02, D03)
	--distros=xxx,xxx       which distros to deploy (Ubuntu, Fedora, OpenSuse, Debian, CentOS)
	--capacity=xxx,xxx      capacity for distros on install disk, unit GB (suggest 50GB)
	--bindir=xxx            binary directory
	--tftproot=xxx          tftp root directory (if not specified, you can select it in runing)
	--nfsroot=xxx           nfs root directory (if not specified, you can select it in runing)
	--net=xxx               wich ethernet card that the boards will connect to (if not specified, you can select it in runing)

  
for example:
	mkpxe.sh --platforms=D02 --distros=Ubuntu,OpenSuse --boardmac=01-00-18-82-05-00-7f,01-00-18-82-05-00-68 \\
	--capacity=50,50 --bindir=./workspace
	mkpxe.sh --platforms=D02,D03 --distros=Ubuntu,OpenSuse --boardmac=01-00-18-82-05-00-7f,01-00-18-82-05-00-68 \\
	--capacity=50,50 --bindir=./workspace --net=eth0

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
		--boardmac) BOARDSMAC=$ac_optarg ;;
		--platforms) PLATFORMS=$ac_optarg ;;
		--distros) DISTROS=$ac_optarg ;;
		--capacity) CAPACITY=$ac_optarg ;;
		--bindir) BINARY_DIR=$(cd $ac_optarg ; pwd) ;;
		--tftproot) TFTP_ROOT=$ac_optarg ;;
		--nfsroot) NFS_ROOT=$ac_optarg ;;
		--net) NETCARD_NAME=$ac_optarg ;;
		*) echo "Unknow option $ac_option!" >&2 ; Usage ; exit 1 ;;
	esac

	shift
done

###################################################################################
# Check parameters
###################################################################################
if  [ x"$PLATFORMS" = x"" ] || [ x"$DISTROS" = x"" ] || [ x"$CAPACITY" = x"" ] || [ x"$BINARY_DIR" = x"" ] || [ x"$BOARDSMAC" = x"" ]; then
	echo "board mac: $BOARDSMAC, platforms: $PLATFORMS, distros: $DISTROS, capacity: $CAPACITY, bindir: $BINARY_DIR"
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
# Setup PXE server
###################################################################################
if [ x"$TFTP_ROOT" = x"" ]; then
	get_pxe_tftproot TFTP_ROOT || exit 1
fi

if [ x"$NFS_ROOT" = x"" ]; then
	get_pxe_nfsroot NFS_ROOT || exit 1
fi

if [ x"$NETCARD_NAME" = x"" ]; then
	if ! get_pxe_interface NETCARD_NAME; then
		exit 1
	fi
fi
SERVER_IP=`ifconfig $NETCARD_NAME 2>/dev/null | grep -Po "(?<=inet addr:)([^ ]*)"`


sudo mkdir -p $TFTP_ROOT $NFS_ROOT
sudo chown -R $USER $TFTP_ROOT
sudo chown -R $USER $NFS_ROOT

TFTP_ROOT=`cd $TFTP_ROOT; pwd`
NFS_ROOT=`cd $NFS_ROOT; pwd`

if ! setup-pxe.sh --tftproot=$TFTP_ROOT --nfsroot=$NFS_ROOT --net=$NETCARD_NAME; then
	echo "Error! Setup PXE server failed!" >&2 ; exit 1
fi

NFS_ROOT=`mktemp -d $NFS_ROOT/rootfs.XXXX`

###################################################################################
# Create Workspace and Switch to Workspace!!!
###################################################################################
WORKSPACE=`mktemp -d workspace.XXXX`
pushd $WORKSPACE >/dev/null

cat > $NFS_ROOT/estuary.txt << EOF
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

cp $BINARY_DIR/grub*.efi $NFS_ROOT/grubaa64.efi || exit 1
cp $BINARY_DIR/Image $NFS_ROOT/ || exit 1

###################################################################################
# Copy distros
###################################################################################
echo "Copy distros to $NFS_ROOT......"

distros=($(echo $DISTROS | tr ',' ' '))
for distro in ${distros[*]}; do
	echo "Copy distro ${distro}_ARM64.tar.gz to $NFS_ROOT......"
	cp $BINARY_DIR/${distro}_ARM64.tar.gz $NFS_ROOT || exit 1
done

echo "Copy distros to $NFS_ROOT done!"
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
	linux /$Image $cmd_line root=/dev/nfs rw nfsroot=${SERVER_IP}:${NFS_ROOT} ip=dhcp
	initrd /$Initrd
}

EOF
done

boards_mac=($(echo $BOARDSMAC | tr "[:upper:]" "[:lower:]" | tr ',' ' '))
for board_mac in ${boards_mac[*]}; do
	cp grub.cfg $TFTP_ROOT/grub.cfg-${board_mac} || exit 1
done


mv grub*.efi $TFTP_ROOT/grubaa64.efi || exit 1
mv $Image $TFTP_ROOT/ || exit 1
mv $Initrd $TFTP_ROOT/ || exit 1

###################################################################################
# Pop Workspace!!!
###################################################################################
popd >/dev/null

# sync

###################################################################################
# Delete workspace
###################################################################################
sudo rm -rf $WORKSPACE 2>/dev/null
echo "Setup PXE deployment environment successful!"
echo ""

exit 0

