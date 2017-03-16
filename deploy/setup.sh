#!/bin/bash
###################################################################################
# initialize
###################################################################################
trap 'exit 0' INT
set +m
echo 0 > /proc/sys/kernel/printk

D03_VGA_CMDLINE="console=tty0 pcie_aspm=off pci=pcie_bus_perf"
D03_CMDLINE="console=ttyS0,115200 pcie_aspm=off pci=pcie_bus_perf"
D05_VGA_CMDLINE="console=tty0 pcie_aspm=off pci=pcie_bus_perf"
D05_CMDLINE="pcie_aspm=off pci=pcie_bus_perf"

###################################################################################
# Global variable
###################################################################################
INSTALL_TYPE=""

PART_BASE_INDEX=2
BOOT_PARTITION_SIZE=200
DISK_LABEL=""
NFS_ROOT=""

INSTALL_DISK="/dev/sdx"
TARGET_DISK=
PART_PREFIX=
BOOT_DEV=

ESTUARY_CFG="/scratch/estuary.txt"

PLATFORM=
INSTALL_DISTRO=()
DISTRO_CAPACITY=()

###################################################################################
# Create mountpointer
###################################################################################
mkdir /boot 2>/dev/null
mkdir /mnt 2>/dev/null
mkdir /scratch 2>/dev/null

###################################################################################
# Find install disk and mount it to /scratch
###################################################################################
if cat /proc/cmdline | grep -Eo "nfsroot=[^ ]*"; then
    INSTALL_TYPE="NFS"
fi

if [ x"$INSTALL_TYPE" = x"NFS" ]; then
    nfs_root=`cat /proc/cmdline | grep -Eo "nfsroot=[^ ]*"`
    NFS_ROOT=`expr "X$nfs_root" : 'X[^=]*=\(.*\)'`
    echo "/*---------------------------------------------------------------"
    echo "- Mounting $NFS_ROOT as install source. Please wait for a moment!"
    echo "---------------------------------------------------------------*/"
    if ! mount -o nolock -t nfs $NFS_ROOT /scratch; then
        echo "Error!!! Mount $NFS_ROOT to /scratch failed!" >&2 ; exit 1
    fi
    echo "Mount $NFS_ROOT to /scratch done......"
    echo ""
else
    echo "/*---------------------------------------------------------------"
    echo "- Finding install USB/ISO disk labelled $DISK_LABEL. Please wait for a moment!"
    echo "---------------------------------------------------------------*/"
    echo ""
    disk_info=`blkid | grep LABEL=\"$DISK_LABEL\"`
    for ((index=0; index<45; index++)); do
        if [ x"$disk_info" != x"" ]; then
            echo "Found install disk labelled $DISK_LABEL."
            break
        fi
        printf "\rWait for install source disk $DISK_LABEL to be ready...... [ %2d ]" $index 
        sleep 3
        disk_info=`blkid | grep LABEL=\"$DISK_LABEL\"`
    done

    if [ x"$disk_info" = x"" ]; then
        echo "Error!!! Cann't find install disk labelled $DISK_LABEL!" >&2 ; exit 1
    fi

    INSTALL_DISK=`expr "${disk_info}" : '/dev/\([^:]*\):[^:]*'`
    echo "Mounting install disk /dev/${INSTALL_DISK} to /scratch."
    if ! mount /dev/${INSTALL_DISK} /scratch; then
        echo "Error!!! Mount install disk /dev/${INSTALL_DISK} to /scratch failed!" >&2
    fi
    echo "Mount install disk /dev/${INSTALL_DISK} to /scratch done."
fi

###################################################################################
# Get install platform parameters
###################################################################################
firmware_info=$(cat /sys/firmware/dmi/entries/0-0/raw 2>/dev/null)
if [ x"$(echo $firmware_info | grep -E "D03|Taishan 2180" 2>/dev/null)" != x"" ]; then
    PLATFORM="D03"
