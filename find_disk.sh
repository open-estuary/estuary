#/bin/bash

#set -x


declare -a disk_list
export disk_list=

if [ ! -o pipefail ]; then
	set -o pipefail
	is_disable=1
fi

#readarray will add newline in array elements
read -a disk_list <<< $(lsblk | grep '\<disk\>' | awk '{print $1}')
if [ $? ]; then
	echo "OK. existing hard-disks are " ${disk_list[@]}
	if [ ${#disk_list[@]} -eq 0 ]; then
		echo "No any SATA hard disk. Please connect a new one"
		exit
	fi
else
	echo "Get hard-disk information fail"
	exit
fi

echo "length of array " ${#disk_list[@]}

if [ $is_disable -eq 1 ]; then
	set +o pipefail
fi

#TMP_RANFILE=$(mktemp)

#The root device should be defined in /proc/cmdline, we process it
#1) obtain the root device id
#2) check whether the hard-disk is where the root filesystem resides

for x in $(cat /proc/cmdline); do
	case $x in
		root=*)
			root_para=${x#root=}
			echo "root_para "${root_para}
			case $root_para in
			LABEL=*)
				root_id=${root_para#LABEL=}
				#case $root_id in
				#*/*)
				#if sed > /dev/null 2>&1;then
				#	root_id="$(echo ${root_id} | sed 's,/,\\x2f,g')"
				#fi
				#;;
				#*)
				#echo "invalid label " ${root_id}
				#;;
				#esac
				root_id="/dev/disk/by-label/${root_id}"
				;;
			PARTUUID=*)
				root_id="/dev/disk/by-partuuid/${root_para#PARTUUID=}"
				root_dev=$(ls -l /dev/disk/by-partuuid | grep ${root_para#PARTUUID=} | awk '{ print $NF }')
				root_dev=${root_dev#../../}
				;;
			/dev/*)
				echo "legacy root device " ${root_para}
				root_id=${root_para#/dev/}
				root_dev=${root_id}
				;;
			*)
				echo "invalid root device " ${root_para}
				;;
			esac
			;;
		#we only care about the root=, skip all others
		esac
done
echo "final root device " ${root_id} ${root_dev}


##filter out the current root disk..
CUR_RTDEV=""
if [ "$root_dev" != "nfs" ]; then
	CUR_RTDEV=$( echo ${root_dev} | sed 's,[0-9]\+,,g')
	echo "root disk in using is "$CUR_RTDEV

	#org_size=${#disk_list[@]}
	elem_idx=0
	for now_disk in "${disk_list[@]}"; do
		echo "disk_list is $elem_idx ${disk_list[elem_idx]}--"
		if (echo ${root_dev} | grep "$now_disk"); then
			echo "try to skip " $now_disk
			unset disk_list[elem_idx]
			#(( ${first_unset:=$elem_idx} ))
			#echo "first unset index is "$first_unset
		else
			if [ $? -gt 1 ]; then
				echo "unknow Error occurred!"
				exit
			fi
		fi
		(( elem_idx++ ))
	done

	#remove the invalid array elements
	#move_array_unset disk_list 0 "$org_size"
	for (( idx=0; idx \< elem_idx; (( idx++ )) )); do
		if [ -z "${disk_list[idx]}" ]; then
			if [ -n "${disk_list[(( --elem_idx ))]}" ]; then
			disk_list[idx]=${disk_list[elem_idx]}
			unset disk_list[elem_idx]
		fi
	fi
	done
else
	[ ${#disk_list[@]} == 0 ] && ( echo "NFS + no_any_disk!"; exit )

fi
export CUR_RTDEV


echo "After filter..length of array ${#disk_list[@]} ${disk_list[0]}--"

#The length of disk_list[] must -gt 0
if [ ${#disk_list[@]} -le 0 ]; then
	echo "No idle SATA hard disk. It is better to plug new one(input 'n')"
	disk_list[0]=$(echo ${root_dev} | sed 's,[0-9]\+,,g')
	echo "Or update " ${disk_list[0]} "have risk to demage whole disk!!"
	read -t 20 -p "Please assert[y/n]:" assert_flag
	if [ ! $assert_flag == "y" ]; then
		exit
	fi
else
	##when there are multiply disks,maybe it is better user decide which to be selected
	#But how the user know which one is new plugged??
	if [ ${#disk_list[@]} \> 1 ]; then
		select newroot_disk in "${disk_list[@]}"; do
			if [ -n "$newroot_disk" ]; then
				disk_list[$REPLY]=${disk_list[0]}
				disk_list[0]=$newroot_disk
				break
			else
				echo "Please try again"
			fi
		done
	fi
fi

echo "will partition disk " ${disk_list[0]}"--"



#ok. The available hard-disks are here now. Just pick one with enough space
#1) check whether parted had been installed
if ! command -v ping -c 2 ports.ubuntu.com > /dev/null 2>&1; then
	echo "network seems not to be available. Please check it first"
	exit
fi

if ! command -v parted -v > /dev/null 2>&1; then
	apt-get install parted || ( echo "parted installation FAIL!"; exit )
fi

#2) find a partition to save the packages fetched
declare -a part_list
declare -a part_name
part_list_idx=0
#disk_list[0]=$(echo ${disk_list[0]} | sed 's/*[ \t\n]//')
declare -a nonboot_part

if [ -z "$CUR_RTDEV" ]; then
	read -a nonboot_part <<< $(sudo parted /dev/${disk_list[0]} print |\
		awk '$1 ~ /[0-9]+/ {print $1}' | sort)
else
	#for non-nfs, only one root-disk, or not less than two disks. For one root-disk, if we choose it, then 
	#disk_list[0] is it; for multiple disks, the root-disk will not be in disk_list[].
	read -a nonboot_part <<< $(sudo parted /dev/${disk_list[0]} print |\
		awk '$1 ~ /[0-9]+/ && ! /boot/ {print $1}' | sort)
fi


for part_idx in ${nonboot_part[*]}; do
	echo "current partition index "${part_idx}
	#will exclude the current root and all mounted partitions of first disk
	if [ ${disk_list[0]} != ${root_dev%${part_idx}} ]; then
		tmp_part="/dev/${disk_list[0]}${part_idx}"
		echo "tmporary partition is "$tmp_part
		if ( mount | grep "$tmp_part" ); then
		#match_str=`(sudo df -ihT | awk '{ if ($1 == tmp_pt) print $NF }' tmp_pt=${tmp_part})`
		#echo "match_str "$match_str"--"
		#if [ "$match_str" ]; then
			echo "partition "$tmp_part " should be kept"
		else
			echo "partition "$tmp_part " can be removed"
			part_list[part_list_idx]=$part_idx
			part_name[part_list_idx]=$tmp_part
			(( part_list_idx++ ))
		fi
	fi
done
unset part_idx

part_name[(( part_list_idx++ ))]="all"
part_name[part_list_idx]="exit"


assert_flag=""
while [ "$assert_flag" != "y" ]; do
##Begin to remove the idle partitions
sudo parted "/dev/"${disk_list[0]} print
echo "Please choose the partition to be removed:"
select part_tormv in "${part_name[@]}"; do
	echo "select input "$part_tormv
	if [ "$part_tormv" == "all" ]; then
		echo "all the partitions listed above will be deleted"
	elif [ "$part_tormv" == "exit" ]; then
		echo "keep all current partitions"
		assert_flag="y"
	elif [ -n "$part_tormv" ]; then
		echo $part_tormv" will be deleted"
	else
		echo "invalid choice! Please try again"
		continue
	fi
	sel_idx=`expr $REPLY - 1`
	break
done

echo "sel_idx "$sel_idx "part_list count:"${#part_list[@]} "part_list[0] :"${part_list[0]}
ind=0
if [ $sel_idx != $(( ${#part_list[@]} + 1 )) ]; then
if [ $sel_idx == ${#part_list[@]} ]; then
	while [ -v part_list[ind] ]; do
		cmd_str="sudo parted "/dev/"${disk_list[0]} rm ${part_list[ind]}"
		echo "delete $ind "$cmd_str
		eval $cmd_str
		(( ind++ ))
	done
	assert_flag="y"
else
	cmd_str="sudo parted "/dev/"${disk_list[0]} rm ${part_list[sel_idx]}"

	echo "delete one partition:  "$cmd_str
	eval $cmd_str

	org_size=${#part_name[@]}
	unset part_name[sel_idx]
	move_array_unset  part_name $sel_idx $org_size
	#idx=$sel_idx
	#(( i=$idx + 1 ))
	#while [ $i \< $org_size -a $idx \< $org_size ]; do
		#[ -z "${part_name[i]}" ] && { (( i++ )); continue; }
		#part_name[idx]=${part_name[i]}
		#unset part_name[i]
		#(( idx++ ))
		#(( i++ ))
	#done
	echo  "new partition is ""${part_name[@]}"

	org_size=${#part_list[@]}
	unset part_list[sel_idx]
	move_array_unset  part_list $sel_idx $org_size
	echo "new partition id are ${part_list[@]}"
	#idx=$sel_idx
	#(( i=$idx + 1 ))
	#while [ $i \< $org_size -a $idx \< $org_size ]; do
		#[ -z "${part_list[i]}" ] && { (( i++ )); continue; }
		#part_list[idx]=${part_list[i]}
		#unset part_list[i]
		#(( idx++ ))
		#(( i++ ))
	#done

fi
fi
done



#NEWFS_DEV=${disk_list[0]}

## the later two entry is not used again unset them
(( i=${#part_name[@]} - 1 ))
unset part_name[i]
(( i-- ))
unset part_name[i]


#make another partition as the place where the new root filesystem locates
#1) ensure that the disk partition table is gpt
if [ "$(sudo parted /dev/${disk_list[0]} print | \
	awk '/Partition / && /Table:/ {print $NF}')" != "gpt" ]; then
	echo "All current partitions will be deleted"
	if ! ( sudo parted /dev/${disk_list[0]} mklabel gpt ); then
		echo "configure ${disk_list[0]} label as gpt FAIL"
		exit
	fi
fi
#2) check whether the boot partition exist
boot_id=$(sudo parted /dev/${disk_list[0]} print | awk '$1 ~ /[0-9]+/ && /boot/ {print $1}')
###in D02, if [ -n "$boot_id" -a $boot_id -ne 1 ]; then always warning "too many parameters"
[[ -n "$boot_id" && $boot_id -ne 1 ]] && \
	{ echo "boot partition is not first one. will delete it at first"
	if ! ( sudo parted /dev/${disk_list[0]} rm $boot_id ); then
		echo "ERR:delete /dev/${disk_list[0]}$boot_id FAIL"
		exit
	fi
	}

#recheck does boot exist...
boot_id=$(sudo parted /dev/${disk_list[0]} print | awk '$1 ~ /[0-9]+/ && /boot/ {print $1}')
if [ -z "$boot_id" ]; then
	echo -n "make boot partition"
	##[ ! (sudo parted /dev/${disk_list[0]} mkpart uefi 1 256) ] && ( echo "ERR"; exit ) always said too many parameters
	if ! ( sudo parted /dev/${disk_list[0]} mkpart uefi 1 256;set 1 boot on ); then
		echo " ERR"
		exit
	else
		echo " OK"
		##since UEFI currently only support fat16, we need mkfs.vfat
		sudo apt-get install dosfstools -y
		mkfs -t vfat /dev/${disk_list[0]}1
		#parted /dev/${disk_list[0]} mkfs 1 fat16
		[ $? ] || { echo "ERR::mkfs for boot partition FAIL"; exit; }
		#sudo parted /dev/${disk_list[0]} set 1 boot on
	fi
else
	echo "existed boot partition will be updated"
fi


sel_name=""
#3)  make the new root partition
#ROOT_FS="ubuntu"
#get the current partition number list before new creation. 
#actually, $ROOT_FS is not necessary. we can find the new created partition still.
read -a old_idx <<< $(sudo parted /dev/${disk_list[0]} print | grep "$ROOT_FS" | awk '{print $1}' | sort)
echo "previous idx list is \"${old_idx[*]}\"${old_idx[*]}"
sudo parted /dev/${disk_list[0]} print free

assert_flag="w"
#while [ "$assert_flag" != "y" -a "$assert_flag" != "n" ]; do
#	read -p "Do you want to create a new root partition?(y | n):" assert_flag
#done
wait_user_choose "Create a new root partition?" "y|n"


if [ "$assert_flag" == "y" ]; then
	echo "Please carefully configure the start and end of root partition"
	cmd_str="sudo parted /dev/${disk_list[0]} mkpart $ROOT_FS 512M 10G"
	echo -n "make root partition by "$cmd_str
	eval $cmd_str
	[ $? ] || { echo " ERR"; exit; }

	echo " OK"
	#get the device id that match with the partition just made
	read -a cur_idx <<< $(sudo parted /dev/${disk_list[0]} print | \
	grep "$ROOT_FS" | awk '{print $1}' | sort)
	echo "root cur_idx is ${cur_idx[*]}"
	for (( ind=0; ( $ind \< ${#old_idx[*]} ); (( ind++ )) )); do
		[ ${cur_idx[ind]} == ${old_idx[ind]} ] || break
	done
	NEWRT_IDX=${cur_idx[ind]}

	#we always re-format the root partition
	mkfs -t ext3 /dev/${disk_list[0]}$NEWRT_IDX
else
	para_sel part_name sel_name
        #we always re-format the root partition
        mkfs -t ext3 $sel_name
	NEWRT_IDX=${sel_name##/dev/${disk_list[0]}}
fi
echo "newrt_idx is "$NEWRT_IDX


#we can make this as function later
read -a cur_idx <<< $(sudo parted /dev/${disk_list[0]} print | \
	grep "user" | awk '{print $1}' | sort)
echo "user cur_idx is ${cur_idx[*]} ${#cur_idx[@]}"
#we try our best to use less user partitions
assert_flag="hw"
wait_user_choose "Create new user partition?" "y|n"
if [ ${#cur_idx[@]} == 0 ]; then
	echo "No any user partitions. Will jump to create new one!"
	assert_flag="y"
fi

if [ "$assert_flag" == "y" ]; then
        #USRDEV_IDX=${cur_idx[0]}
        sudo parted /dev/${disk_list[0]} print free
        cmd_str="sudo parted /dev/${disk_list[0]} mkpart user 10G 20G"
        echo -n "make user partition by "$cmd_str
        eval $cmd_str
        [ $? ] || { echo " ERRR"; exit; }
        echo " OK"
        #only one user partition
        read -a cur_idx <<< $(sudo parted /dev/${disk_list[0]} print | \
                grep "user" | awk '{print $1}')
        USRDEV=${disk_list[0]}${cur_idx[0]}
        mkfs -t ext3 /dev/$USRDEV
        echo "user partition is $USRDEV"
    else
	sel_name=""
	echo "There are user partitions now."
       	for (( i=0; i < ${#cur_idx[@]}; (( i++ )) )); do
               	cur_idx[i]="/dev/${disk_list[0]}${cur_idx[i]}"
        done

        sudo parted /dev/${disk_list[0]} pr
        echo "Must select one idle partition as cache:"
	para_sel  cur_idx  sel_name
	##unset the reused partition
	for (( i=0; i < ${#part_name[@]}; (( i++ )) )); do
		[ "${part_name[i]}" != $sel_name ] && continue
		unset part_name[i]
		break		
	done
	move_array_unset part_name $i ${#part_name[@]}

        USRDEV=${sel_name##/dev/}
        echo "user partition is $USRDEV"
        wait_user_choose "Is the user partition re-formatted?" "y|n"
        [ "$assert_flag" != "y" ] || mkfs -t ext3 /dev/$USRDEV
fi

USRDEV_IDX=${USRDEV##${disk_list[0]}}
echo "USRDEV_IDX is $USRDEV_IDX"

assert_flag=""
read -p "Do you need to create one swap partition?(y/n)" assert_flag
if [ "$assert_flag" == "y" ]; then
	sudo parted /dev/${disk_list[0]} print free
	sudo parted /dev/${disk_list[0]} mkpart swap linux-swap 20G 30G

	[ $? ] || { echo "WARNING:: create swap partition FAIL"; }
fi


#fi

#read -p "Please input the partition size(G or M):" root_size
#while [ -z "$(echo $root_size | awk '/^[0-9]+[GM]$/ {print}')" -o "${root_size:0: -1}" == "0" ]; do
#	echo "Invalid input"
#	read -p "Please input the partition size(G or M):" root_size
#done
#echo "partition size is "$root_size

NEWFS_DEV=${disk_list[0]}
export NEWRT_IDX
export NEWFS_DEV


sudo mkdir $PWD/boot
sudo mkdir $PWD/rootfs
sudo mkdir $PWD/tmp
sudo mount -t vfat /dev/${disk_list[0]}1 boot
sudo mount -t ext3 /dev/${disk_list[0]}2 rootfs

sudo rm -rf boot/*
sudo rm -rf rootfs/*

sudo cp -a /sys_setup/boot/* boot/
sudo dd if=/sys_setup/distro/ubuntu-vivid.img of=/dev/${disk_list[0]}2

sudo umount boot rootfs
sudo rm -rf boot rootfs tmp 


##OK. Partitions are ready in Hard_disk. Can start the boot, root file-system making
