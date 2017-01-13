#!/bin/bash
#author: Justin Zhao
#date: 31/10/2015
#description: automatically call all post install scripts in post_dir

lastupdate="2015-10-15"
post_dir="/usr/bin/estuary/postinstall"
install_log_dir="/usr/bin/estuary/.log"
install_one_dir="${install_log_dir}/one"
install_always_dir="${install_log_dir}/always/"

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
############################# Install Packages           ##########################
###################################################################################
install_packages() {
    one_log_dir=${1}
    always_log_dir=${2}
    all_successful=0
    
    for fullfile in $post_dir/*
    do
        file=${fullfile##*/}
        if [ -f $fullfile ]; then
            check_init "${one_log_dir}/$file" $lastupdate
            ret1="$?"
            check_init "${always_log_dir}/$file" $lastupdate
            ret2="$?"
                
            if [ x"1" != x"${ret1}" ] && [ x"1" != x"${ret2}" ] ; then
                #Call script to install package
                $fullfile
                retcode="$?"
                if [ x"${INSTALL_SUCCESS}" = x"${retcode}" ]; then
                    touch "${one_log_dir}/$file"
                elif [ x"${INSTALL_ALWAYS}" = x"${retcode}" ]; then
                    touch "${always_log_dir}/$file"
                else 
                    all_successful=255
                fi
            fi
        fi
    done
    return ${all_successful}
}

if [ ! -d "${install_one_dir}" ] ; then
    mkdir -p "${install_one_dir}"
fi
if [ ! -d "${install_always_dir}" ] ; then 
    mkdir -p "${install_always_dir}"
fi

#Clear "always logs" during every boot stage
rm -fr ${install_always_dir}/*

#Now begin to install packages
cur_retry_num=0
max_retry_num=24
retry_sleep_interval=300

while [[ ${cur_retry_num} -lt ${max_retry_num} ]]
do
    install_packages ${install_one_dir} ${install_always_dir}
    if [ x"0" == x"$?" ] ; then
        break
    fi

    sleep ${retry_sleep_interval}
    let "cur_retry_num++"
done

echo "Packages installation have been done"
