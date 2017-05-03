#!/bin/bash

###################################################################################
# Const variables
###################################################################################
TOPDIR=`pwd`
SUPPORTED_PLATFORM=(D03 D05)
ESTUARY_HTTP_ADDR="http://download.open-estuary.org/?dir=AllDownloads/DownloadsEstuary"
ESTUARY_FTP_ADDR="ftp://117.78.41.188"

D03_VGA_CMDLINE="console=tty0 pcie_aspm=off pci=pcie_bus_perf"
D03_CMDLINE="console=ttyS0,115200 pcie_aspm=off pci=pcie_bus_perf"
D05_VGA_CMDLINE="console=tty0 pcie_aspm=off pci=pcie_bus_perf"
D05_CMDLINE="pcie_aspm=off pci=pcie_bus_perf"

BOOT_PARTITION_SIZE=4
DISK_LABEL="Estuary"
WGET_OPTS="-T 120 -c"

###################################################################################
# Global variables
###################################################################################
TARGET=
VERSION=3.1
RC=rc0
PLATFORM=D05
DISTRO=
CAPACITY=50
BINDIR=

WORKSPACE=Workspace
ESTUARY_WEB_ADDR=$ESTUARY_FTP_ADDR

###################################################################################
# Usage
###################################################################################
Usage() {
cat << EOF
###################################################################
# mkdeploydisk.sh usage
###################################################################
Usage: mkdeploydisk.sh [OPTION]... [--OPTION=VALUE]...
    -h, --help              display this help and exit
    --target=xxx            target usb device which is used to make a bootable install usb disk
                                If not specified, the first usb storage device will be default
    --version=xxx           target estuary release version. If not specified, the latest will be default
    --rc=xxx                target release　candidate version
    --platform=xxx          target platform to install, it can be D03 or D05
    --distro=xxx            target distro to install
    --capacity=xxx          target root file system partition size (GB)

for example:
    mkdeploydisk.sh --help
    mkdeploydisk.sh
    mkdeploydisk.sh --version=3.0 --target=/dev/sdx --platform=D05 --distro=CentOS
    mkdeploydisk.sh --version=3.0 --rc=rc0 --target=/dev/sdx --platform=D05 --distro=CentOS
    mkdeploydisk.sh --target=/dev/sdx --platform=D05 --distro=CentOS

EOF


if [ x"$RC" = x"" ]; then
    distro_list=(`get_all_distro ${ESTUARY_WEB_ADDR}/releases/${VERSION}/linux`)
else
    distro_list=(`get_all_distro ${ESTUARY_WEB_ADDR}/pre-releases/${VERSION}/${RC}/linux`)
fi

echo "The Distros which can be selected are: ${distro_list[*]}"
}

