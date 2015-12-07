#!/bin/bash

check_status() {
    ret=$?
    if [ "$ret" -ne "0" ]; then
        echo "Failed setup, aborting.."
        exit 1
    fi
}

# This function will return the code name of the Linux host release to the caller
get_host_type() {
    local  __host_type=$1
    local  the_host=`lsb_release -a 2>/dev/null | grep Codename: | awk {'print $2'}`
    eval $__host_type="'$the_host'"
}

# This function returns the version of the Linux host to the caller
get_host_version() {
    local  __host_ver=$1
    local  the_version=`lsb_release -a 2>/dev/null | grep Release: | awk {'print $2'}`
    eval $__host_ver="'$the_version'"
}

# This function returns the major version of the Linux host to the caller
# If the host is version 14.04 then this function will return 14
get_major_host_version() {
    local  __host_ver=$1
    get_host_version major_version
    eval $__host_ver="'${major_version%%.*}'"
}

# This function returns the minor version of the Linux host to the caller
# If the host is version 14.04 then this function will return 04
get_minor_host_version() {
    local  __host_ver=$1
    get_host_version minor_version
    eval $__host_ver="'${minor_version##*.}'"
}

#copy/paste programs
cp_progress () {
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

#Precentage function
untar_progress ()
{
    TARBALL=$1;
    DIRECTPATH=$2;
    BLOCKING_FACTOR=$(($(gzip --list ${TARBALL} | sed -n -e "s/.*[[:space:]]\+[0-9]\+[[:space:]]\+\([0-9]\+\)[[:space:]].*$/\1/p") / 51200 + 1));
    tar --blocking-factor=${BLOCKING_FACTOR} --checkpoint=1 --checkpoint-action='ttyout=Written %u%  \r' -zxf ${TARBALL} -C ${DIRECTPATH}
}

parse_config () {
    CFGFILE=$1
    build_PLATFORM=`jq -r ".system.platform" $CFGFILE`

    case $build_PLATFORM in
        "D02")
        TARGET_ARCH=ARM64
        ;;
        "D01")
        echo "This script can not used for deploying $build_PLATFORM board."
        exit 1
        ;;
        "QEMU")
        echo "This script can not used for deploying $build_PLATFORM platform."
        exit 1
        ;;
        "HiKey")
        echo "This script can not used for deploying $build_PLATFORM board."
        exit 1
        ;;
        *)
        ;;
    esac
}

cp_distros () {
    mkdir -p $1/sys_setup/boot/EFI/GRUB2 2> /dev/null
    mkdir -p $1/sys_setup/distro 2> /dev/null
    mkdir -p $1/sys_setup/bin 2> /dev/null
    cp -a $cwd/../build/$build_PLATFORM/binary/grubaa64* $1/sys_setup/boot/EFI/GRUB2
    cp -a $cwd/../build/$build_PLATFORM/binary/Image_$build_PLATFORM $1/sys_setup/boot/Image
    cp -a $cwd/../build/$build_PLATFORM/binary/hip05-d02.dtb $1/sys_setup/boot
    if [ "$ubuntu_en" == "yes" ]; then
        mkdir -p $1/sys_setup/distro/$build_PLATFORM/ubuntu$TARGET_ARCH 2> /dev/null
        TOTALSIZE=`sudo du -c ../build/$build_PLATFORM/distro/Ubuntu_"$TARGET_ARCH".tar.gz | grep total | awk {'print $1'}`
        cp -af $cwd/../build/$build_PLATFORM/distro/Ubuntu_"$TARGET_ARCH".tar.gz $1/sys_setup/distro/$build_PLATFORM/ubuntu$TARGET_ARCH &
        cp_progress $TOTALSIZE $1/sys_setup/distro/$build_PLATFORM/ubuntu$TARGET_ARCH
    fi
    if [ "$fedora_en" == "yes" ]; then
        pushd ..
        if [ -f $PWD/estuary/build.sh ]; then
            $PWD/estuary/build.sh -p $build_PLATFORM -d Fedora
        fi
        popd
        mkdir -p $1/sys_setup/distro/$build_PLATFORM/fedora$TARGET_ARCH 2> /dev/null
        cp -a $cwd/../build/$build_PLATFORM/distro/Fedora_"$TARGET_ARCH".tar.gz $1/sys_setup/distro/$build_PLATFORM/fedora$TARGET_ARCH
    fi
    if [ "$debian_en" == "yes" ]; then
        pushd ..
        if [ -f $PWD/estuary/build.sh ]; then
            $PWD/estuary/build.sh -p $build_PLATFORM -d Debian
        fi
        popd
        mkdir -p $1/sys_setup/distro/$build_PLATFORM/debian$TARGET_ARCH 2> /dev/null
        cp -a $cwd/../build/$build_PLATFORM/distro/Debian_"$TARGET_ARCH".tar.gz $1/sys_setup/distro/$build_PLATFORM/debian$TARGET_ARCH
    fi
    if [ "$opensuse_en" == "yes" ]; then
        pushd ..
        if [ -f $PWD/estuary/build.sh ]; then
            $PWD/estuary/build.sh -p $build_PLATFORM -d OpenSuse
        fi
        popd
        mkdir -p $1/sys_setup/distro/$build_PLATFORM/opensuse$TARGET_ARCH 2> /dev/null
        cp -a $cwd/../build/$build_PLATFORM/distro/OpenSuse_"$TARGET_ARCH".tar.gz $1/sys_setup/distro/$build_PLATFORM/opensuse$TARGET_ARCH
    fi
}

