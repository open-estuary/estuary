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
# get_packages_cmd_and_elems <cfgfile>
# input: estuarycfg json file
# output: (package_cmd, package1, package2, ..., packagen)
###################################################################################
get_packages_cmd_and_elems()
{
    (
    index=0
    cfgfile=$1
    package_list=()

    package_cmd=`jq -r ".packages.cmd" $cfgfile 2>/dev/null`
    if [ x"${package_cmd}" != x"" ] && [ x"${package_cmd}" != x"null" ] && [ x"${package_cmd}" != x"none" ] ; then
        package_list[$index]=$package_cmd
        let "index++"

        elem_index=0
        package_name=`jq -r ".packages.elems[$elem_index].name" $cfgfile 2>/dev/null`
        while [ x"${package_name}" != x"null" ] && [ x"${package_name}" != x"" ] ; do
            package_requires=`jq -r ".packages.elems[$elem_index].requires" $cfgfile 2>/dev/null`
            package_enabled=`jq -r ".packages.elems[$elem_index].enabled" $cfgfile 2>/dev/null`

            if [ x"${package_enabled}" != x"no" ] ; then
                if [ x"${package_requires}" != x"null" ] && [ x"${package_requires}" != x"" ] ; then
                    requires_list=(${package_requires//,/ })
                    for pkg1 in ${requires_list[@]}; do
                        is_existed=0
                        for pkg2 in ${package_list[@]}; do
                            if [ x"${pkg1}" == x"${pkg2}" ] ; then
                                is_existed=1
                                break
                            fi
                        done

                        if [ ${is_existed} -eq 0 ] ; then
                            package_list[$index]=$pkg1
                            let "index++"
                        fi
                    done
                fi
                package_list[$index]=${package_name}
                let "index++"
            fi

            let "elem_index++"
            package_name=`jq -r ".packages.elems[$elem_index].name" $cfgfile 2>/dev/null`
        done
    fi

    echo ${package_list[@]}
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

get_envlist()
{
    cfg_file=$1
    env_list=$(jq -r -c '.env[] | to_entries | "\(.[].key)=\(.[].value)"' ${cfg_file})

    echo "$env_list"
}