###################################################################################
# string[] get_usb_devices(void)
###################################################################################
get_usb_devices() {
    (
    root=$(mount | grep " / " | grep  -Po "(/dev/sd[^ ])")
    if [ $? -ne 0 ]; then
        root="/dev/sdx"
    fi

    index=0
    usb_devices=()
    disk_devices=(`ls -l --color=auto /dev/disk/by-id/usb* | awk '{print $NF}' | grep -Pv "[0-9]"`)
    for disk in ${disk_devices[@]}; do
        name=${disk##*/}
        usb_devices[$index]=/dev/$name
        let index++
    done

    echo ${usb_devices[*]}
    )
}

###################################################################################
# int get_default_usb(sting &__usb_device)
###################################################################################
get_default_usb() {
    local __usb_device=$1
    local usb_devices=(`get_usb_devices`)
    local first_usb=${usb_devices[0]}
    if [ x"$first_usb" != x"" ]; then
        eval $__usb_device="'$first_usb'" ; return 0
    else
        return 1
    fi
}

###################################################################################
# int check_usb_device(string usb_device)
###################################################################################
check_usb_device() {
    (
    usb_device=$1
    if [ x"$usb_device" = x"" ] || [ ! -b $usb_device ]; then
        echo "Device $usb_device is not exist!" ; return 1
    else
        if sudo lshw 2>/dev/null | grep "bus info: usb" -A 12 | grep "logical name: /dev/sd" | grep $usb_device >/dev/null; then
            return 0
        else
            echo "Device $usb_device is not an usb device!" ; return 1
        fi
    fi
    )
}

###################################################################################
# int umount_device(string device)
###################################################################################
umount_device() {
    (
    device=$1
    mounted_partition=(`mount | grep -Po "^(${device}[^ ]*)"`)
    for part in ${mounted_partition[@]}; do
        sudo umount $part || return 1
    done
    )

    return 0
}

###################################################################################
# string get_proto_type(string web_addr)
###################################################################################
get_proto_type() {
    local web_addr=$1
    echo $web_addr | grep -Po "^(http|ftp)(?=\:.*)"
}

###################################################################################
# string[] get_ftp_dir(string ftp_addr)
###################################################################################
get_ftp_dir() {
    # local ftp_addr=`echo $1 | sed 's/\/\+/\//g' | sed 's/[^\/]$/&\//g'`
    local ftp_addr=`echo $1 | sed 's/\/\{2,\}$/\//g' | sed 's/[^\/]$/&\//g'`
    curl -s $ftp_addr | grep "^d.*" | awk '{print $NF}'
}

###################################################################################
# string[] get_http_dir(string http_addr)
###################################################################################
get_http_dir() {
    local http_addr=`echo $1 | sed 's/\/\{2,\}$/\//g'`
    curl -s $http_addr 2>/dev/null | grep 'class="item dir"' | sed 's/<[^<>]*>//g'
}

###################################################################################
# string[] get_all_version(string web_addr)
###################################################################################
get_all_version()
{
    local web_addr=$1
    local proto_type=`get_proto_type $web_addr`
    eval get_${proto_type}_dir $web_addr 2>/dev/null
}

###################################################################################
# int select_version(string estuary_web_addr, string &_version, string $_rc)
###################################################################################
select_version()
{
    local version=
    local rc=
    local use_releases=
    local estuary_web_addr=$1
    local _version=$2
    local _rc=$3
    read -t 5 -p "Use releases version? y/N (default y): " c
    if [ x"$c" = x"" ] || [ x"$c" = x"y" ]; then
        use_releases=yes
        estuary_web_addr=${estuary_web_addr}/releases
    else
        estuary_web_addr=${estuary_web_addr}/pre-releases
    fi

    local version_list=(`get_all_version $estuary_web_addr/ | sort -r`)
    if [ ${#version_list[@]} -eq 0 ]; then
        echo "Error! Get version from $estuary_web_addr/ failed!"; return 1
    fi

    echo ""
    echo "------------------------------------------------------"
    echo "- released version list"
    echo "------------------------------------------------------"
    local old_ps3="$PS3"
    PS3="Input the version index to install: "
    select version in ${version_list[*]}; do break; done
    PS3="$old_ps3"

    if [ x"$use_releases" != x"yes" ]; then
        local rc_list=(`get_all_version $estuary_web_addr/${version}/ | sort -r`)
        if [ ${#rc_list[@]} -eq 0 ]; then
            echo "Error! rc version from $estuary_web_addr/${version}/ failed!"; return 1
        fi
        echo "------------------------------------------------------"
        echo "- rc version list"
        echo "------------------------------------------------------"
        PS3="Input the rc index to install: "
        select rc in ${rc_list[*]}; do break; done
        PS3="$old_ps3"
    fi

    eval $_version=$version
    eval $_rc=$rc

    return 0
}

###################################################################################
# string[] get_all_distro(string web_addr)
###################################################################################
get_all_distro()
{
    local web_addr=$1
    local proto_type=`get_proto_type $web_addr`
    eval get_${proto_type}_dir $web_addr 2>/dev/null | grep -Pv "Common|Minirootfs" | sort
}

###################################################################################
# int download_file(string target_file, string target_dir)
###################################################################################
download_file() {
    (
    target_file=$1
    target_dir=$2

    pushd $target_dir >/dev/null
    target_file_name=`basename $target_file`
    md5sum --quiet --check .${target_file_name}.sum >/dev/null 2>&1 && return 0

    rm -f ${target_file_name}.sum .${target_file_name}.sum >/dev/null 2>&1
    wget ${target_file}.sum || return 1
    mv ${target_file_name}.sum .${target_file_name}.sum
    md5sum --quiet --check .${target_file_name}.sum >/dev/null 2>&1 && return 0
    rm -f $target_file_name >/dev/null 2>&1
    wget ${WGET_OPTS} $target_file && md5sum --quiet --check .${target_file_name}.sum >/dev/null 2>&1 && return 0
    popd >/dev/null

    return 1
    )
}

###################################################################################
# int create_partition(string device, int efi_partition_size, string rootfs_label)
###################################################################################
create_partition() {
    (
    device=$1
    efi_partition_size=$2
    rootfs_label=$3

    umount_device $device || return 1
    yes | sudo mkfs.ext4 $device >/dev/null || return 1
    echo -e "n\n\n\n\n+${efi_partition_size}M\nw\n" | sudo fdisk $device >/dev/null || return 1
    echo -e "t\nef\nw\n" | sudo fdisk $device >/dev/null || return 1
    yes | sudo mkfs.vfat ${device}1 >/dev/null || return 1

    echo -e "n\n\n\n\n\nw\n" | sudo fdisk $device >/dev/null || return 1
    yes | sudo mkfs.ext4 -L $rootfs_label ${device}2 >/dev/null || return 1
    )

    return 0
}

###################################################################################
# int create_grub_header(string grub_cfg_file)
###################################################################################
create_grub_header() {
    (
    grub_cfg_file=$1
cat > $grub_cfg_file << EOF
# NOTE: Please remove the unused boot items according to your real condition.
# Sample GRUB configuration file
#

# Boot automatically after 10 secs.
set timeout=10

# By default, boot the Linux
set default=xxxx

EOF
    )
}

###################################################################################
# int create_grub_menuentry(string grub_cfg_file, string title, string menuentry_id, sting image, string cmdline, string initrd)
###################################################################################
create_grub_menuentry() {
    (
    grub_cfg_file=$1
    title=$2
    menuentry_id=$3
    image=$4
    cmdline=$5
    initrd=$6
cat >> $grub_cfg_file << EOF
# Booting initrd for $plat
menuentry "$title" --id $menuentry_id {
    search --no-floppy --label --set=root $DISK_LABEL
    linux $image $cmdline
    initrd $initrd
}

EOF
    return 0
    )
}

###################################################################################
# int download_common_binary(string common_bin_dir)
###################################################################################
download_common_binary() {
    local common_bin_dir=$1
    download_file ${common_bin_dir}/Image ./ || return 1
    download_file ${common_bin_dir}/grubaa64.efi ./ || return 1
    download_file ${common_bin_dir}/deploy-utils.tar.bz2 ./ || return 1
    return 0
}

###################################################################################
# int download_mini_rootfs(string mini_rootfs_dir)
###################################################################################
download_mini_rootfs()
{
    local mini_rootfs_dir=$1
    download_file ${mini_rootfs_dir}/mini-rootfs.cpio.gz ./ || return 1
}

###################################################################################
# int download_distro(string distro_dir, string[] distro)
###################################################################################
download_distro() {
    (
    distro_dir=$1
    distro=$2
    for dist in ${distro[@]}; do
        download_file ${distro_dir}/${dist}/Common/${dist}_ARM64.tar.gz ./ || return 1
    done

    return 0
    )
}

###################################################################################
# int create_initrd(string rootfs, string deploy_utils)
###################################################################################
create_initrd() {
    (
    rootfs=$1
    deploy_utils=$2

    user=`whoami`
    group=`groups | awk '{print $1}'`

    zcat $rootfs | sudo cpio -dimv >/dev/null 2>/dev/null || return 1
    sudo tar xf $deploy_utils -C ./ || return 1

    sudo chown -R ${user}:${group} *
    if ! (grep "/usr/bin/setup.sh" etc/init.d/rcS); then
        echo "/usr/bin/setup.sh" >> etc/init.d/rcS || exit 1
    fi

    sed -i '/eth0/s/^/#/g' ./etc/network/interfaces
    sed -i "s/\(DISK_LABEL=\"\).*\(\"\)/\1$DISK_LABEL\2/g" ./usr/bin/setup.sh
    sudo chmod 755 ./usr/bin/setup.sh

    sudo chown -R root:root *
    sudo find | sudo cpio -o -H newc | gzip -c > ../initrd.gz || return 1

    return 0
    )
}

###################################################################################
# int clean_workspace(void)
###################################################################################
clean_workspace() {
    cd $TOPDIR
    umount_device $TARGET
    rmdir $WORKSPACE 2>/dev/null

    return 0
}

###################################################################################
# get the release of the current machine
##################################################################################
dist_name() {
    if [ -f /etc/os-release ]; then
        dist=$(. /etc/os-release && echo "${ID}")
    elif [ -x /usr/bin/lsb_release ]; then
        dist="$(lsb_release -si)"
    elif [ -f /etc/lsb-release ]; then
        dist="$(. /etc/lsb-release && echo "${DISTRIB_ID}")"
    elif [ -f /etc/debian_version ]; then
        dist="debian"
    elif [ -f /etc/fedora-release ]; then
        dist="fedora"
    elif [ -f /etc/centos-release ]; then
        dist="centos"
    else
        dist="unknown"
        echo "Unsupported distro: cannot determine distribution name"
    fi

    # convert dist to lower case
    dist=$(echo ${dist} | tr '[:upper:]' '[:lower:]')
}

###################################################################################
# install packages
###################################################################################
install_deps(){
    pkgs="$1"
    [ -z "${pkgs}" ] && echo "Usage: install_deps pkgs"
    echo "Installing ${pkgs}"
    dist_name
    case "${dist}" in
        debian|ubuntu)
            apt-get update -q -y
            apt-get install -q -y ${pkgs}
            ;;
        centos)
            yum -e 0 -y install ${pkgs}
            ;;
        fedora)
            dnf -e 0 -y install ${pkgs}
            ;;
        opensuse)
            zypper -q -y install ${pkgs}
            ;;
        *)
            echo "Unsupported distro: ${dist}! Package installation skipped."
            ;;
    esac
}

