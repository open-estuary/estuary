#!/bin/bash

###################################################################################
# int download_distros <ftp_cfgfile> <ftp_addr> <target_dir> <distros>
###################################################################################
download_distros()
{
	(
	ftp_cfgfile=$1
	ftp_addr=$2
	target_dir=$3
	distros=($(echo $4 | tr ',' ' '))

	distro_files=(`get_field_content $ftp_cfgfile distro`)
	mkdir -p $target_dir
	pushd $target_dir >/dev/null
	for distro in ${distros[@]}; do
		ftp_file=`echo ${distro_files[*]} | tr ' ' '\n' | grep -Po "(?<=${distro}_ARM64.tar.gz:)(.*)"`
		distro_file=`basename $ftp_file`

		if [ ! -f ${distro_file}.sum ]; then
			wget -c $ftp_addr/${ftp_file}.sum || return 1
		fi

		if [ ! -f $distro_file ] || ! check_sum . ${distro_file}.sum; then
			rm -f $distro_file 2>/dev/null
			wget -c $ftp_addr/$ftp_file || return 1
			check_sum . ${distro_file}.sum || return 1
		fi

		if [ x"$distro_file" != x"${distro}_ARM64.tar.gz" ]; then
			rm -f ${distro}_ARM64.tar.gz ${distro}_ARM64.tar.gz.sum 2>/dev/null
			ln -s $distro_file ${distro}_ARM64.tar.gz
			ln -s ${distro_file}.sum ${distro}_ARM64.tar.gz.sum
		fi
	done
	popd >/dev/null

	return 0
	)
}

###################################################################################
# uncompress_distros <distros> <src_dir> <target_dir>
###################################################################################
uncompress_distros()
{
	(
	distros=($(echo $1 | tr ',' ' '))
	src_dir=$2
	target_dir=$3
	for distro in ${distros[*]}; do
		if ! check_file_update $target_dir/${distro} $src_dir/${distro}_ARM64.tar.gz; then
			sudo rm -rf $target_dir/$distro
			rm -f $target_dir/${distro}_ARM64.tar.gz 2>/dev/null
			mkdir -p $target_dir/$distro
			if ! uncompress_file_with_sudo $src_dir/${distro}_ARM64.tar.gz $target_dir/$distro; then
				echo -e "\033[31mError! Uncompress ${distro}_ARM64.tar.gz failed!\033[0m" >&2
				sudo rm -rf $target_dir/$distro
				return 1
			else
				sudo rm -rf $target_dir/$distro/lib/modules/*
			fi
		fi
	done

	return 0
	)
}

###################################################################################
# create_distros <distros> <distro_dir>
###################################################################################
create_distros()
{
	(
	distros=($(echo $1 | tr ',' ' '))
	distro_dir=$2
	for distro in ${distros[*]}; do
		if [ ! -d $distro_dir/$distro ]; then
			echo "Error! $distro_dir/$distro is not exist!" >&2 ; return 1
		fi

		if [ -f $distro_dir/${distro}_ARM64.tar.gz ]; then
			echo "Check $distro_dir/${distro}_ARM64.tar.gz update ......"
			last_modify=`sudo find $distro_dir/$distro 2>/dev/null -exec stat -c %Y {} \; | sort -n -r | head -n1`
			distro_last_modify=`stat -c %Y $distro_dir/${distro}_ARM64.tar.gz 2>/dev/null`
			if [[ "$last_modify" -gt "$distro_last_modify" ]]; then
				rm -f $distro_dir/${distro}_ARM64.tar.gz
			else
				echo "File $distro_dir/${distro}_ARM64.tar.gz no need to update."
				continue
			fi
		fi

		pushd $distro_dir/$distro
		if ! (sudo tar czvf ../${distro}_ARM64.tar.gz *); then
			echo "Error! Create ${distro}_ARM64.tar.gz failed!" >&2
			rm -f ../${distro}_ARM64.tar.gz ../arm64/${distro}_ARM64.tar.gz
			return 1
		fi
		cd ..
		md5sum ${distro}_ARM64.tar.gz > ${distro}_ARM64.tar.gz.sum
		mkdir -p ../binary/arm64
		ln -s ../../distro/${distro}_ARM64.tar.gz ../binary/arm64/

		popd
	done

	return 0
	)
}

