#!/bin/bash

TOPDIR=$(cd `dirname $0` ; pwd)

###################################################################################
# Global args
###################################################################################
TARGET=
BOARDS_MAC=
PLATFORMS=
DISTROS=
CAPACITY=
BIN_DIR=

DEPLOY_TYPE=
TARGET_DEVICE=

###################################################################################
# Global vars
###################################################################################
ESTUARY_LABEL="Estuary"

###################################################################################
# quick_deploy_usage
###################################################################################
quick_deploy_usage()
{
cat << EOF
Usage: quick-deploy.sh --target=xxx --boardmac=xxx,xxx --platform=xxx,xxx --distros=xxx,xxx --capacity=xxx,xxx --output=xxx
	--target: deploy type and device (usb, iso, pxe)
		for usb, you can use "--target=usb:/dev/sdb" to install deploy files into /dev/sdb;
		for iso, you can use "--target=iso:Estuary.iso" to create Estuary.iso deploy media;
		for pxe, you can use "--target=pxe" to setup the pxe on the host.
		if usb device is not specified, the first usb storage device will be default.
		if iso file name not specified, the "Estuary_<PLAT>.iso" will be default.
	--boardmac: if you pxe deploy type, use "--boardmac" to specify the target board mac addresses.
	--platform: which platforms to deploy
	--distros: which distros to deploy
	--capacity: capacity for distros on install disk, unit GB (suggest 50GB)
	--binary: target binary directory

Example:
	quick-deploy.sh --target=usb --platform=D02,D03 --distros=Ubuntu,CentOS --binary=./workspace
	quick-deploy.sh --target=usb:/dev/sdb --platform=D02 --distros=Ubuntu,CentOS --binary=./workspace
	quick-deploy.sh --target=iso --platform=D02 --distros=Ubuntu,CentOS --binary=./workspace/binary
	quick-deploy.sh --target=iso:Estuary_D02.iso --platform=D02 --distros=Ubuntu,CentOS --binary=./workspace
	quick-deploy.sh --target=pxe --boardmac=01-00-18-82-05-00-7f,01-00-18-82-05-00-68 --platform=D02 --distros=Ubuntu,CentOS --binary=./workspace

EOF
}

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
		--target) TARGET=$ac_optarg ;;
		--boardmac) BOARDS_MAC=$ac_optarg ;;
		--platform) PLATFORMS=$ac_optarg ;;
		--distros) DISTROS=$ac_optarg ;;
		--capacity) CAPACITY=$ac_optarg ;;
		--binary) BIN_DIR=$ac_optarg ;;
		*) echo "Error! Unknown option $ac_option!"
			quick_deploy_usage ; exit 1 ;;
        esac

        shift
done

###################################################################################
# Check args
###################################################################################
if [ x"$TARGET" = x"" ] || [ x"$PLATFORMS" = x"" ] || [ x"$DISTROS" = x"" ] || [ x"$BIN_DIR" = x"" ]; then
	quick_deploy_usage ; exit 1
fi

###################################################################################
# Deploy
###################################################################################
deploy_type=`echo "$TARGET" | awk -F ':' '{print $1}'`
deploy_device=`echo "$TARGET" | awk -F ':' '{print $2}'`
platforms=`echo $PLATFORMS | tr ',' ' '`

if [ x"$deploy_type" = x"usb" ]; then
	for plat in ${platforms[*]}; do
		mkusbinstall.sh --target=$deploy_device --platform=$plat -distros=$DISTROS --capacity=$CAPACITY --bindir=$BIN_DIR || exit 1
	done
elif [ x"$deploy_type" = x"iso" ]; then
	for plat in ${platforms[*]}; do
		if [ ! -f $BIN_DIR/Estuary_${plat}.iso ]; then
			mkisoimg.sh --platform=$plat --distros=$DISTROS --capacity=$CAPACITY --disklabel="Estuary" --bindir=$BIN_DIR || exit 1
			mv Estuary_${plat}.iso $BIN_DIR/ || exit 1
		fi
	done
elif [ x"$deploy_type" = x"pxe" ]; then
	for plat in ${platforms[*]}; do
		mkpxe.sh --platform=$plat --distros=$DISTROS --capacity=$CAPACITY --boardmac=$BOARDS_MAC --bindir=$BIN_DIR || exit 1
	done
else
	echo "Unknow deploy type!" >&2 ; exit 1
fi

###################################################################################
# Report result
###################################################################################
echo "/*---------------------------------------------------------------"
echo "- quick deploy, deploy type: $deploy_type, platform: $PLATFORMS, distros: $DISTROS"
echo "- target device: $deploy_device, boards mac: $BOARDS_MAC"
echo "- done!"
echo "---------------------------------------------------------------*/"
echo ""
exit 0


