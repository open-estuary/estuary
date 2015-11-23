#!/bin/bash

wyl_debug=y

CFGFILE=$cwd/estuarycfg.json

LANG=C

declare -a distros=("ubuntu" "opensuse" "linaro" "fedora" "debian")
readonly -a root_name

root_fs_tmp=""
#save the array index that correspnds to root filesystem type selected
root_ind=0


declare -a platforms=("D02" "D03")
readonly -a platforms

export BRD_TYPE=
export ROOT_FS=

usage()
{
	echo "usage:"
	echo -n "$0 [ -p "
	echo -n "${platforms[@]}" | sed 's/[ \t\n]\+/ | /g'
	echo -n " ] [ -d "
	echo -n "${distros[@]}" | sed 's/[ \t\n]\+/ | /g'
	echo " ] "

	echo -e "\n -h	print this message"
	echo " -p	hardware platform"
	echo " -d	OS distribuation"
	#echo "		*for D01, only support Ubuntu, OpenSuse, Fedora"
	#echo "		*for EVB, only support OpenEmbedded"
	#echo "		*for D02, support OpenEmbedded Ubuntu, OpenSuse, Fedora"
}

#some common functions
. functions.sh

#command options processing. We don't support long options now.
while getopts ":d:p:h" optname; do
	case "$optname" in
		"d")
			distr_input=$OPTARG
			;;

		"p")
			BRD_TYPE=$OPTARG
			;;

		"h")
			usage
			exit
			;;
		"?")
			echo "unknown option $OPTARG"
			exit
			;;
		":")
			echo "option $OPTARG should be with arguments"
			exit
			;;
		"*")
			echo "unknown error"
			exit
			;;
	esac
done



if [ -z "$BRD_TYPE" ]; then
	#para_sel  platforms BRD_TYPE
	#BRD_TYPE=$out_var  #another way to get function output
    echo ""
fi
#the default is D02
(( ${BRD_TYPE:=D02} ))
echo "BRD_TYPE  is "$BRD_TYPE

if [ -z "$ROOT_FS" ]; then
	#para_sel  distros  ROOT_FS
    echo ""
fi

#echo "${distros[@]}"
#make a choice what root fs is wanted to setup
#if [ -z "${distr_input}" ]; then
	#para_sel  distr_input distros sel_ind

	#we should choose a predefined rootfs at first
#	select distr_input in "${distros[@]}"; do
#		if [ -z "${distr_input}" ]; then
#			echo "Invalid input. Please try again!"
#		else
		#update the root_ind to save the array index
#			root_ind=$REPLY
#			echo "you picked " $distr_input \($REPLY\)
#			break
#		fi
#	done
#fi

(( ${ROOT_FS:=${distros[0]}} ))
echo "Type of root filesystem is " $ROOT_FS

#OK. Time to build the hard-disk system
#1) find the new plugged hard-disk
pushd . >/dev/null 2>&1
. find_disk.sh
popd >/dev/null 2>&1

#wyl debud
if [ x"n" = x"$wyl_debug" ]
then
echo "wyl-trace -> pwd = "$PWD
##differentiate the shell according to the root filesystem type
pushd .
. make_${ROOT_FS}.sh
[ $? ] || exit
popd

pushd .
. build_${BRD_TYPE}.sh
[ $? ] || exit
popd

###successful... here
fi
