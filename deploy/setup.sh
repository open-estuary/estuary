#!/bin/bash
###################################################################################
# initialize
###################################################################################
trap 'exit 0' INT
echo 0 > /proc/sys/kernel/printk

D02_CMDLINE="rdinit=/init crashkernel=256M@32M console=ttyS0,115200 earlycon=uart8250,mmio32,0x80300000 pcie_aspm=off ip=dhcp"
D03_CMDLINE="rdinit=/init console=ttyS0,115200 earlycon=hisilpcuart,mmio,0xa01b0000,0,0x2f8 pcie_aspm=off ip=dhcp"
D05_CMDLINE="rdinit=/init console=ttyAMA0,115200 earlycon=pl011,mmio,0x602B0000 pcie_aspm=off crashkernel=256M@32M acpi=force ip=dhcp"
HiKey_CMDLINE="rdinit=/init console=tty0 console=ttyAMA3,115200 rootwait rw loglevel=8 efi=noruntime"

###################################################################################
# Global variable
###################################################################################
INSTALL_TYPE=""
ACPI="YES"
ACPI_ARG="acpi=force"

PART_BASE_INDEX=2
BOOT_PARTITION_SIZE=200
DISK_LABEL=""
NFS_ROOT=""

INSTALL_DISK="/dev/sdx"
TARGET_DISK=
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
# Get install parameters
###################################################################################
platform=`cat $ESTUARY_CFG | grep -Eo "PLATFORM=[^ ]*"`
platform=(`expr "X$platform" : 'X[^=]*=\(.*\)' | tr ',' ' '`)
PLATFORM=${platform[0]}

