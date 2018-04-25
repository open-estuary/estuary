#!/bin/bash

###################################################################################
# Const Variables, PATH
###################################################################################
LOCALARCH=`uname -m`
if [ x"$LOCALARCH" = x"x86_64" ]; then
    DEFAULT_ESTUARYCFG="./estuarycfg_x86_64.json"
else
    DEFAULT_ESTUARYCFG="./estuarycfg.json"
fi
SUPPORT_DISTROS=(`sed -n '/^\"distros\":\[/,/^\]/p' $DEFAULT_ESTUARYCFG 2>/dev/null | sed 's/\"//g' | grep -Po "(?<=name:)(.*?)(?=,)" | sort`)

top_dir=$(cd `dirname $0` ; pwd)
dname=$(dirname "$PWD")

export WGET_OPTS="-T 120 -c"
export LC_ALL=C
export LANG=C

###################################################################################
# Includes
###################################################################################
cd ${top_dir}
. Include.sh

# check host arch, docker running permission
check_running_not_in_container

###################################################################################
# Variables
###################################################################################
declare -l distros DISTROS
action=build			# build or clean, default to build
build_dir=${top_dir}/build	# Build output directory
platforms=			# Platforms to build, support platforms: d03, d05
distros=			# Distros to build, support distro: debian, centos, ubuntu, opensuse, fedora
version=master			# estuary repo's tag or branch
cfg_file=${DEFAULT_ESTUARYCFG}	# config file

###################################################################################
# Usage
###################################################################################
Usage()
{
    local distros=`echo ${SUPPORT_DISTROS[*]} | sed 's/ /, /g'`

cat << EOF
Usage: ./build.sh [options]
Options:
    -h, --help: Display this information
    -d, --distro: the distribuations
        * support distros: $distros
    --builddir: Build output directory, default is ./build
    clean: Clean all distros.

Example:
    ./build.sh --help
    ./build.sh --build_dir=./workspace # build distros from json configuration
    ./build.sh --build_dir=./workspace -d ubuntu,centos # build specified distros,separated with ","
    ./build.sh --build_dir=./workspace clean 	# clean distros
    sudo ./build.sh --build_dir=./workspace -d ubuntu # when user is not root, you should add sudo !!!
EOF
}

###################################################################################
# Get all args
###################################################################################
while test $# != 0
do
    case $1 in
        --*=*) ac_option=`expr "X$1" : 'X\([^=]*\)='` ; ac_optarg=`expr "X$1" : 'X[^=]*=\(.*\)'` ; ac_shift=: ;;
        -*) ac_option=$1 ; ac_optarg=$2; ac_shift=shift ;;
        *) ac_option=$1 ; ac_shift=: ;;
    esac

    case ${ac_option} in
        clean) action=clean ;;
	--build_dir) eval build_dir=$ac_optarg ;;
        -d | --distro) DISTROS=$ac_optarg ;;
        -h | --help) Usage ; exit 0 ;;
        *) Usage ; echo "Unknown option $1" ; exit 1 ;;
    esac

    ${ac_shift}
    shift
done


###################################################################################
# Install development tools
###################################################################################
if [ x"$action" != x"clean" ]; then
    install_dev_tools
fi

docker_status=`service docker status|grep "running"`
if [ x"$docker_status" = x"" ]; then
    service docker start
fi

gnupg_dir=${top_dir}/..
if [ -d "$HOME/.gnupg" ]; then
    cp -rf $HOME/.gnupg ${gnupg_dir}
else
    echo -e "\033[31mPlease import estuary secure key first!\033[0m";exit 1
fi

# get estuary repo version
tag=$(cd ${top_dir} && git describe --tags --exact-match || true)
version=${tag:-${version}}
build_kernel_pkg_only=${BUILD_KERNEL_PKG_ONLY:-false}

# get absolute path
cd ${top_dir}
build_dir=$(mkdir -p ${build_dir} && cd ${build_dir} && pwd)

###################################################################################
# Parse configuration file
###################################################################################
platforms=$(get_install_platforms ${cfg_file} | tr ' ' ',')
envlist=$(get_envlist ${cfg_file})
build_common=${BUILD_COMMON:-false}

if [ x"$DISTROS" != x"" ]; then
    get_common=`echo $DISTROS |grep -w common`
    distros=$(echo $DISTROS |sed 's/common//g' |tr ',' ' ')
else
    get_common=`echo $(get_install_distros ${cfg_file}) |grep -w common`
    distros=$(get_install_distros ${cfg_file} |sed 's/common//g')
fi

DISTROS=$(echo $distros | tr ' ' ',')
if [ x"$get_common" != x"" ]; then
    build_common=true
    all_distros="$distros common"
else
    all_distros=$distros
fi

if [ x"$build_kernel_pkg_only" = x"true" ]; then
    if [ x"$distros" = x"" ]; then
        echo -e "\033[31mcommon no need to build package!\033[0m"
        exit 0
    else
        build_common=false
    fi
fi

