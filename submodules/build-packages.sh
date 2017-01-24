#!/bin/bash
#################################################################################
# Comment: This script is to integrate packages into Estuary 
# Author: Huang Jinhua
# Date : 2017/01/22
#################################################################################

#################################################################################
# Includes
#################################################################################
if [ -z "${TOPDIR}" ] ; then
    TOPDIR=$(cd ./estuary; pwd)
fi

if [ ! -d "${TOPDIR}" ] ; then
    echo "Please build packages under estuary root directory"
    exit 1
fi

if [ -z "$(echo $PATH | grep 'estuary/submodules' 2>/dev/null)" ] ; then
    export PATH=$TOPDIR:$TOPDIR/include:$TOPDIR/submodules:$TOPDIR/deploy:$PATH
fi

. $TOPDIR/Include.sh

PACKAGE_ROOT_DIR=$(cd $TOPDIR/../packages; pwd)
#################################################################################
# Define necessary variables
#################################################################################
BUILDDIR=
DISTRO=
ROOTFS=
KERNEL=
CFG_FILE=
PACKAGES=
PKG_CMD=
SPECIFCI_PACKAGES=""
INSTALL_DIR="/usr/estuary/"
PACKAGE_INTEGRATE_DIR="/usr/local/estuary/packages"
PACKAGE_SAVE_DIR=
DEBUG_ON=0

# This file contains the list of packages which will be installed automatically 
# during ARM64 boot up stage
POSTINSTALL_PACKAGEFILELIST="${INSTALL_DIR}.postinstall_packagelist"

lastupdate="2017-01-22"
OpenSuse_rc="etc/rc.d/after.local"
Fedora_rc="etc/rc.d/rc.local"
CentOS_rc="etc/rc.d/rc.local"
Default_rc="etc/rc.local"

###################################################################################
# build_packages_usage
###################################################################################
build_packages_usage()
{
cat << EOF
Usage: ./estuary/submodules/build-packages.sh --platform=xxx --packages=xxx,xxx --distro=xxx --rootfs=xxx --kernel=xxx
    --output: build output directory
    --packages: packages to build
    --distro: distro that the packages will be built for
    --rootfs: target rootfs which the package will be installed into
    --kernel: kernel output directory
    --file : estuary configuration json file
    --spec_packages: specify the specific packages (so sthat the json file will be ignored)
Example:
    ./estuary/submodules/build-packages.sh --output=./workspace --packages=docker,armor,mysql \\
    --distro=Ubuntu --rootfs=./workspace/distro/Ubuntu --kernel=./workspace/kernel \\
    --cross=aarch64-linux-gnu- --file=./estuary/estuarycfg.json
EOF
}

###################################################################################
# install_pkgs_script <distro> <rootfs> <install_dir>
###################################################################################
integrate_postinstall_scripts()
{
    (
    distro=$1
    rootfs=$2
    install_dir=$3

    local_dir=${rootfs}${install_dir}bin
    log_dir=${install_dir}.log
    log_file=${log_dir}/estuarylogs

    sudo mkdir -p ${local_dir} 2>/dev/null
    sudo mkdir -p ${rootfs}/${log_dir}

    rm -f /tmp/post_install.sh 2>/dev/null
    cp ${TOPDIR}/post_install.sh /tmp/
    sed -i "s/lastupdate=.*/lastupdate=\"$lastupdate\"/" /tmp/post_install.sh
    sudo mv /tmp/post_install.sh ${local_dir}
    sudo chmod 755 ${local_dir}/post_install.sh
    eval rc_local_file=\$${distro}_rc
    if [ x"$rc_local_file" = x"" ]; then
        rc_local_file=$Default_rc
    fi

    if [ ! -f $rootfs/$rc_local_file ]; then
        cat > /tmp/rc.local << EOF
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

exit 0
EOF
        sudo mv /tmp/rc.local $rootfs/$rc_local_file
        sudo chown root:root $rootfs/$rc_local_file
        sudo chmod 755 $rootfs/$rc_local_file
    fi

    sudo chmod +x $rootfs/$rc_local_file

    if ! grep "${install_dir}bin/post_install.sh" $rootfs/$rc_local_file >/dev/null; then
        if grep -E "^(exit)" $rootfs/$rc_local_file >/dev/null; then
            sudo sed -i "/^exit/i${install_dir}bin/post_install.sh > ${log_file} 2>&1 &" ${rootfs}/$rc_local_file
        else
            sudo sed -i "$ a ${install_dir}bin/post_install.sh > ${log_file} 2>&1 &" ${rootfs}/$rc_local_file
        fi
    fi

    return 0
    )
}

