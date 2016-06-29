#!/bin/bash

###################################################################################
# get_cross_compile <arch> <toolchain_dir>
###################################################################################
get_cross_compile()
{
	(
	arch=$1
	toolchain_dir=$2

	if [ x"$arch" != x"x86_64" ]; then
		return 0
	fi

	cross_compile=$(basename `find $toolchain_dir/bin -name "*-gcc" 2>/dev/null` | grep -Po "(.*-)(?=gcc$)")
	echo $cross_compile
	)
}

