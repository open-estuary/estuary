#!/bin/bash

###################################################################################
# get_install_platforms <cfgfile>
###################################################################################
get_install_platforms()
{
	(
	index=0
	cfgfile=$1
	platforms=()
	install=`jq -r ".system[$index].install" $cfgfile 2>/dev/null`
	while [ x"$?" = x"0" ] && [ x"$install" != x"null" ] && [ x"$install" != x"" ]; do
		if [ x"yes" = x"$install" ]; then
			platform=`jq -r ".system[$index].platform" $cfgfile`
			idx=${#platforms[@]}
			platforms[$idx]=$platform
		fi
		
		(( index=index+1 ))
		install=`jq -r ".system[$index].install" $cfgfile`
	done

	echo ${platforms[@]}
	)
}

###################################################################################
# get_install_distros <cfgfile>
###################################################################################
get_install_distros()
{
	(
	index=0
	cfgfile=$1
	distros=()
	install=`jq -r ".distros[$index].install" $cfgfile 2>/dev/null`
	while [ x"$?" = x"0" ] && [ x"$install" != x"null" ] && [ x"$install" != x"" ]; do
		if [ x"yes" = x"$install" ]; then
			distro=`jq -r ".distros[$index].name" $cfgfile`
			idx=${#distros[@]}
			distros[$idx]=$distro
		fi
		
		(( index=index+1 ))
		install=`jq -r ".distros[$index].install" $cfgfile`
	done

	echo ${distros[@]}
	)
}

###################################################################################
# get_install_capacity <cfgfile>
###################################################################################
get_install_capacity()
{
	(
	index=0
	cfgfile=$1
	capacities=()
	install=`jq -r ".distros[$index].install" $cfgfile 2>/dev/null`
	while [ x"$?" = x"0" ] && [ x"$install" != x"null" ] && [ x"$install" != x"" ]; do
		if [ x"yes" = x"$install" ]; then
			capacity=`jq -r ".distros[$index].capacity" $cfgfile`
			idx=${#capacities[@]}
			capacities[$idx]=$capacity
		fi
		
		(( index=index+1 ))
		install=`jq -r ".distros[$index].install" $cfgfile`
	done

	echo ${capacities[@]}
	)
}

###################################################################################
# get_install_packages <cfgfile>
###################################################################################
get_install_packages()
{
	(
	index=0
	cfgfile=$1
	packages=()
	install=`jq -r ".packages[$index].install" $cfgfile 2>/dev/null`
	while [ x"$?" = x"0" ] && [ x"$install" != x"null" ] && [ x"$install" != x"" ]; do
		if [ x"yes" = x"$install" ]; then
			package=`jq -r ".packages[$index].name" $cfgfile`
			idx=${#packages[@]}
			packages[$idx]=$package
		fi
		
		(( index=index+1 ))
		install=`jq -r ".packages[$index].install" $cfgfile`
	done

	echo ${packages[@]}
	)
}

###################################################################################
# get_boards_mac <cfgfile>
###################################################################################
get_boards_mac()
{
	(
	cfgfile=$1
	brdmacs=()
	index=0
	board_mac=`jq -r ".boards[$index].mac" $cfgfile 2>/dev/null`
	while [ x"$?" = x"0" ] && [ x"$board_mac" != x"null" ] && [ x"$board_mac" != x"" ]; do
		idx=${#brdmacs[@]}
		brdmacs[$idx]=$board_mac
		index=$[index + 1]
		board_mac=`jq -r ".boards[$index].mac" $cfgfile 2>/dev/null`
	done
	echo ${brdmacs[@]}
	)
}

###################################################################################
# get_deploy_info <cfgfile>
###################################################################################
get_deploy_info()
{
	(
	cfgfile=$1

	index=0
	install=`jq -r ".setup[$index].install" $cfgfile 2>/dev/null`
	while [ x"$?" = x"0" ] && [ x"$install" != x"null" ] && [ x"$install" != x"" ]; do
		if [ x"yes" = x"$install" ]; then
			deploy_info=`jq -r ".setup[$index]" $cfgfile 2>/dev/null | sed -e 's/[ |{|}|"]//g' | tr ':' '=' | sed -e 's/install=yes,*//g'`
			deploy_type=`echo "$deploy_info" | grep -Po "(?<=type=)([^,]*)"`
			deploy_device=`echo "$deploy_info" | grep -Po "(?<=device=)([^,]*)"`
			if [ x"$deploy_device" != x"" ]; then
				echo "$deploy_type:$deploy_device"
			else
				echo "$deploy_type"
			fi
		fi
		index=$[index + 1]
		install=`jq -r ".setup[$index].install" $cfgfile 2>/dev/null`
	done

	return 0
	)
}


