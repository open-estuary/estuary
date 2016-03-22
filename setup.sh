#!/bin/bash

###################################################################################
# Global variable
###################################################################################
PART_BASE_INDEX=2
BOOT_PARTITION_SIZE=200
DISK_LABEL=""

INSTALL_DISK=
TARGET_DISK=
BOOT_DEV=

INSTALL_CFG="`dirname $0`/estuarycfg.json"
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
disk_info=`blkid | grep LABEL=\"$DISK_LABEL\"`
for ((index=0; index<10; index++))
do
	if [ x"$disk_info" != x"" ]; then
		break
	fi
	sleep 1
	disk_info=`blkid | grep LABEL=\"$DISK_LABEL\"`
done

if [ x"$disk_info" = x"" ]; then
	echo "Cann't find install disk!"
	exit 1
fi

INSTALL_DISK=`expr "${disk_info}" : '/dev/\([^:]*\):[^:]*'`

mount /dev/${INSTALL_DISK} /scratch

###################################################################################
# Get all disk info (exclude the install disk)
###################################################################################
clear

disk_list=()
disk_model_info=()
disk_size_info=()
disk_sector_info=()

install_disk_dev=`echo "${INSTALL_DISK}" | sed 's/[0-9]*$//g'`
read -a disk_list <<< $(lsblk -ln -o NAME,TYPE | grep '\<disk\>' | grep -v $install_disk_dev | awk '{print $1}')

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
	index=0
fi

TARGET_DISK="/dev/${disk_list[$index]}"

echo ""
sleep 1s

###################################################################################
# Get all distro info
###################################################################################
distro=
capacity=