for dist in ${distros};do
    check_distro=`echo ${SUPPORT_DISTROS[*]} |grep -w $dist`
    if [ x"$check_distro" = x"" ]; then
        echo -e "\033[31mError! $dist is not supported!\033[0m"
        echo -e "\033[31mSupport distros: ${SUPPORT_DISTROS[*]}\033[0m" ; exit 1
    fi
done


cat << EOF
##############################################################################
# platform:	${platforms}
# distro:	${all_distros}
# version:	${version}
# build_dir:	${build_dir}
# envlist:	${envlist}
##############################################################################
EOF

###################################################################################
# Check args
###################################################################################
for var in ${envlist}; do
	repo_url=`echo ${var} |sed 's/.*=//g'`
	wget -q --spider  $repo_url/
	if [ $? -eq 0 ];then
	    new="$new $var"
	fi
done
envlist=${new}
export ${envlist}


###################################################################################
# Update Estuary FTP configuration file
###################################################################################
DOWNLOAD_FTP_ADDR=`grep -Po "(?<=estuary_interal_ftp: )(.*)" $top_dir/estuary.txt`
DOWNLOAD_FTP_ADDR=${ESTUARY_FTP:-"$DOWNLOAD_FTP_ADDR"}
ESTUARY_FTP_CFGFILE="${version}.xml"
if [ x"$build_common" = x"true" ] || [ x"$build_kernel_pkg_only" = x"false" ]; then
    if ! check_ftp_update $version . ; then
        echo "##############################################################################"
        echo "# Update estuary configuration file"
        echo "##############################################################################"
        if ! update_ftp_cfgfile $version $DOWNLOAD_FTP_ADDR . ; then
            echo -e "\033[31mError! Update Estuary FTP configuration file failed!\033[0m" ; exit 1
        fi
        rm -f prebuild/.*.sum prebuild/*.sum 2>/dev/null
        rm -f toolchain/.*.sum toolchain/*.sum 2>/dev/null
    fi
fi

###################################################################################
# Download/uncompress toolchains
###################################################################################
if [ x"$LOCALARCH" = x"x86_64" ]; then
    echo "##############################################################################"
    echo "# Download/Uncompress toolchain"
    echo "##############################################################################"
    mkdir -p toolchain
    download_toolchains $ESTUARY_FTP_CFGFILE $DOWNLOAD_FTP_ADDR toolchain
    if [[ $? != 0 ]]; then
        echo -e "\033[31mError! Download toolchains failed!\033[0m" >&2 ; exit 1
    fi

    if ! uncompress_toolchains $ESTUARY_FTP_CFGFILE toolchain; then
        echo -e "\033[31mError! Uncompress toolchains failed!\033[0m" >&2 ; exit 1
    fi

    toolchain=`get_toolchain $ESTUARY_FTP_CFGFILE arm`
    toolchain_dir=`get_compress_file_prefix $toolchain`
    export PATH=`pwd`/toolchain/$toolchain_dir/bin:$PATH

    toolchain=`get_toolchain $ESTUARY_FTP_CFGFILE aarch64`
    toolchain_dir=`get_compress_file_prefix $toolchain`

    TOOLCHAIN=$toolchain
    TOOLCHAIN_DIR=`cd toolchain/$toolchain_dir; pwd`
    CROSS_COMPILE=`get_cross_compile $LOCALARCH $TOOLCHAIN_DIR`
    export PATH=$TOOLCHAIN_DIR/bin:$PATH
fi

###################################################################################
# Download binaries
###################################################################################
if [ x"$build_common" = x"true" ] && [ x"$action" != x"clean" ]; then
    echo "##############################################################################"
    echo "# Download binaries"
    echo "##############################################################################"
    mkdir -p prebuild
    download_binaries $ESTUARY_FTP_CFGFILE $DOWNLOAD_FTP_ADDR prebuild
    if [[ $? != 0 ]]; then
        echo -e "\033[31mError! Download binaries failed!\033[0m" ; exit 1
    fi
fi
echo ""

###################################################################################
# Copy toolchains
###################################################################################
if [ x"$LOCALARCH" = x"x86_64" ]; then
    echo "##############################################################################"
    echo "# Copy toolchains"
    echo "##############################################################################"
    mkdir -p $BUILD_DIR/binary/arm64 2>/dev/null
    if ! copy_toolchains $ESTUARY_FTP_CFGFILE toolchain $BUILD_DIR/binary/arm64; then
        echo -e "\033[31mError! Copy toolchains failed!\033[0m" ; exit 1
    fi
fi

###################################################################################
# Download UEFI and kernel depository
###################################################################################
if [ x"$build_common" = x"true" ] && [ x"$action" != x"clean" ]; then
    binary_dir=${build_dir}/out/release/${version}/binary
    mkdir -p ${binary_dir} && cd ${binary_dir}
    rm -rf estuary-uefi-* ${version}.zip
    wget ${WGET_OPTS} https://github.com/open-estuary/estuary-uefi/archive/${version}.zip
    unzip ${version}.zip ; cp -rf estuary-uefi-*/* . ; rm -rf estuary-uefi-* ${version}.zip