#####################################################################################
# update_system_variables <rootfs> <install_dir> 
#####################################################################################
update_system_variables()
{
    rootfs=${1}
    install_dir=${2}

    etc_file=${rootfs}/etc/profile
    ld_conf=${rootfs}/etc/ld.so.conf.d/estuaryapps.conf
    
    if [ ! -f "${ld_conf}" ] ; then
        touch ${ld_conf}
        chmod 755 ${ld_conf}
    fi

    if [ -z "$(grep "/usr/estuary/libs" ${ld_conf} 2>/dev/null)" ] ; then
        echo "/usr/estuary" >> ${ld_conf}
        echo "/usr/estuary/libs" >> ${ld_conf}
        echo "/usr/estuary/lib64" >> ${ld_conf}
    fi

    if [ -z "$(grep "/usr/estuary/bin" ${etc_file} 2>/dev/null)" ] ; then
        if [ ! -z "$(grep -E '^(exit)' ${etc_file} 2>/dev/null)" ] ; then
            sudo sed -i "/^exit/iPATH=/usr/estuary:/usr/estuary/include:/usr/estuary/bin:$PATH" ${etc_file}
            sudo sed -i "/^exit/iC_INCLUDE_PATH=/usr/estuary/include:$C_INCLUDE_PATH" ${etc_file}
            sudo sed -i "/^exit/iCPLUS_INCLUDE_PATH=/usr/estuary/include:$CPLUS_INCLUDE_PATH" ${etc_file}
            sudo sed -i "/^exit/iLIBRARY_PATH=/usr/estuary/libs:/usr/estuary/lib64:$LIBRARY_PATH" ${etc_file}
        else
            sudo sed -i "$ a PATH=/usr/estuary:/usr/estuary/include:/usr/estuary/bin:$PATH" ${etc_file}
            sudo sed -i "$ a C_INCLUDE_PATH=/usr/estuary/include:$C_INCLUDE_PATH" ${etc_file}
            sudo sed -i "$ a CPLUS_INCLUDE_PATH=/usr/estuary/include:$CPLUS_INCLUDE_PATH" ${etc_file}
            sudo sed -i "$ a LIBRARY_PATH=/usr/estuary/libs:/usr/estuary/lib64:$LIBRARY_PATH" ${etc_file}
        fi
    fi
}


