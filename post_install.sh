#!/bin/bash
#author: Justin Zhao
#date: 31/10/2015PACKAGE_INTEGRATE_DIR
#description: automatically call all post install scripts in POST_DIR

lastupdate="2017-01-22"
INSTALL_DIR="/usr/estuary/"
POST_DIR="${INSTALL_DIR}packages"
PACKAGE_INTEGRATE_DIR="/usr/local/estuary/packages"
# This file contains the list of packages which will be installed automatically 
# during ARM64 boot up stage
POSTINSTALL_PACKAGEFILELIST="${INSTALL_DIR}.postinstall_packagelist"
INSTALL_ONE_DIR="${INSTALL_DIR}.log/one/"
INSTALL_ALWAYS_DIR="${INSTALL_DIR}.log/always/"

##################################################################################
# 
#  Package Installation(setup.sh) Return Code
#  1) INSTALL_SUCCESS: It means that this package have been installed successfully,
#              and wouldn't be installed during next boot stage 
#
#  2) INSTALL_FAILURE: It means that this package couldn't be installed at this time,
#                      but it will be installed later (or during next boot stage)
#
#  3) INSTALL_ALWAYS: It means that this package has been installed successfully
#              during this instllation stage, but they will also be re-installed 
#              at next boot stage
#              (such as loading modules during every boot stage)
#
INSTALL_SUCCESS=0
INSTALL_FAILURE=1
INSTALL_ALWAYS=2

###################################################################################
############################# Check initilization status ##########################
###################################################################################
check_init()
{
    tmpfile=$1
    tmpdate=$2

    if [ -f "$tmpfile" ]; then
        inittime=`stat -c %Y $tmpfile`
        checktime=`date +%s -d $tmpdate`

        if [ $inittime -gt $checktime ]; then
              return 1
        fi
    fi

    return 0
}

###################################################################################
############################# Decompress Packages        ##########################
###################################################################################
decompress_tar_files()
{
    packages_files=${1}
    package_dir=${2}
    install_dir=${3} 
   
    if [ ! -d "${install_dir}" ] ; then
        mkdir -p ${install_dir}
    fi
 
    cat ${packages_files} | while read line
    do
        if [ ! -z "${line}" ] ; then
            packages_list=$(ls ${package_dir}/${line}*.tar.gz) 
            for pkg_file in ${packages_list[@]}
            do
                filename=${pkg_file##*/}
                filename=${filename%\.tar\.gz*}
                if [ ! -d ${install_dir}/${filename} ] ; then
                    mkdir -p ${install_dir}/${filename}
                    tar -zxvf ${pkg_file} -C ${install_dir}/${filename}
                fi
            done
        fi
    done
}

###################################################################################
############################# Install Packages           ##########################
###################################################################################
install_packages() {
    install_file=${1}
    one_log_dir=${2}
    always_log_dir=${3}
    all_successful=0

    cat ${install_file} | while read line
    do     
        if [ -z "${line}" ] ; then
            continue
        fi

        #Not necessary to install packages which are not specified 
        pkg_dir_lists=($(ls -d $POST_DIR/${line}*))
        for fullfile in ${pkg_dir_lists[@]} ; do
            file=${fullfile##*/}
            
            check_init "${one_log_dir}/$file" $lastupdate
            ret1="$?"
            check_init "${always_log_dir}/$file" $lastupdate
            ret2="$?"
                
            if [ x"1" != x"${ret1}" ] && [ x"1" != x"${ret2}" ] ; then
                #Call script to install package
                $fullfile/setup.sh "${INSTALL_DIR}"
                retcode="$?"
                if [ x"${INSTALL_SUCCESS}" = x"${retcode}" ]; then
                    touch "${one_log_dir}/$file"
                elif [ x"${INSTALL_ALWAYS}" = x"${retcode}" ]; then
                    touch "${always_log_dir}/$file"
                else 
                    all_successful=255
                fi
            fi
        done
    done
    return ${all_successful}
}

if [ ! -d "${INSTALL_ONE_DIR}" ] ; then
    mkdir -p "${INSTALL_ONE_DIR}"
fi

if [ ! -d "${INSTALL_ALWAYS_DIR}" ] ; then 
    mkdir -p "${INSTALL_ALWAYS_DIR}"
fi

if [ ! -d "${POST_DIR}" ] ; then
    mkdir -p "${POST_DIR}"
fi

#Clear "always logs" during every boot stage
rm -fr ${INSTALL_ALWAYS_DIR}/*
decompress_tar_files "${POSTINSTALL_PACKAGEFILELIST}" "${PACKAGE_INTEGRATE_DIR}" "${POST_DIR}"

#Now begin to install packages
cur_retry_num=0
max_retry_num=24
retry_sleep_interval=300

while [[ ${cur_retry_num} -lt ${max_retry_num} ]]
do
    install_packages "${POSTINSTALL_PACKAGEFILELIST}" "${INSTALL_ONE_DIR}" "${INSTALL_ALWAYS_DIR}"
    if [ x"0" == x"$?" ] ; then
        break
    fi

    sleep ${retry_sleep_interval}
    let "cur_retry_num++"
done

#To load Estuary dynamic libs 
ldconfig

echo "Packages installation have been done"