command -v curl >/dev/null 2>&1 || install_deps curl
command -v sudo >/dev/null 2>&1 || install_deps sudo
command -v lshw >/dev/null 2>&1 || install_deps lshw
command -v mkfs.vfat >/dev/null 2>&1 || install_deps dosfstools

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
        --platform) PLATFORM=$ac_optarg ;;
        --distro) DISTRO=$ac_optarg ;;
        --capacity) CAPACITY=$ac_optarg ;;
        --version) VERSION=$ac_optarg ;;
        --rc) RC=$ac_optarg ;;
        *) echo "Unknow option $ac_option!" ; Usage ; exit 1 ;;
    esac

    shift
done

###################################################################################
# Get/Check platform info
###################################################################################
if [ x"$PLATFORM" = x"" ] || !(echo ${SUPPORTED_PLATFORM[@]} | grep -w $PLATFORM >/dev/null 2>&1); then
    echo "------------------------------------------------------"
    echo "- supported platform list"
    echo "------------------------------------------------------"
    old_ps3="$PS3"
    PS3="Input the platform index to install: "
    select PLATFORM in ${SUPPORTED_PLATFORM[*]}; do break; done
    PS3="$old_ps3"
fi

###################################################################################
# Get/Check version info
###################################################################################
while true; do
    if [ x"$VERSION" != x"" ]; then
        if [ x"$RC" = x"" ]; then
            if (get_all_version $ESTUARY_WEB_ADDR/releases/ | grep -w $VERSION >/dev/null 2>&1); then
                break
            fi
        elif (get_all_version $ESTUARY_WEB_ADDR/pre-releases/ | grep -w $VERSION >/dev/null 2>&1 \
            && get_all_version $ESTUARY_WEB_ADDR/pre-releases/$VERSION | grep -w $RC >/dev/null 2>&1); then
            break
        fi
    fi

    if ! select_version $ESTUARY_WEB_ADDR VERSION RC; then
        echo "Get version from $ESTUARY_WEB_ADDR failed!"; exit 1
    fi

    break