fi
if [ x"$action" != x"clean" ]; then
    cd ${top_dir}
    if [ ! -f "kernel-${version}-ready" ]; then
        rm -rf kernel
    fi
    if [ ! -d "kernel" ]; then
        git clone --depth 1 -b ${version} https://github.com/open-estuary/kernel.git
        rm -rf kernel-*-ready
        touch kernel-${version}-ready
    else
        (cd kernel ; git pull || true)
    fi

fi

###################################################################################
# Copy binaries/docs ...
###################################################################################
if [ x"$platforms" != x"" ] && [ x"$action" != x"clean" ] && [ x"$build_common" = x"true" ]; then
    echo "##############################################################################"
    echo "# Copy binaries/docs"
    echo "##############################################################################"
    binary_src_dir="./prebuild"
    doc_src_dir=${top_dir}/doc/release-files
    doc_dir=${build_dir}/out/release/${version}

    if ! copy_all_binaries $platforms $binary_src_dir $binary_dir; then
        echo -e "\033[31mError! Copy binaries failed!\033[0m" ; exit 1
    fi

    cp -rf ${doc_src_dir}/* ${doc_dir}
fi

###################################################################################
# Build/clean distros
###################################################################################
#    docker run --rm --privileged ${qemu_image} bash
for dist in ${distros};do
        debian_image="linaro/ci-arm64-debian:stretch"
        centos_image="openestuary/centos:3.1-full"
        opensuse_image="arm64v8/opensuse:leap"
        fedora_image="arm64v8/fedora:26"
        ubuntu_image="openestuary/ubuntu:3.1-full"
        eval image="$"${dist}"_image"
        docker pull ${image}
        status=$?
        while [ $status != 0 ];
        do
            docker pull ${image}
            status=$?
        done;
done

for dist in ${distros}; do
	echo "/*---------------------------------------------------------------"
	echo "- ${action}  $dist"
	echo "---------------------------------------------------------------*/"
	./submodules/${action}-distro.sh --distro=${dist} \
		--version=${version} --envlist="${envlist}" \
		--build_dir=${build_dir} --build_kernel=${build_kernel_pkg_only}
	if [ $? -ne 0 ]; then
	    exit 1
	fi
	echo "${action} ${dist} done!"
done


###################################################################################
# Build/clean common rootfs
###################################################################################
if [ x"$build_common" = x"true" ]; then
        ./submodules/${action}-distro.sh --distro=common \
                --version=${version} --envlist="${envlist}" \
                --build_dir=${build_dir} --build_kernel=${build_kernel_pkg_only}
        if [ $? -ne 0 ]; then
            exit 1
        fi
	echo "${action} common rootfs done!"
fi


###################################################################################
# Build/clean kernel packages finish here
###################################################################################

if [ x"$build_kernel_pkg_only" = x"true" ]; then
    echo "${action} kernel packages done!"
    exit 0
fi

###################################################################################
# Download/uncompress distros tar
###################################################################################
if [ x"$DISTROS" != x"" ] && [ x"$action" != x"clean" ]; then
    echo "##############################################################################"
    echo "# Download distros (distros: $DISTROS)"
    echo "##############################################################################"
    mkdir -p distro
    download_distros $ESTUARY_FTP_CFGFILE $DOWNLOAD_FTP_ADDR distro $DISTROS
    if [[ $? != 0 ]]; then
        echo -e "\033[31mError! Download distros failed!\033[0m" ; exit 1
    fi
    echo ""

    echo "##############################################################################"
    echo "# Uncompress distros (distros: $DISTROS)"
    echo "##############################################################################"

    rootfs_dir=$build_dir/out/release/${version}/.rootfs
    if ! uncompress_distros $DISTROS distro $rootfs_dir; then
        echo -e "\033[31mError! Uncompress distro files failed!\033[0m" ; exit 1
    fi
    echo ""
fi

###################################################################################
# Install modules
###################################################################################
if [ x"$DISTROS" != x"" ] && [ x"$action" != x"clean" ]; then
    for distro in ${distros[*]}; do
        build_dir=${build_dir}/${distro}
        mkdir -p ${build_dir}
        cp -rf kernel $build_dir/kernel
        echo "---------------------------------------------------------------"
        echo "- Build modules (kerneldir: $build_dir, rootfs: $rootfs_dir/$distro, cross: $CROSS_COMPILE)"
        echo "---------------------------------------------------------------"
        ./submodules/build-modules.sh --kerneldir=$build_dir --rootfs=$rootfs_dir/$distro --cross=$CROSS_COMPILE || exit 1
        rm -rf $build_dir
        echo "- Build modules done!"
        echo ""
    done
fi

###################################################################################
# Build distros tar
###################################################################################
if [ x"$DISTROS" != x"" ] && [ x"$action" != x"clean" ]; then

    echo "/*---------------------------------------------------------------"
    echo "- create distros (distros: $DISTROS, distro dir: $rootfs_dir)"
    echo "---------------------------------------------------------------*/"
    if ! create_distros $DISTROS $rootfs_dir; then
        echo -e "\033[31mError! Create distro files failed!\033[0m" ; exit 1
    fi
    for distro in ${distros[*]}; do
        rm -rf ${rootfs_dir}/${distro}*
    done

    echo "Build distros done!"
    echo ""
fi