#####################################################################################
# build_packages <packages> <package_cmd> <builddir> <pack_save_dir> <instal_dir>
#####################################################################################
build_packages()
{
    packages=$1
    package_cmd=${2}
    builddir_dir=$(cd ${3}; pwd)
    pack_save_dir=$(cd ${4}; pwd)
    install_dir=${5}

    packages=${packages//,/ }
    
    distro=${DISTRO}
    rootfs=$(cd "${ROOTFS}"; pwd)
    kernel=$(cd "${KERNEL}"; pwd)
    cross="${CROSS}"

    pack_type="tar"
    if [ x"${package_cmd}" == x"build_tar" ] || [ x"${package_cmd}" == x"integrate" ] || [ x"${package_cmd}" == x"install" ]; then
        pack_type="tar"
    elif [ x"${package_cmd}" == x"build_rpm" ] ; then
        pack_type="rpm"
    elif [ x"${package_cmd}" == x"build_deb" ] ; then
        pack_type="deb"
    elif [ x"${package_cmd}" == x"build_all" ] ; then
        pack_type="all"
    fi

    for pkg in ${packages[@]}; do
        subbuild_dir=${builddir_dir}/${pkg}
        
        tar_file=$(ls ${pack_save_dir}/${pkg}*.tar.gz 2>/dev/null)
        rpm_file=$(ls ${pack_save_dir}/${pkg}*.rpm 2>/dev/null)
        deb_file=$(ls ${pack_save_dir}/${pkg}*.deb 2>/dev/null)
  
        has_built=0
        if [ x"${pack_type}" == x"all" ] ; then
            if [ ! -z "${tar_file} ] && [ ! -z "${rpm_file} ] && [ ! -z "${deb_file}" ] ; then
                has_built=1
            fi
        else 
            check_file=${pack_type}_file
            if [ ! -z `eval echo '$'$check_file` ]; then
                has_built=1
            fi
        fi

        echo "###################################################################################"
        if [ ${has_built} -eq 1 ] ; then
            echo "${pkg} has been built before"
            continue
        fi
       
        PKG_BUILD_STR="${PACKAGE_ROOT_DIR}/${pkg}/build.sh ${subbuild_dir} ${distro} ${rootfs} ${kernel} ${cross} ${pack_type} ${pack_save_dir} ${install_dir}"
        echo "Begin to build ${pkg} ......"
        if [ ${DEBUG_ON} -eq 1 ] ; then
            echo "Build command:${PKG_BUILD_STR}"
        fi
        
        if [ ! -f ${PACKAGE_ROOT_DIR}/${pkg}/build.sh ] ; then
            echo "Fail to compile ${pkg} due to that ${PACKAGE_ROOT_DIR}/${pkg}/build.sh does not exist!"
            exit 1
        fi

        if [ ! -d ${subbuild_dir} ] ; then
            mkdir -p ${subbuild_dir}
        fi

        ${PACKAGE_ROOT_DIR}/${pkg}/build.sh "${subbuild_dir}" "${distro}" "${rootfs}" "${kernel}" "${cross}" "${pack_type}" "${pack_save_dir}" "${install_dir}"
    
        if [ -z "$(ls ${pack_save_dir}/${pkg}*.* 2>/dev/null)" ] ; then
            echo ""
            echo "Fail to compile ${pkg} because its build.sh doesnot generate any tar/rpm/deb files under ${pack_save_dir}"
            echo "Please consider disable ${pkg} in estuarycfg.json if really does not generate any file!"
            #exit 1
        fi
    done

    return 0
}


#####################################################################################
# integrate_packages <packages> <pack_save_dir> <dst_dir> 
#   Integrate packages into local root file system but donot install them automatically 
#  
#####################################################################################
integrate_packages() 
{
    packages=$1
    pack_save_dir=$2
    dst_dir=$3
    
    if [ ! -d ${dst_dir} ] ; then
        sudo mkdir -p ${dst_dir}
    fi

    packages=${packages//,/ }
    for pkg in ${packages[@]}; do
        sudo cp ${pack_save_dir}/${pkg}*.tar.gz ${dst_dir}
    done
}

#####################################################################################
# mark_package_installation <packages> <mark_file> 
# To mark packages in the specified file so that they could be installed automatically
#####################################################################################
mark_package_installation() 
{
    packages=$1
    mark_file=$2

    packages=${packages//,/ }
    
    if [ ! -f ${mark_file} ]; then
        sudo touch ${mark_file}
        sudo chmod 755 ${mark_file}
    fi

    #If it will re-installs packages which need to be installed before
    #just clear previous installation status
    for pkg in ${packages[@]} ; do
        if [ ! -z "$(grep ${pkg} ${mark_file})" ] ; then
            sudo echo > ${mark_file}
            break
        fi
    done

    index=0
    for pkg in ${packages[@]}; do
        if [ ${index} -eq 0 ] ; then
            sudo echo ${pkg} > ${mark_file}
        else 
            sudo echo ${pkg} >> ${mark_file}
        fi
        let "index++"
    done
}

###################################################################################
# Get args
###################################################################################
while test $# != 0
do
    case $1 in
         --*=*) ac_option=`expr "X$1" : 'X\([^=]*\)='` ; ac_optarg=`expr "X$1" : 'X[^=]*=\(.*\)'` ;;
        *) ac_option=$1 ;;
        esac
    case $ac_option in
        --output) BUILDDIR=$(cd $ac_optarg; pwd) ;;
        --distro) DISTRO=$ac_optarg ;;
        --rootfs) ROOTFS=$(cd $ac_optarg; pwd) ;;
        --kernel) KERNEL=$(cd $ac_optarg; pwd) ;;
        --cross) CROSS=$ac_optarg ;;
        --file) CFG_FILE=$ac_optarg ;;
        --spec_packages) SPECIFIC_PACKAGES=$ac_optarg ;;
        --debug) DEBUG_ON=1 ;;
        --help) build_packages_usage; exit 1 ;;

        *) echo -e "\033[31mUnknown option $ac_option!\033[0m"
        build_packages_usage ; exit 1 ;;
        esac

    shift
done

