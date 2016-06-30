#!/bin/bash

###################################################################################
# download_distros <target_dir> <checksum_dir> <distro_source> <distros>
###################################################################################
download_distros()
{
	(
	target_dir=$1
	checksum_dir=$(cd $2; pwd)
	distro_source=$3
	distros=($(echo $4 | tr ',' ' '))

	mkdir -p $target_dir
	pushd $target_dir >/dev/null
	for distro in ${distros[@]}; do
		checksum_file="${distro}_ARM64.tar.gz.sum"
		distro_file=`cat $checksum_dir/$checksum_file | awk '{print $2}'`
		if ! check_sum . $checksum_dir/$checksum_file; then
			wget -c $distro_source/$distro/$distro_file || return 1
			check_sum . $checksum_dir/$checksum_file || return 1
		fi

		if [ x"$distro_file" != x"${distro}_ARM64.tar.gz" ]; then
			rm -f ${distro}_ARM64.tar.gz
			ln -s $distro_file ${distro}_ARM64.tar.gz
		fi
	done
	popd

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
		if [ ! -f $target_dir/.$distro ]; then
			sudo rm -rf $target_dir/$distro
			mkdir -p $target_dir/$distro
			if ! uncompress_file_with_sudo $src_dir/${distro}_ARM64.tar.gz $target_dir/$distro; then
				echo -e "\033[31mError! Uncompress ${distro}_ARM64.tar.gz failed!\033[0m" >&2
				sudo rm -rf $target_dir/$distro
				return 1
			else
				touch $target_dir/.$distro
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
		if [ -f $distro_dir/${distro}_ARM64.tar.gz ]; then
			continue
		fi

		if [ ! -d $distro_dir/$distro ]; then
			echo "Error! $distro_dir/$distro is not exist!" >&2 ; return 1
		fi

		pushd $distro_dir/$distro
		if ! (sudo tar cvf ../${distro}_ARM64.tar.gz *); then
			echo "Error! Create ${distro}_ARM64.tar.gz failed!" >&2
			return 1
		fi
		popd
	done

	return 0
	)
}