done

###################################################################################
# Get/Check distro info
###################################################################################
distro_list=
if [ x"$RC" = x"" ]; then
    distro_list=(`get_all_distro ${ESTUARY_WEB_ADDR}/releases/${VERSION}/linux`)
else
    distro_list=(`get_all_distro ${ESTUARY_WEB_ADDR}/pre-releases/${VERSION}/${RC}/linux`)
fi

if [ ${#distro_list[@]} -eq 0 ]; then
    echo "Get distro info from ${ESTUARY_WEB_ADDR}/${VERSION}/linux failed!"; exit 1
fi

INSTALL_DISTRO=()
all_distros=()

if [ x"$DISTRO" != x"" ]; then
    DISTRO=$(echo $DISTRO | tr ',' ' ')
    all_distros=($DISTRO)
    index=0
    for distro in ${all_distros[*]};do
        if [ x"$(echo ${distro_list[*]} | grep -iw $distro)" = x"" ]; then
            DISTRO=${DISTRO/$distro/}
            echo "the distro $distro you have selected are not valid"
        else
            if echo $distro | grep -wi ubuntu >/dev/null 2>&1; then
                INSTALL_DISTRO[$index]="Ubuntu"
            elif echo $distro | grep -wi centos >/dev/null 2>&1; then
                INSTALL_DISTRO[$index]="CentOS"
            elif echo $distro | grep -wi debian >/dev/null 2>&1; then
                INSTALL_DISTRO[$index]="Debian"
            elif echo $distro | grep -wi opensuse >/dev/null 2>&1; then
                INSTALL_DISTRO[$index]="OpenSuse"
            elif echo $distro | grep -wi rancher >/dev/null 2>&1; then
                INSTALL_DISTRO[$index]="Rancher"
            elif echo $distro | grep -wi openembedded >/dev/null 2>&1; then
                INSTALL_DISTRO[$index]="OpenEmbedded"
            else
                if echo $distro | grep -wi fedora >/dev/null 2>&1; then
                    INSTALL_DISTRO[$index]="Fedora"
                fi
            fi
            let ++index
        fi
    done
fi

echo "The valid distro(s) is/are: ${INSTALL_DISTRO[@]}"

if [ x"$DISTRO" = x"" ];then
    echo "---------------------------------------------------------------------------------"
    echo "- select distros you want to install"
    echo "---------------------------------------------------------------------------------"
    total_distro=${#distro_list[@]}
    for ((index=0; index<${total_distro}; index++)); do
        read -n1 -t 5 -p "Install ${distro_list[index]} (default N)? y/N " c
        if [ x"$c" = x"y" ] || [ x"$c" = x"Y" ]; then
            INSTALL_DISTRO[${#INSTALL_DISTRO[@]}]=${distro_list[index]}
        fi
        echo  ""
    done

    if [ ${#INSTALL_DISTRO[@]} -eq 0 ]; then
        echo "You have not select any distros, will install CentOS default"
        INSTALL_DISTRO[${#INSTALL_DISTRO[@]}]="CentOS"
    fi
fi

###################################################################################
# Check distro capacity
###################################################################################
capacity_length=${#CAPACITY[@]}

if [ ${#INSTALL_DISTRO[@]} -ne $capacity_length ] && [ $capacity_length -gt 1 ]; then
    echo "The selected distros length is not the same with the capacity length"
    exit 1
fi

if [ $capacity_length -eq 1 ]; then
    length=${#INSTALL_DISTRO[@]}
    CAPACITYS=`printf -v v "%-*s" ${length} "" ; echo "${v// /$CAPACITY }"`
else
    if [ ${#INSTALL_DISTRO[@]} -eq $capacity ] && [ $capacity_length -ne 1 ]; then
        CAPACITYS=$CAPACITY
    fi
fi

###################################################################################
# Set parameters
###################################################################################
if [ x"$RC" = x"" ]; then
    BINDIR=${ESTUARY_WEB_ADDR}/releases/${VERSION}/linux
else
    BINDIR=${ESTUARY_WEB_ADDR}/pre-releases/${VERSION}/${RC}/linux
fi

###################################################################################
# check/get USB storage device
###################################################################################
if [ x"$TARGET" != x"" ]; then
    echo -e "\nCheck the target USB storage device. Please wait a moment."
    check_usb_device $TARGET || { echo "Error!!! Device $TARGET is not a USB device or not exist!"; exit 1;}
else
    echo -e "\nNotice. No USB storage device is specified.\nUse the first USB storage device by default."
    get_default_usb TARGET || { echo "Error!!! Can't find an available USB storage device!"; exit 1;}
fi

###################################################################################
# Display install info
###################################################################################
cat << EOF
------------------------------------------------------
- PLATFROM: $PLATFORM, VERSION: $VERSION, RC: $RC, DISTRO: ${INSTALL_DISTRO[@]}, TARGET: $TARGET
- BINDIR: $BINDIR/
------------------------------------------------------

EOF

sleep 1

###################################################################################
# Create and format usb storage
###################################################################################
cat << EOF
------------------------------------------------------
- Format and create usb storage partisions
------------------------------------------------------
EOF
echo -e "Notice! The device $TARGET will be formatted."
read -n1 -t 5 -p "Continue to do this? (y/N) " c
if [ x"$c" = x"N" ] || [ x"$c" = x"n" ];then
    echo "You need to format the USB to continue."
    exit 1
fi
if ! create_partition $TARGET $BOOT_PARTITION_SIZE $DISK_LABEL; then
    echo "Error!!! Create partition on $TARGET failed!"; exit 1
fi

###################################################################################
# create workspace and switch into workspace
###################################################################################
if [ -d $WORKSPACE ]; then
    WORKSPACE=`mktemp -d Workspace.XXXX`
fi

mkdir -p $WORKSPACE
WORKSPACE=`cd $WORKSPACE; pwd`
trap 'trap EXIT; clean_workspace; exit 1' INT EXIT

sudo mount ${TARGET}2 $WORKSPACE || exit 1
sudo chmod a+rw $WORKSPACE
pushd $WORKSPACE >/dev/null

DISTROS=$(echo ${INSTALL_DISTRO[*]} | tr ' ' ',')
CAPACITYS=$(echo ${CAPACITYS} | tr ' ' ',')
cat > estuary.txt << EOF
PLATFORM=$PLATFORM
DISTRO=${DISTROS}
CAPACITY=${CAPACITYS}
EOF

###################################################################################
# download all binary file from estuary
###################################################################################
cat << EOF
------------------------------------------------------
- Download binary files from server
------------------------------------------------------
EOF

if ! download_mini_rootfs ${BINDIR}/Minirootfs/Common; then
    echo "Error!!! Download mini rootfs failed!"; exit 1
fi

if ! download_common_binary ${BINDIR}/Common; then
    echo "Error!!! Download common binary failed!"; exit 1
fi

download_distros=$(echo ${INSTALL_DISTRO[*]})
if ! download_distro ${BINDIR} "$download_distros"; then
    echo "Error!!! Download distro failed!"; exit 1
fi

###################################################################################
# create grub.cfg
###################################################################################
create_grub_header grub.cfg
platform=(`echo $PLATFORM | tr ',' ' '`)
default_menuentry="`echo ${platform[0]} | tr "[:upper:]" "[:lower:]"`_menuentry_vga"
sed -i "s/\(set default=\)\(.*\)/\1${default_menuentry}/g" grub.cfg
for plat in ${platform[@]}; do
    eval vga_cmd_line=\$${plat}_VGA_CMDLINE
    eval console_cmd_line=\$${plat}_CMDLINE
    title="Install $plat estuary"
    menuentry_id="`echo $plat | tr "[:upper:]" "[:lower:]"`_menuentry"
    create_grub_menuentry grub.cfg "$title (VGA)" "${menuentry_id}_vga" /Image "$vga_cmd_line" /initrd.gz
    create_grub_menuentry grub.cfg "$title (Console)" "${menuentry_id}_console" /Image "$console_cmd_line" /initrd.gz
done

###################################################################################
# copy grub to efi partition
###################################################################################
sudo mount ${TARGET}1 /mnt || exit 1
sudo cp grub.cfg /mnt/
mkdir -p EFI/GRUB2/
cp grubaa64.efi EFI/GRUB2/grubaa64.efi || exit 1
sudo cp -r EFI /mnt/ || exit 1
sudo umount ${TARGET}1 || exit 1

###################################################################################
# create initrd.gz
###################################################################################
cat << EOF
------------------------------------------------------
- Generate initrd
------------------------------------------------------
EOF
user=`whoami`
group=`groups | awk '{print $1}'`
mkdir rootfs

pushd rootfs >/dev/null
if ! create_initrd ../mini-rootfs.cpio.gz ../deploy-utils.tar.bz2; then
    echo "Error!!! Create initrd.gz failed!"; exit 1
fi
popd >/dev/null
echo "Clear temporary files. Please wait!"
sudo rm -rf rootfs
rm -f mini-rootfs.cpio.gz deploy-utils.tar.bz2

###################################################################################
# switch out from workspace...
###################################################################################
popd >/dev/null
cat << EOF
------------------------------------------------------
- Umount usb install device
------------------------------------------------------
EOF

trap EXIT
echo "umount ${TARGET}2...... Please wait!"
(
trap 'echo ""; exit' SIGTERM EXIT
while :; do echo -n "."; sleep 3; done
) &
child_pid=$!
sudo umount ${TARGET}2 || exit 1
kill -s SIGTERM ${child_pid} 2>/dev/null
wait ${child_pid}

rmdir $WORKSPACE
exit 0

