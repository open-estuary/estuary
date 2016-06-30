#!/bin/bash

###################################################################################
# get_compress_file_prefix <src_file>
###################################################################################
get_compress_file_prefix()
{
	(
	src_file=`basename $1`
	postfix=$(echo $src_file | grep -Po "((\.tar)*\.(tar|bz2|gz|xz)$)" 2>/dev/null)
	prefix=${src_file%$postfix}
	echo $prefix
	)
}

###################################################################################
# get_compress_file_postfix <src_file>
###################################################################################
get_compress_file_postfix()
{
	(
	src_file=`basename $1`
	postfix=$(echo $src_file | grep -Po "((\.tar)*\.(tar|bz2|gz|xz)$)" 2>/dev/null)
	echo $postfix
	)
}

###################################################################################
# uncompress_file <src_file> <target_dir>
###################################################################################
uncompress_file()
{
	(
	src_file=$1
	target_dir=$2
	if [ x"$target_dir" = x"" ]; then
		target_dir="./"
	fi

	postfix=`get_compress_file_postfix $src_file`
	case $postfix in
		.tar.bz2 | .tar.gz | .tar.xz | .xz | .tbz)
			if ! tar xvf $src_file -C $target_dir >/dev/null 2>&1; then
				return 1
			fi
			;;
		.gz)
			if ! gunzip $src_file -C $target_dir >/dev/null 2>&1; then
				return 1
			fi
			;;
		*)
			echo -e "\033[31mCan not find the suitable root filesystem!\033[0m" ; return 1
			;;
	esac
	
	return 0
	)
}

###################################################################################
# uncompress_file_with_sudo <src_file> <target_dir>
###################################################################################
uncompress_file_with_sudo()
{
	(
	src_file=$1
	target_dir=$2
	if [ x"$target_dir" = x"" ]; then
		target_dir="./"
	fi

	postfix=`get_compress_file_postfix $src_file`
	case $postfix in
		.tar.bz2 | .tar.gz | .tar.xz | .xz | .tbz)
			if ! sudo tar xvf $src_file -C $target_dir >/dev/null 2>&1; then
				return 1
			fi
			;;
		.gz)
			if ! sudo gunzip $src_file -C $target_dir >/dev/null 2>&1; then
				return 1
			fi
			;;
		*)
			echo -e "\033[31mCan not find the suitable root filesystem!\033[0m" ; return 1
			;;
	esac
	
	return 0
	)
}


