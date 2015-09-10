
wait_user_choose()
{
	exit_flag=0
	
	echo "wyl-trace -> wait_user_choose() -> assert_flag="$assert_flag

	opt_list=$( echo "$2" | sed -e 's/[ \t\n]*|[ \t\n]*/ /g' )
	#read -a option <<< echo $opt_list
	echo "wyl-trace -> $opt_list"
	assert_flag=""
	while [ $exit_flag != 1 ]; do
		echo "$1:($2)"
		select assert_flag in $opt_list; do
			[ -n "$assert_flag" ] && { exit_flag=1; break; }
		done
	done

	echo "wyl-trace -> wait_user_choose() -> assert_flag="$assert_flag

	echo "The choice is $assert_flag"
}


para_sel()
{
	local arr_ref=${1}[@]
	echo "wyl-trace -> "$arr_ref
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





