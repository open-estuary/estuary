#!/bin/bash

###################################################################################
# get_toolchain <ftp_cfgfile> <arch>
###################################################################################
get_toolchain()
{
	(
	ftp_cfgfile=$1
	arch=$2
	get_field_content $ftp_cfgfile toolchain | tr ' ' '\n' | grep $arch | awk -F ':' '{print $1}'
	)
}

###################################################################################
# int download_toolchains <ftp_cfgfile> <ftp_addr> <target_dir>
###################################################################################
download_toolchains()
{
	(
	ftp_cfgfile=$1
	ftp_addr=$2
	target_dir=$3
	toolchain_files=(`get_field_content $ftp_cfgfile toolchain`)

	pushd $target_dir >/dev/null
	for toolchain in ${toolchain_files[*]}; do
		target_file=`expr "X$toolchain" : 'X\([^:]*\):.*' | sed 's/ //g'`
		target_addr=`expr "X$toolchain" : 'X[^:]*:\(.*\)' | sed 's/ //g'`
		toolchain_file=`basename $target_addr`

		if [ ! -f ${toolchain_file}.sum ]; then
			rm -f .${toolchain_file}.sum 2>/dev/null
			wget $ftp_addr/${target_addr}.sum || return 1
		fi

		if [ ! -f $toolchain_file ] || ! check_sum . ${toolchain_file}.sum; then
			rm -f $toolchain_file 2>/dev/null
			wget ${WGET_OPTS} $ftp_addr/$target_addr || return 1
			check_sum . ${toolchain_file}.sum || return 1
		fi
		
		if [ x"$target_file" != x"$toolchain_file" ]; then
			rm -f $target_file 2>/dev/null
			ln -s $toolchain_file $target_file
		fi
	done
	popd >/dev/null

	return 0
	)
}

###################################################################################
# int copy_toolchains <ftp_cfgfile> <src_dir> <target_dir>
###################################################################################
copy_toolchains()
{
	(
	ftp_cfgfile=$1
	src_dir=$2
	target_dir=$3
	toolchain_files=(`get_field_content $ftp_cfgfile toolchain | tr ' ' '\n' | awk -F ':' '{print $1}'`)
	for toolchain_file in ${toolchain_files[*]}; do
		if ! (diff $src_dir/${toolchain_file}.sum $target_dir/.${toolchain_file}.sum >/dev/null 2>&1) \
			|| [ ! -f $target_dir/$toolchain_file ]; then
			rm -f $target_dir/$toolchain_file 2>/dev/null
			cp $src_dir/$toolchain_file $target_dir/$toolchain_file || return 1
			rm -f $target_dir/.${toolchain_file}.sum 2>/dev/null
			cp $src_dir/${toolchain_file}.sum $target_dir/.${toolchain_file}.sum || return 1
		fi
	done

	return 0
	)
}

###################################################################################
# int uncompress_toolchains <ftp_cfgfile> <src_dir>
###################################################################################
uncompress_toolchains()
{
	(
	ftp_cfgfile=$1
	src_dir=$2

	toolchain_files=(`get_field_content $ftp_cfgfile toolchain | tr ' ' '\n' | awk -F ':' '{print $1}'`)

	for toolchain_file in ${toolchain_files[*]}; do
		toolchain_dir=`get_compress_file_prefix $toolchain_file`
		if [ ! -d $src_dir/$toolchain_dir ]; then
			if ! uncompress_file $src_dir/$toolchain_file $src_dir; then
				rm -rf $src_dir/$toolchain_dir 2>/dev/null ; return 1
			fi
		fi
	done

	return 0
	)
}

###################################################################################
# int install_toolchain <ftp_cfgfile> <src_dir>
###################################################################################
install_toolchain()
{
	(
	ftp_cfgfile=$1
	src_dir=$2
	toolchain_files=(`get_field_content $ftp_cfgfile toolchain | tr ' ' '\n' | awk -F ':' '{print $1}'`)
	
	for toolchain_file in ${toolchain_files[*]}; do
		toolchain_dir=`get_compress_file_prefix $toolchain_file`
		if [ ! -d /opt/$toolchain ]; then
			if ! sudo cp -r $src_dir/$toolchain_dir/ /opt/; then
				return 1
			fi

			str='export PATH=$PATH:/opt/'$toolchain_dir'/bin'
			if ! grep "$str" ~/.bashrc >/dev/null; then
				echo "$str">> ~/.bashrc
			fi
		fi
	done

	return 0
	)
}