else
    if [ x"$(echo $firmware_info | grep -E "D05|Taishan 2280" 2>/dev/null)" != x"" ]; then
        PLATFORM="D05"
    fi
fi

if [ x"$PLATFORM" = x"" ]; then
    platform=`cat $ESTUARY_CFG | grep -Eo "PLATFORM=[^ ]*"`
    platform=(`expr "X$platform" : 'X[^=]*=\(.*\)' | tr ',' ' '`)
    PLATFORM=${platform[0]}

    if [ ${#platform[@]} -gt 1 ]; then
        echo "Notice! Multiple platforms found."
        echo ""
        echo "---------------------------------------------------------------"
        echo "- platfrom: ${PLATFORMS[*]}"
        echo "---------------------------------------------------------------"
        for (( index=0; index<${#platform[@]}; index++ )); do
            echo "$[index + 1]) ${platform[index]}"
        done
        read -n1 -t 5 -p "Please input the index of platfrom to install (default 1): " index
        echo ""

        if [ x"$index" = x"" ] || ! (expr 1 + $index > /dev/null 2>&1); then
            index=1
        fi
        PLATFORM=${platform[index-1]}
        PLATFORM=${PLATFORM:${platform[0]}}
    fi
fi

###################################################################################
# Get install distro parameters
###################################################################################
all_distro=`cat $ESTUARY_CFG | grep -Eo "DISTRO=[^ ]*"`
all_distro=($(expr "X$all_distro" : 'X[^=]*=\(.*\)' | tr ',' ' '))
all_capacity=`cat $ESTUARY_CFG | grep -Eo "CAPACITY=[^ ]*"`
all_capacity=($(expr "X$all_capacity" : 'X[^=]*=\(.*\)' | tr ',' ' '))

if [[ ${#all_distro[@]} == 0 ]]; then
    echo "Error!!! Distro is not specified" ; exit 1
fi

if [[ ${#all_capacity[@]} == 0 ]]; then
    echo "Error! Capacity is not specified!" ; exit 1
fi

if [[ ${#all_distro[@]} == 1 ]]; then
    INSTALL_DISTRO=(${all_distro[@]})
    DISTRO_CAPACITY=(${all_capacity[@]})
else
    echo "---------------------------------------------------------------"
    echo "- distro: ${all_distro[*]}"
    echo "---------------------------------------------------------------"
    total_distro=${#all_distro[@]}
    for ((index=0; index<total_distro; index++)); do
        read -n1 -p "Install ${all_distro[index]} (default N)? y/N " c
        if [ x"$c" = x"y" ] || [ x"$c" = x"Y" ]; then
            INSTALL_DISTRO[${#INSTALL_DISTRO[@]}]=${all_distro[index]}
            DISTRO_CAPACITY[${#DISTRO_CAPACITY[@]}]=${all_capacity[index]}
        fi

        echo ""
    done

    if [ ${#INSTALL_DISTRO[@]} -eq 0 ]; then
        echo "You have not selected any distro! Please select."
        for ((index=0; index<total_distro; index++)); do
            read -n1 -p "Install ${all_distro[index]} (default N)? y/N " c
            if [ x"$c" = x"y" ] || [ x"$c" = x"Y" ]; then
                INSTALL_DISTRO[${#INSTALL_DISTRO[@]}]=${all_distro[index]}
                DISTRO_CAPACITY[${#DISTRO_CAPACITY[@]}]=${all_capacity[index]}
            fi

            echo ""
        done

        if [ ${#INSTALL_DISTRO[@]} -eq 0 ]; then
            echo "You have not selected any distro again! Will reboot now."
            reboot
        fi
    fi
fi

###################################################################################
# Display install info
###################################################################################
echo "/*---------------------------------------------------------------"
echo "- platform: $PLATFORM, distro: ${INSTALL_DISTRO[@]}, capacity: ${DISTRO_CAPACITY[@]}, type: $INSTALL_TYPE"
echo "---------------------------------------------------------------*/"
echo "" ; sleep 1

###################################################################################
# Get all disk info (exclude the install disk)
###################################################################################
disk_list=()
disk_model_info=()
disk_size_info=()
disk_sector_info=()

echo "/*---------------------------------------------------------------"
echo "- Find target distk to install. Please wait for a moment!"
echo "---------------------------------------------------------------*/"
install_disk_dev=`echo "${INSTALL_DISK}" | sed 's/[0-9]*$//g'`
disk_list=(`lsblk -ln -o NAME,TYPE | grep '\<disk\>' | grep -v $install_disk_dev | awk '{print $1}'`)

if [[ ${#disk_list[@]} = 0 ]]; then
    echo "Error!!! Can't find disk to install distros!" >&2 ; exit 1
fi

for disk in ${disk_list[@]}; do
    disk_model_info[${#disk_model_info[@]}]=`parted -s /dev/$disk print 2>/dev/null | grep "Model: "`
    disk_size_info[${#disk_size_info[@]}]=`parted -s /dev/$disk print 2>/dev/null | grep "Disk /dev/$disk: "`
    disk_sector_info[${#disk_sector_info[@]}]=`parted -s /dev/$disk print 2>/dev/null | grep "Sector size (logical/physical): "`
done

###################################################################################
# Select disk to install
###################################################################################
index=0
disk_number=${#disk_list[@]}

for (( index=0; index<disk_number; index++)); do
    echo "Disk [$index] info: "
    echo ${disk_model_info[$index]}
    echo ${disk_size_info[$index]}
    echo ${disk_sector_info[$index]}
    echo ""
done

read -n1 -t 5 -p "Input disk index to install or q to quit (default 0): " index
echo ""
if [ x"$index" = x"q" ]; then
    exit 0
fi

if [ x"$index" = x"" ] || [[ $index != [0-9]* ]] \
    || [[ $index -ge $disk_number ]]; then
    echo ""
    echo "Warning! We'll use the first disk to install!"
    index=0
fi

TARGET_DISK="/dev/${disk_list[$index]}"

echo ""
sleep 1s

###################################################################################
# Format target disk
###################################################################################
echo ""
echo "/*---------------------------------------------------------------"
echo "- Format target disk $TARGET_DISK. Please wait for a moment!"
echo "---------------------------------------------------------------*/"
(yes | mkfs.ext4 $TARGET_DISK) >/dev/null 2>&1
echo "Format target disk $TARGET_DISK done."
echo ""

###################################################################################
# format gpt disk and create EFI System partition for kernel and grub
###################################################################################
echo "/*---------------------------------------------------------------"
echo "- Create and install kernel into boot partition on ${TARGET_DISK} part1. Please wait for a moment!"
echo "---------------------------------------------------------------*/"
(parted -s $TARGET_DISK mklabel gpt) >/dev/null 2>&1

# EFI System
echo "Creating and formatting ${TARGET_DISK}1."
efi_start_address=1
efi_end_address=$(( start_address + BOOT_PARTITION_SIZE))

BOOT_DEV=
(parted -s $TARGET_DISK "mkpart UEFI $efi_start_address $efi_end_address") >/dev/null 2>&1
(parted -s $TARGET_DISK set 1 boot on) >/dev/null 2>&1
first_part=`lsblk ${TARGET_DISK} -ln -o NAME,TYPE | grep -m 1 part | awk '{print $1}'`
PART_PREFIX=`echo "/dev/$first_part" | sed 's/[0-9]*$//g' | sed "s,^${TARGET_DISK},,g"`
BOOT_DEV="${TARGET_DISK}${PART_PREFIX}1"
(yes | mkfs.vfat $BOOT_DEV) >/dev/null 2>&1

echo "Create and format ${TARGET_DISK} part1 done."

###################################################################################
# Install kernel to boot partition
###################################################################################
echo "Installing kernel to ${TARGET_DISK}${PART_PREFIX}1."
pushd /scratch >/dev/null
mount $BOOT_DEV /boot/ >/dev/null 2>&1 || exit 1
cp Image* /boot/
popd >/dev/null
sync
umount /boot/
echo "Install kernel to ${TARGET_DISK}${PART_PREFIX}1 done!"
echo ""

###################################################################################
# Install all distros to target disk
###################################################################################
echo "/*---------------------------------------------------------------"
echo "- Install distros into ${TARGET_DISK}. Please wait for a moment!"
echo "---------------------------------------------------------------*/"
allocate_address=$((efi_end_address + 1))
start_address=
end_address=

pushd /scratch >/dev/null
index=0
distro_number=${#INSTALL_DISTRO[@]}

for ((index=0; index<distro_number; index++))
do
    # Get necessary info for current distro.
    part_index=$((PART_BASE_INDEX + index))
    distro_name=${INSTALL_DISTRO[$index]}
    rootfs_package="${distro_name}""_ARM64.tar.gz"
    distro_capacity=${DISTRO_CAPACITY[$index]%G*}

    start_address=$allocate_address
    end_address=$((start_address + distro_capacity * 1000))
    allocate_address=$end_address

    # Create and fromat partition for current distro.
    echo "Creating and formatting ${TARGET_DISK}${PART_PREFIX}${part_index} for $distro_name."
    (parted -s $TARGET_DISK "mkpart ROOT ext4 $start_address $end_address") >/dev/null 2>&1
    (echo -e "t\n$part_index\n13\nw\n" | fdisk $TARGET_DISK) >/dev/null 2>&1
    (yes | mkfs.ext4 ${TARGET_DISK}${PART_PREFIX}${part_index}) >/dev/null 2>&1
    echo "Create and format ${TARGET_DISK}${part_index} for $distro_name."

    echo "Installing $rootfs_package into ${TARGET_DISK}${PART_PREFIX}${part_index}. Please wait patiently!"
    # Mount root dev to mnt and uncompress rootfs to root dev
    if ! mount ${TARGET_DISK}${PART_PREFIX}${part_index} /mnt/ 2>/dev/null; then
        echo "Error!!! Unable mount ${TARGET_DISK}${part_index} to /mnt!" >&2 ; exit 1
    fi

    echo -e "\033[?25l"
    blocking_factor=$[$(gzip --list $rootfs_package | awk 'END {print $2}') / 51200 + 1]
    if ! tar --blocking-factor=${blocking_factor} --checkpoint=5 \
         --checkpoint-action='exec=printf "\rUncompressed [ %d%% ]..." $TAR_CHECKPOINT' \
         -zxf $rootfs_package -C /mnt/ 1>/dev/null 2>/tmp/${distro_name}_uncompress_log; then
        echo "Error!!! Uncompress $rootfs_package failed!" >&2 ; echo -e "\033[?25h"; exit 1
    fi
    echo -e "\033[?25h"
    echo "Install $rootfs_package into ${TARGET_DISK}${PART_PREFIX}${part_index} done."

    echo "Flush data to disk. Please wait a moment!"
    sync
    umount /mnt/

    echo ""
    sleep 1s
done

popd >/dev/null
echo "Install distros done!"
echo "" ; sleep 1s

###################################################################################
# Install grub to EFI partition
###################################################################################
echo "/*---------------------------------------------------------------"
echo "- Install grub to EFI partition. Please wait for a moment!"
echo "---------------------------------------------------------------*/"

mount $BOOT_DEV /boot/ >/dev/null || exit 1
# install grubaa64.efi
mkdir -p /boot/EFI/GRUB2 2>/dev/null
pushd /scratch >/dev/null
cp grubaa64.efi /boot/EFI/GRUB2 || exit 1
popd >/dev/null

# create grub.cfg header
cat > /boot/grub.cfg << EOF
# NOTE: Please remove the unused boot items according to your real condition.
# Sample GRUB configuration file
#

# Boot automatically after 3 secs.
set timeout=3

# By default, boot the Linux
set default=default_menuentry

EOF

# create grub entry for each distro
platform=$(echo $PLATFORM | tr "[:upper:]" "[:lower:]")
eval vga_cmd_line=\$${PLATFORM}_VGA_CMDLINE
eval console_cmd_line=\$${PLATFORM}_CMDLINE
boot_dev_info=`blkid -s UUID $BOOT_DEV 2>/dev/null | grep -o "UUID=.*" | sed 's/\"//g'`
boot_dev_uuid=`expr "${boot_dev_info}" : '[^=]*=\(.*\)'`

pushd /boot/ >/dev/null
Image="`ls Image*`"
popd >/dev/null

echo "Updating grub.cfg."
distro_number=${#INSTALL_DISTRO[@]}
for ((index=0; index<distro_number; index++)); do
    part_index=$((PART_BASE_INDEX + index))
    root_dev="${TARGET_DISK}${PART_PREFIX}${part_index}"
    root_dev_info=`blkid -s PARTUUID $root_dev 2>/dev/null | grep -o "PARTUUID=.*" | sed 's/\"//g'`
    root_partuuid=`expr "${root_dev_info}" : '[^=]*=\(.*\)'`

    linux_arg="/$Image root=$root_dev_info rootwait rw $console_cmd_line"
    linux_vga_arg="/$Image root=$root_dev_info rootwait rw $vga_cmd_line"
    distro_name=${INSTALL_DISTRO[$index]}

cat >> /boot/grub.cfg << EOF
# Booting from SATA/SAS with $distro_name rootfs (VGA)
menuentry "${PLATFORM} $distro_name (VGA)" --id ${platform}_${distro_name}_vga {
    set root=(hd0,gpt1)
    search --no-floppy --fs-uuid --set=root $boot_dev_uuid
    linux $linux_vga_arg
}

# Booting from SATA/SAS with $distro_name rootfs (Console)
menuentry "${PLATFORM} $distro_name (Console)" --id ${platform}_${distro_name}_console {
    set root=(hd0,gpt1)
    search --no-floppy --fs-uuid --set=root $boot_dev_uuid
    linux $linux_arg
}

EOF

done

# Set the first distro to default
default_menuentry_id="${platform}_""${INSTALL_DISTRO[0]}""_vga"
sed -i "s/\(set default=\)\(default_menuentry\)/\1$default_menuentry_id/g" /boot/grub.cfg

echo "Update grub.cfg done!"
echo ""

# Delete old Estuary bootorder
efi_bootorder=(`efibootmgr | grep -E "Boot[^ ]+\* Estuary" | awk '{print $1}'`)
for bootorder in ${efi_bootorder[*]}; do
        order=`expr "$bootorder" : 'Boot\([^ ]*\)\*'`
        efibootmgr -q -b $order -B 2>/dev/null
done

efibootmgr -c -q -d ${TARGET_DISK} -p 1 -L "Estuary" -l "\EFI\GRUB2\grubaa64.efi"

echo "Install grub and kernel to ${TARGET_DISK}${PART_PREFIX}1 done!"
echo ""

sync
umount $BOOT_DEV

###################################################################################
# Umount install disk
###################################################################################
echo "/*---------------------------------------------------------------"
echo "- Umount install disk. Please wait for a moment!"
echo "---------------------------------------------------------------*/"
cd ~
umount /scratch
echo ""

###################################################################################
# Restart the system
###################################################################################
echo "/*---------------------------------------------------------------"
echo "- All install finished!"
echo "---------------------------------------------------------------*/"
echo -e "\033[?25l"
echo "Press y to restart at now, other key to stop!"
(
trap 'exit' SIGTERM
for ((i=1; i<16; i++)); do
    left_time=$[16 - i]
    printf "                                          \r"
    printf "Restart in %2d second(s)! Reboot now? (y/N) " $left_time
    sleep 1
done

echo -e "\033[?25h"
reboot -f
) &
child_pid=$!
read -n1 c
kill -15 $child_pid 2>/dev/null
if [ x"$c" = x"y" ] || [ x"$c" = x"Y" ]; then
    echo -e "\033[?25h"
    reboot
fi

echo -e "\033[?25h"
