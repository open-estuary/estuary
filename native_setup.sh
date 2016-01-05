#!/bin/bash
#description: setup PXE environment for deploying estuary.
#author: wangyanliang
#date: October 28, 2015

cwd=`dirname $0`
. $cwd/common.sh

echo "--------------------------------------------------------------------------------"

to_install_packages="jq parted dosfstools"
install_packages to_install_packages

default_config=$cwd/estuarycfg.json
echo "--------------------------------------------------------------------------------"
echo "Please specify estuary config file (press return to use:$default_config)"
read -p "[ $default_config ] " CFGFILE

if [ ! -n "$CFGFILE" ]; then
    CFGFILE=$default_config
fi
echo "--------------------------------------------------------------------------------"
parse_config $CFGFILE

DISTROS=()
idx=0
idx_en=0
install=`jq -r ".distros[$idx].install" $CFGFILE`
while [ x"$install" != x"null" ];
do
    if [ x"yes" = x"$install" ]; then
        idx_en=${#DISTROS[@]}
        DISTROS[${#DISTROS[@]}]=`jq -r ".distros[$idx].name" $CFGFILE`
    fi
    name=`jq -r ".distros[$idx].name" $CFGFILE`
    value=`jq -r ".distros[$idx].install" $CFGFILE`
    case $name in
        "Ubuntu")
        ubuntu_en=$value
        ;;
        "OpenSuse")
        opensuse_en=$value
        ;;
        "Fedora")
        fedora_en=$value
        ;;
        "Debian")
        debian_en=$value
        ;;
        *)
        ;;
    esac
    let idx=$idx+1
    install=`jq -r ".distros[$idx].install" $CFGFILE`
done

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
    cp_distros

sudo ./sys_setup.sh

echo "--------------------------------------------------------------------------------"
echo "Operation finished!"
echo "--------------------------------------------------------------------------------"