install_packages () {
    local packages_to_install_ref=$1
    local packages_to_install=${!packages_to_install_ref}
    local cmd="sudo apt-get install "
    # Check and only install the missing packages
    for i in $packages_to_install; do
        is_it_installed=`dpkg-query -l $i 2>/dev/null`
        if [ "$?" -ne "0" ]; then
            needs_installation=`echo $needs_installation`" "$i
            new_cmd=`echo $cmd`" "$i
            cmd=$new_cmd
        fi
    done

    if [ "$needs_installation" = "" ]; then
        echo "System has required packages!"
    else
        echo "System requires packages $needs_installation to be installed"

        echo "Installation requires you to have administrator priviliges (sudo access) "
        echo "on your host. Do you have administrator privilieges?"

        # Force the user to answer.  Maybe the user does not want to continue
        while true;
        do
            read -p "Type 'y' to continue or 'n' to exit the installation: " REPLY
            if [ "$REPLY" = 'y' -o "$REPLY" = 'n' ]; then
                break;
            fi
        done

        if [ "$REPLY" = 'n' ]; then
            echo "Installation is aborted by user"
            exit 1
        fi

        echo "Performing $cmd"
        $cmd
        check_status
    fi
}

wait_user_choose()
{
	exit_flag=0

	opt_list=$( echo "$2" | sed -e 's/[ \t\n]*|[ \t\n]*/ /g' )
	#read -a option <<< echo $opt_list
	assert_flag=""
	while [ $exit_flag != 1 ]; do
		echo "$1:($2)"
		select assert_flag in $opt_list; do
			[ -n "$assert_flag" ] && { exit_flag=1; break; }
		done
	done

	echo "The choice is $assert_flag"
}


para_sel()
{
	local arr_ref=${1}[@]
	#echo "local variable name is "$arr_ref $2

	local arr_val=( "${!arr_ref}" )
	echo "${!arr_ref}"
	echo "array is "${arr_val[@]}
	select out_var in "${arr_val[@]}"; do
		if [ -z "$out_var" ]; then
			echo "Invalid input. Please try again!"
		else
			eval $2="${out_var}"
			echo "you picked " $out_var  \($REPLY\)
			(( root_ind=$REPLY - 1 ))
			break
		fi
	done
}


umount_proc()
{
	cd ~

        case $1 in
        20)
        [ -n "$mnt_boot_pt" ] && { sudo umount $mnt_boot_pt; sudo rmdir $mnt_boot_pt; }
        ;&

        10)
        [ -n "$mount_pt" ] && { sudo umount $mount_pt; sudo rmdir $mount_pt; }
        ;&

        5)
        [ -n "$usr_mnt" ] && { sudo umount $usr_mnt; sudo rmdir $usr_mnt; }
        ;;

        esac
}


##move the non-empty elements to previous unset element, 
#keep the order of elements
#$1 is the array name; $2 is the first unset element index;
#$3 is the size of original $1

move_array_unset()
{
        local arr_ref=${1}[@]
        local arr_var=( "${!arr_ref}" )

        local idx="$2"
        local i=0
        local max_idx="$3"

        while [ $idx \< $max_idx ]; do
                [ -v ${arr_var[idx]} ] && { (( idx++ )); continue; }
                break
        done

        echo "the index are "$idx $i $max_idx
        echo "input array is ""${arr_var[@]}"

        echo "${arr_var[@]}"
        cmd_str="$1=( \"${arr_var[@]}\" )"
        #disk_list=( "${arr_var[@]}" )
}




move_array_unset_old()
{
	local arr_ref=${1}[@]
	local arr_var=( "${!arr_ref}" )

	local idx="$2"
	local i=0
	local max_idx="$3"

	#(( max_idx=${#arr_var[@]} + $counter ))
	while [ $idx \< $max_idx ]; do
		echo "$idx   ${arr_var[idx]}"
		[ -v ${arr_var[idx]} ] && { (( idx++ )); continue; }
		echo "nonset=$idx"
		break
	done

	echo "the index are "$idx $i $max_idx
	(( i=$idx + 1 ))
	echo "input array is ""${arr_var[@]}"
	while [ $i \< $max_idx -a $idx \< $max_idx ]; do
		#[ -n ${arr_var[i]} ] || { (( i++ )); echo "media=$i"; continue; }
		if [ -z ${arr_var[i]} ]; then
			echo "next nonset=$i"
			(( i++ ))
			continue
		fi
		arr_var[idx]=${arr_var[i]}
		unset arr_var[i]
		(( idx++ ))
		(( i++ ))
		echo "${arr_var[@]} idx=$idx i=$i"
	done
	#echo "${arr_var[@]}"
	cmd_str="$1=( \"${arr_var[@]}\" )"
	#disk_list=( "${arr_var[@]}" )
}