if [ ${#platform[@]} -gt 1 ]; then
	echo "Notice! Multiple platforms found."
	echo "---------------------------------------------------------------"
	echo "- platfrom: ${platform[*]}"
	echo "---------------------------------------------------------------"
	echo "Please select the platfrom to install."
	select plat in ${platform[*]}; do
		if [ x"$plat" != x"" ]; then
			PLATFORM=$plat; break
		fi
	done
fi

install_distro=`cat $ESTUARY_CFG | grep -Eo "DISTRO=[^ ]*"`
INSTALL_DISTRO=($(expr "X$install_distro" : 'X[^=]*=\(.*\)' | tr ',' ' '))
distro_capacity=`cat $ESTUARY_CFG | grep -Eo "CAPACITY=[^ ]*"`
DISTRO_CAPACITY=($(expr "X$distro_capacity" : 'X[^=]*=\(.*\)' | tr ',' ' '))

###################################################################################
# Install parameters check
###################################################################################
if [[ ${#INSTALL_DISTRO[@]} == 0 ]]; then
	echo "Error!!! Distro is not specified" ; exit 1
fi

if [[ ${#DISTRO_CAPACITY[@]} == 0 ]]; then
	echo "Error! Capacity is not specified!" ; exit 1
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

for disk in ${disk_list[@]}
do
	disk_model_info[${#disk_model_info[@]}]=`parted -s /dev/$disk print 2>/dev/null | grep "Model: "`
	disk_size_info[${#disk_size_info[@]}]=`parted -s /dev/$disk print 2>/dev/null | grep "Disk /dev/$disk: "`
	disk_sector_info[${#disk_sector_info[@]}]=`parted -s /dev/$disk print 2>/dev/null | grep "Sector size (logical/physical): "`
done

###################################################################################
# Select disk to install
###################################################################################
index=0
disk_number=${#disk_list[@]}
for (( index=0; index<disk_number; index++))
do
	echo "Disk [$index] info: "
	echo ${disk_model_info[$index]}
	echo ${disk_size_info[$index]}
	echo ${disk_sector_info[$index]}
	echo ""
done

read -p "Input disk index to install or q to quit (default 0): " index
if [ x"$index" = x"q" ]; then
	exit 0
fi

if [ x"$index" = x"" ] || [[ $index != [0-9]* ]] \
	|| [[ $index -ge $disk_number ]]; then
	echo "Warning! We'll use the first disk to install!"
	index=0
fi

TARGET_DISK="/dev/${disk_list[$index]}"

echo ""
sleep 1s

###################################################################################
# Select ACPI choice
###################################################################################
read -p "Use ACPI by force? y/n (y by default)" c
if [ x"$c" = x"n" ]; then
	ACPI="NO"
fi

###################################################################################
# Format target disk
###################################################################################
echo "/*---------------------------------------------------------------"
echo "- Format target disk $TARGET_DISK. Please wait for a moment!"
echo "---------------------------------------------------------------*/"
(yes | mkfs.ext4 $TARGET_DISK) >/dev/null 2>&1
echo "Format target disk $TARGET_DISK done."
echo ""

###################################################################################
# make gpt label and create EFI System partition
###################################################################################
echo "/*---------------------------------------------------------------"
echo "- Create and install kernel into EFI partition on ${TARGET_DISK}1. Please wait for a moment!"
echo "---------------------------------------------------------------*/"
(parted -s $TARGET_DISK mklabel gpt) >/dev/null 2>&1

# EFI System
echo "Creating and formatting ${TARGET_DISK}1."
efi_start_address=1
efi_end_address=$(( start_address + BOOT_PARTITION_SIZE))

BOOT_DEV=${TARGET_DISK}1
(parted -s $TARGET_DISK "mkpart UEFI $efi_start_address $efi_end_address") >/dev/null 2>&1
(parted -s $TARGET_DISK set 1 boot on) >/dev/null 2>&1
(yes | mkfs.vfat $BOOT_DEV) >/dev/null 2>&1
echo "Create and format ${TARGET_DISK}1 done."

###################################################################################
# Install grub and kernel to EFI System partition
###################################################################################
echo "Installing grub and kernel to ${TARGET_DISK}1."
pushd /scratch >/dev/null

mount $BOOT_DEV /boot/ >/dev/null 2>&1
cp Image* /boot/
mkdir -p /boot/EFI/GRUB2 2>/dev/null
cp grubaa64.efi /boot/EFI/GRUB2 || exit 1

# Delete old Estuary bootorder
efi_bootorder=(`efibootmgr | grep -E "Boot[^ ]+\* Estuary" | awk '{print $1}'`)
for bootorder in ${efi_bootorder[*]}; do
        order=`expr "$bootorder" : 'Boot\([^ ]*\)\*'`
        efibootmgr -q -b $order -B 2>/dev/null
done

efibootmgr -c -q -d ${TARGET_DISK} -p 1 -L "Estuary" -l "\EFI\GRUB2\grubaa64.efi"

cat > /boot/grub.cfg << EOF
# NOTE: Please remove the unused boot items according to your real condition.
# Sample GRUB configuration file
#

# Boot automatically after 3 secs.
set timeout=3

# By default, boot the Linux
set default=default_menuentry

EOF

popd >/dev/null
sync
umount /boot/
echo "Install grub and kernel to ${TARGET_DISK}1 done!"
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
	echo "Creating and formatting ${TARGET_DISK}${part_index} for $distro_name."
	(parted -s $TARGET_DISK "mkpart ROOT ext4 $start_address $end_address") >/dev/null 2>&1
	(echo -e "t\n$part_index\n13\nw\n" | fdisk $TARGET_DISK) >/dev/null 2>&1
	(yes | mkfs.ext4 ${TARGET_DISK}${part_index}) >/dev/null 2>&1
	echo "Create and format ${TARGET_DISK}${part_index} for $distro_name."
	
	echo "Installing $rootfs_package into ${TARGET_DISK}${part_index}. Please wait patiently!"
	# Mount root dev to mnt and uncompress rootfs to root dev
	if ! mount ${TARGET_DISK}${part_index} /mnt/ 2>/dev/null; then
		echo "Error!!! Unable mount ${TARGET_DISK}${part_index} to /mnt!" >&2 ; exit 1
	fi
	
	echo -e "\033[?25l"
	blocking_factor=$[$(gzip --list $rootfs_package | awk 'END {print $2}') / 51200 + 1]
	if ! tar --blocking-factor=${blocking_factor} --checkpoint=5 --checkpoint-action='exec=printf "\rUncompressed [ %d%% ]..." $TAR_CHECKPOINT' -zxf $rootfs_package -C /mnt/; then
		echo "Error!!! Uncompress $rootfs_package failed!" >&2 ; echo -e "\033[?25h"; exit 1
	fi
	echo -e "\033[?25h"
	echo "Install $rootfs_package into ${TARGET_DISK}${part_index} done."

	sync
	umount /mnt/

	echo ""
	sleep 1s
done

popd >/dev/null
echo "Install distros done!"
echo "" ; sleep 1s

###################################################################################
# Update grub configuration file
###################################################################################
echo "/*---------------------------------------------------------------"
echo "- Update grub configuration file. Please wait for a moment!"
echo "---------------------------------------------------------------*/"

platform=$(echo $PLATFORM | tr "[:upper:]" "[:lower:]")
eval cmd_line=\$${PLATFORM}_CMDLINE
if [ x"$ACPI" = x"YES" ]; then
	cmd_line="${cmd_line} ${ACPI_ARG}"
fi

boot_dev_info=`blkid -s UUID $BOOT_DEV 2>/dev/null | grep -o "UUID=.*" | sed 's/\"//g'`
boot_dev_uuid=`expr "${boot_dev_info}" : '[^=]*=\(.*\)'`

mount $BOOT_DEV /boot/ >/dev/null 2>&1

pushd /boot/ >/dev/null
Image="`ls Image*`"
popd >/dev/null

echo "Updating grub.cfg."
distro_number=${#INSTALL_DISTRO[@]}
for ((index=0; index<distro_number; index++)); do
	part_index=$((PART_BASE_INDEX + index))
	root_dev="${TARGET_DISK}${part_index}"
	root_dev_info=`blkid -s PARTUUID $root_dev 2>/dev/null | grep -o "PARTUUID=.*" | sed 's/\"//g'`
	root_partuuid=`expr "${root_dev_info}" : '[^=]*=\(.*\)'`

	linux_arg="/$Image root=$root_dev_info rootfstype=ext4 rw $cmd_line"
	distro_name=${INSTALL_DISTRO[$index]}
	
cat >> /boot/grub.cfg << EOF
# Booting from SATA with $distro_name rootfs
menuentry "${PLATFORM} $distro_name" --id ${platform}_${distro_name} {
    set root=(hd0,gpt1)
    search --no-floppy --fs-uuid --set=root $boot_dev_uuid
    linux $linux_arg
}

EOF

done

# Set the first distro to default
default_menuentry_id="${platform}_""${INSTALL_DISTRO[0]}"
sed -i "s/\(set default=\)\(default_menuentry\)/\1$default_menuentry_id/g" /boot/grub.cfg

echo "Update grub.cfg done!"
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
for ((i=1; i<16; i++)); do
	left_time=$[16 - i]
	printf "                                          \r"
	printf "Restart in %2d second(s)! Reboot now? (y/N) " $left_time
	sleep 1
done

reboot
) &
child_pid=$!
read -n1 c
kill -s 9 $child_pid 2>/dev/null
if [ x"$c" = x"y" ] || [ x"$c" = x"Y" ]; then
	reboot
fi

echo -e "\033[?25h"
