#!/bin/bash

TOPDIR=$(cd `dirname $0` ; pwd)
. $TOPDIR/../include/common-func.sh

###################################################################################
# Global args
###################################################################################
TARGET=
BOARD_MAC=
PLATFORM=
DISTROS=
OUTPUT_DIR=

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
Usage: quick-deploy.sh --target=xxx --boardmac=xxx,xxx --platform=xxx --distros=xxx,xxx --output=xxx
	--target: deploy type and device (usb, iso, pxe)
		for usb, you can use "--target=usb:/dev/sdb" to install deploy files into /dev/sdb;
		for iso, you can use "--target=iso:Estuary.iso" to create Estuary.iso deploy media;
		for pxe, you can use "--target=pxe" to setup the pxe on the host.
		if usb device is not specified, the first usb storage device will be default.
		if iso file name not specified, the "Estuary_<PLAT>.iso" will be default.
	--boardmac: if you pxe deploy type, use "--boardmac" to specify the target board mac addresses.
	--platform: which platform to deploy
	--distros: which distros to deploy
	--binary: target binary directory

Example:
	./estuary/quick-deploy.sh --target=usb --platform=D02 --distros=Ubuntu,CentOS --binary=./workspace/binary
	./estuary/quick-deploy.sh --target=usb:/dev/sdb --platform=D02 --distros=Ubuntu,CentOS --binary=./workspace/binary
	./estuary/quick-deploy.sh --target=iso --platform=D02 --distros=Ubuntu,CentOS --binary=./workspace/binary
	./estuary/quick-deploy.sh --target=iso:Estuary_D02.iso --platform=D02 --distros=Ubuntu,CentOS --binary=./workspace/binary
	./estuary/quick-deploy.sh --target=pxe --boardmac=01-00-18-82-05-00-7f,01-00-18-82-05-00-68 --platform=D02 --distros=Ubuntu,CentOS --binary=./workspace/binary

EOF
}

###################################################################################
# iso_deploy
###################################################################################
iso_deploy()
{
}

###################################################################################
# usb_deploy
###################################################################################
usb_deploy()
{
}

###################################################################################
# pxe_deploy
###################################################################################
pxe_deploy()
{
}

###################################################################################
# deploy_entry <cfgfile>
###################################################################################
deploy_entry()
{
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
		--boardmac) BOARD_MAC=$ac_optarg ;;
		--platform) PLATFORM=$ac_optarg ;;
		--distros) DISTROS=$ac_optarg ;;
		--output) OUTPUT_DIR=$ac_optarg ;;
		*) echo "Error! Unknown option $ac_option!"
			quick_deploy_usage ; exit 1 ;;
        esac

        shift
done

###################################################################################
# check args
###################################################################################
if [ x"$TARGET" = x"" ] || [ x"$PLATFORM" = x"" ] || [ x"$DISTROS" = x"" ] || [ x"$OUTPUT_DIR" = x"" ]; then
	quick_deploy_usage ; exit 1
fi

deploy_type=`echo "$arg" | awk -F ':' '{print $1}'`
deploy_device=`echo "$arg" | awk -F ':' '{print $2}'`
if [ x"$deploy_type" = x"usb" ]; then
	if [ x"$deploy_device" != x"" ]; then
		if [ ! -b $deploy_device ]; then
			echo "Error! Specified usb device is not exist!" ; exit 1
		fi
	else

	fi
	mkusbinstall.sh --target=$deploy_device --platform=$PLATFORM -distros=$DISTROS --bindir=$OUTPUT_DIR

elif [ x"$deploy_type" = x"iso" ]; then
elif [ x"$deploy_type" = x"pxe" ]; then
else
	echo "Unknow deploy type!" >&2 ; exit 1
fi