index=0
install=`jq -r ".distros[$index].install" $INSTALL_CFG 2>/dev/null`
while [ x"$?" = x"0" ] && [ x"$install" != x"null" ] && [ x"$install" != x"" ];
do
	if [ x"yes" = x"$install" ]; then
		idx=${#INSTALL_DISTRO[@]}
		distro=`jq -r ".distros[$index].name" $INSTALL_CFG`
		capacity=`jq -r ".distros[$idx].capacity" $INSTALL_CFG`
		printf "%d) %s, %s\n" $idx $distro $capacity
		INSTALL_DISTRO[$idx]="$distro"
		DISTRO_CAPACITY[$idx]="$capacity"
		
	fi
	(( index=index+1 ))
	install=`jq -r ".distros[$index].install" $INSTALL_CFG`
done

if [[ ${#INSTALL_DISTRO[@]} == 0 ]]; then
	echo "There's no distro to install!"
	exit 1
fi

echo ""
sleep 1s

###################################################################################
# Delete all partitions on target disk
###################################################################################
echo "Delete all partitions on $TARGET_DISK ......"
(yes | mkfs.ext4 $TARGET_DISK) >/dev/null 2>&1
echo "Delete all partitions on $TARGET_DISK done!"

###################################################################################
# make gpt label and create EFI System partition
###################################################################################
echo "Create EFI System partition on $TARGET_DISK ......"
(parted -s $TARGET_DISK mklabel gpt) >/dev/null 2>&1

# EFI System
efi_start_address=1
efi_end_address=$(( start_address + BOOT_PARTITION_SIZE))

BOOT_DEV=${TARGET_DISK}1
(parted -s $TARGET_DISK "mkpart UEFI $efi_start_address $efi_end_address") >/dev/null 2>&1
(parted -s $TARGET_DISK set 1 boot on) >/dev/null 2>&1
(yes | mkfs.vfat $BOOT_DEV) >/dev/null 2>&1
echo "Create EFI System partition on $TARGET_DISK done!"

###################################################################################
# Install grub and kernel to EFI System partition
###################################################################################
echo "Install grub and kernel to $BOOT_DEV ......"
pushd /scratch

mount $BOOT_DEV /boot/ >/dev/null 2>&1
mkdir -p /boot/EFI/BOOT/
cp grub*.efi /boot/EFI/BOOT/BOOTAA64.EFI
cp Image* /boot/
cp hip*.dtb /boot/

cat > /boot/grub.cfg << EOF
# NOTE: Please remove the unused boot items according to your real condition.
# Sample GRUB configuration file
#

# Boot automatically after 5 secs.
set timeout=3

# By default, boot the Euler/Linux
set default=default_menuentry

EOF

popd
sync
umount /boot/
echo "Install grub and kernel to $BOOT_DEV done!"

###################################################################################
# Install all distributions to target disk
###################################################################################
echo "Install distributions to $TARGET_DISK ......"
allocate_address=$((efi_end_address + 1))
start_address=
end_address=

pushd /scratch
index=0
distro_number=${#INSTALL_DISTRO[@]}

for ((index=0; index<distro_number; index++))
do
	# Get necessary info for current distribution.
	part_index=$((PART_BASE_INDEX + index))
	distro_name=${INSTALL_DISTRO[$index]}
	rootfs_package="${distro_name}""_ARM64.tar.gz"
	distro_capacity=${DISTRO_CAPACITY[$index]%G*}
	
	start_address=$allocate_address
	end_address=$((start_address + distro_capacity * 1000))
	allocate_address=$((end_address + 1))
	
	# Create and fromat partition for current distribution.
	echo "Create ${TARGET_DISK}${part_index} for $distro_name ......"
	(parted -s $TARGET_DISK "mkpart ROOT ext4 $start_address $end_address") >/dev/null 2>&1
	(echo -e "t\n$part_index\n13\nw\n" | fdisk $TARGET_DISK) >/dev/null 2>&1
	(yes | mkfs.ext4 ${TARGET_DISK}${part_index}) >/dev/null 2>&1
	echo "Create done!"
	
	# Mount root dev to mnt and uncompress rootfs to root dev
	mount ${TARGET_DISK}${part_index} /mnt/ 2>/dev/null
	echo "Uncompress $rootfs_package to ${TARGET_DISK}${part_index} ......"
	tar xvf $rootfs_package -C /mnt/ 2>/dev/null
	echo "Uncompress $rootfs_package to ${TARGET_DISK}${part_index} done!"

	sync
	umount /mnt/

	echo ""
	sleep 1s
done

popd
echo ""
sleep 1s

###################################################################################
# Update grub configuration file
###################################################################################
echo "Update grub configuration file ......"
PLATFORM=`jq -r ".system.platform" $INSTALL_CFG`
platform=$(echo $PLATFORM | tr "[:upper:]" "[:lower:]")

if [ x"D02" = x"$PLATFORM" ]; then
	cmd_line="rdinit=/init crashkernel=256M@32M console=ttyS0,115200 earlycon=uart8250,mmio32,0x80300000 ip=dhcp"
else
	cmd_line="rdinit=/init console=ttyS1,115200 earlycon=hisilpcuart,mmio,0xa01b0000,0,0x2f8"
fi

boot_dev_info=`blkid -s UUID $BOOT_DEV 2>/dev/null | grep -o "UUID=.*" | sed 's/\"//g'`
boot_dev_uuid=`expr "${boot_dev_info}" : '[^=]*=\(.*\)'`

mount $BOOT_DEV /boot/ >/dev/null 2>&1

pushd /boot/
Image="`ls Image*`"
Dtb="`ls hip*.dtb`"
popd

distro_number=${#INSTALL_DISTRO[@]}
for ((index=0; index<distro_number; index++))
do
	part_index=$((PART_BASE_INDEX + index))
	root_dev="${TARGET_DISK}${part_index}"
	root_dev_info=`blkid -s PARTUUID $root_dev 2>/dev/null | grep -o "PARTUUID=.*" | sed 's/\"//g'`
	root_partuuid=`expr "${root_dev_info}" : '[^=]*=\(.*\)'`

	linux_arg="/$Image root=$root_dev_info rootfstype=ext4 rw $cmd_line"
	device_tree_arg="/$Dtb"

	distro_name=${INSTALL_DISTRO[$index]}
	

cat >> /boot/grub.cfg << EOF
# Booting from SATA with $distro_name rootfs
menuentry "${PLATFORM} $distro_name SATA" --id ${platform}_${distro_name}_sata {
    set root=(hd0,gpt1)
    search --no-floppy --fs-uuid --set=root $boot_dev_uuid
    linux $linux_arg
    devicetree $device_tree_arg
}

EOF

done

# Set the first distribution to default
default_menuentry_id="${platform}_""${INSTALL_DISTRO[0]}""_sata"
sed -i "s/\(set default=\)\(default_menuentry\)/\1$default_menuentry_id/g" /boot/grub.cfg

echo "Update grub configuration file done!"

sync
umount $BOOT_DEV

###################################################################################
# Umount install disk
###################################################################################
cd ~
umount /scratch