##################################################################################
# Parse extra args
##################################################################################
if [ ! -z "${SPECIFIC_PACKAGES}" ] ; then
    PACKAGES_CMD="install"
    PACKAGES=${SPECIFIC_PACKAGES}
    #PACKAGES=${SPECIFIC_PACKAGES//,/ }
elif [ -f "${CFG_FILE}" ] ; then
    PACKAGES_CMD_ELEM=$(get_packages_cmd_and_elems $CFG_FILE | tr ' ' ',')
    if [ ${DEBUG_ON} -eq 1 ]; then
        echo "Parse estuarycfg.json results:${PACKAGES_CMD_ELEM}"
    fi

    PACKAGES_CMD_LIST=(${PACKAGES_CMD_ELEM//,/ })
    if [ ${#PACKAGES_CMD_LIST[@]} -eq 0 ] ; then
        PACKAGES_CMD="none"
        PACKAGES=""
    else
        PACKAGES_CMD=${PACKAGES_CMD_LIST[0]}
        unset PACKAGES_CMD_LIST[0]
        PACKAGES=$(echo ${PACKAGES_CMD_LIST[@]} | tr ' ' ','$)
    fi
    
    #PACKAGES_CMD=${PACKAGES_CMD_ELEM%%,*}
    #PACKAGES=${PACKAGES_CMD_ELEM#*,}
fi 

echo "Build command:${PACKAGES_CMD}, packages:${PACKAGES[@]}"
###################################################################################
# Check args
##################################################################################
if [ ${#PACKAGES[@]} -eq 0 ] || [ -z "${PACKAGES}" ] || [ -z "${PACKAGES_CMD}" ] || [ "${PACKAGES_CMD}" == "none" ] ; then
    echo "Not necessary to build any packages" ; 
    exit 0
fi
if [ x"$BUILDDIR" = x"" ] || [ x"$DISTRO" = x"" ] || [ x"$ROOTFS" = x"" ] || [ x"$KERNEL" = x"" ]; then
    echo "Some arguments are not specified, such as output: $BUILDDIR, distro: $DISTRO, rootfs: $ROOTFS, kernel: $KERNEL"
    exit 1
fi

if [ ! -d $ROOTFS ]; then
    echo "Error! The specified rootfs directory:${ROOTFS} does not exist" >&2 ; 
    exit 1
fi

if [ ! -d $KERNEL ]; then
    echo "Error! The specified kernel directory:${KERNEL} does not exist" >&2 ; 
    exit 1
fi

###################################################################################
# Build packages
###################################################################################
PACKAGE_BUILD_DIR=${BUILDDIR}/packages/builddir/
PACKAGE_SAVE_DIR=${BUILDDIR}/packages/${DISTRO}/
if [ ! -d ${PACKAGE_BUILD_DIR} ] ; then
    mkdir -p ${PACKAGE_BUILD_DIR}
fi

if [ ! -d ${PACKAGE_SAVE_DIR} ] ; then
    mkdir -p ${PACKAGE_SAVE_DIR}
fi

build_packages "${PACKAGES}" "${PACKAGES_CMD}" "${PACKAGE_BUILD_DIR}" "${PACKAGE_SAVE_DIR}" "${INSTALL_DIR}" 
integrate_postinstall_scripts ${DISTRO} ${ROOTFS} ${INSTALL_DIR}
update_system_variables "${ROOTFS}" "${INSTALL_DIR}"

###################################################################################
# Integrate built packages into root file system but don't install them automatically
###################################################################################
ROOTFS_INTEGRATE_DIR=${ROOTFS}${PACKAGE_INTEGRATE_DIR}
if [ x"${PACKAGES_CMD}" == x"integrate" ]; then
    integrate_packages ${PACKAGES} ${PACKAGE_SAVE_DIR} ${ROOTFS_INTEGRATE_DIR} 
    echo "Packages have been integrated ${DISTRO} root file system"
    exit 0
fi

##################################################################################
#  Mark packages which will be installed automatically
##################################################################################
if [ x"${PACKAGES_CMD}" == x"install" ]; then
    integrate_packages ${PACKAGES} ${PACKAGE_SAVE_DIR} ${ROOTFS_INTEGRATE_DIR} 
    mark_package_installation ${PACKAGES} ${ROOTFS}/${POSTINSTALL_PACKAGEFILELIST}
    echo "Packages will be installed automatically during ${DISTRO} boot up stage"
    exit 0
fi

echo "Only build packages successfully"
