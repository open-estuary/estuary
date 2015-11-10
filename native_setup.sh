#!/bin/bash
#description: setup PXE environment for deploying estuary.
#author: wangyanliang
#date: October 28, 2015

cwd=`dirname $0`
. $cwd/common.sh

echo "--------------------------------------------------------------------------------"

#copy/paste programs
cp_progress ()
{
	CURRENTSIZE=0
	while [ $CURRENTSIZE -lt $TOTALSIZE ]
	do
		TOTALSIZE=$1;
		TOHERE=$2;
		CURRENTSIZE=`sudo du -c $TOHERE | grep total | awk {'print $1'}`
		echo -e -n "$CURRENTSIZE /  $TOTALSIZE copied \r"
		sleep 1
	done
}

cat << EOM
Begin to parse estuary.cfg ...
EOM
while read line
do
    name=`echo $line | awk -F '=' '{print $1}'`
    value=`echo $line | awk -F '=' '{print $2}'`
    case $name in
        "arch")
        TARGET_ARCH=$value
        ;;
        "platform")
        build_PLATFORM=$value
        ;;
        "distro")
        build_DISTRO=$value
        ;;
        "ubuntu")
        ubuntu_en=$value
        ;;
        "opensuse")
        opensuse_en=$value
        ;;
        "fedora")
        fedora_en=$value
        ;;
        "debian")
        debian_en=$value
        ;;
        *)
        ;;
    esac
done < estuary.cfg

pwd=`pwd`
pushd ..
if [ ! -d build/$build_PLATFORM/binary ]
then
    # Make sure that the build.sh file exists
    if [ -f $PWD/estuary/build.sh ]; then
        $PWD/estuary/build.sh -p $build_PLATFORM -d Ubuntu
        echo "execute build.sh"
    else
        echo "build.sh does not exist in the directory"
        exit 1
    fi
fi
popd

mkdir -p /sys_setup/boot/EFI/GRUB2 2> /dev/null
mkdir -p /sys_setup/distro 2> /dev/null
mkdir -p /sys_setup/bin 2> /dev/null
cp -a $cwd/../build/$build_PLATFORM/binary/grubaa64* /sys_setup/boot/EFI/GRUB2
cp -a $cwd/../build/$build_PLATFORM/binary/Image_$build_PLATFORM /sys_setup/boot/Image
cp -a $cwd/../build/$build_PLATFORM/binary/hip05-d02.dtb /sys_setup/boot
if [ "$ubuntu_en" == "y" ]; then
    mkdir -p /sys_setup/distro/$build_PLATFORM/ubuntu$TARGET_ARCH 2> /dev/null
    TOTALSIZE=`sudo du -c ../distro/Ubuntu_"$TARGET_ARCH".tar.gz | grep total | awk {'print $1'}`
    cp -af $cwd/../distro/Ubuntu_"$TARGET_ARCH".tar.gz /sys_setup/distro/$build_PLATFORM/ubuntu$TARGET_ARCH &
    cp_progress $TOTALSIZE /sys_setup/distro/$build_PLATFORM/ubuntu$TARGET_ARCH
fi
if [ "$fedora_en" == "y" ]; then
    pushd ..
    if [ -f $PWD/estuary/build.sh ]; then
        $PWD/estuary/build.sh -p $build_PLATFORM -d Fedora
    fi
    popd
    mkdir -p /sys_setup/distro/$build_PLATFORM/fedora$TARGET_ARCH 2> /dev/null
    cp -a $cwd/../distro/Fedora_"$TARGET_ARCH".tar.gz /sys_setup/distro/$build_PLATFORM/fedora$TARGET_ARCH
fi
if [ "$debian_en" == "y" ]; then
    pushd ..
    if [ -f $PWD/estuary/build.sh ]; then
        $PWD/estuary/build.sh -p $build_PLATFORM -d Debian
    fi
    popd
    mkdir -p /sys_setup/distro/$build_PLATFORM/debian$TARGET_ARCH 2> /dev/null
    cp -a $cwd/../distro/Debian_"$TARGET_ARCH".tar.gz /sys_setup/distro/$build_PLATFORM/debian$TARGET_ARCH
fi
if [ "$opensuse_en" == "y" ]; then
    pushd ..
    if [ -f $PWD/estuary/build.sh ]; then
        $PWD/estuary/build.sh -p $build_PLATFORM -d OpenSuse
    fi
    popd
    mkdir -p /sys_setup/distro/$build_PLATFORM/opensuse$TARGET_ARCH 2> /dev/null
    cp -a $cwd/../distro/OpenSuse_"$TARGET_ARCH".tar.gz /sys_setup/distro/$build_PLATFORM/opensuse$TARGET_ARCH
fi

cp -a post_install.sh /sys_setup/bin

sudo ./sys_setup.sh

echo "--------------------------------------------------------------------------------"
echo "Operation finished!"
echo "--------------------------------------------------------------------------------"
