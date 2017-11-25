#!/bin/bash

###################################################################################
# Const Variables, PATH
###################################################################################
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
check_arch
check_running_not_in_container

###################################################################################
# Variables
###################################################################################
action=build			# build or clean, default to build
build_dir=${top_dir}/build	# Build output directory
platforms=			# Platforms to build, support platforms: d03, d05
distros=			# Distros to build, support distro: debian, centos, ubuntu
version=master			# estuary repo's tag or branch
cfg_file=estuarycfg.json	# config file

###################################################################################
# Usage
###################################################################################
Usage()
{
cat << EOF
Usage: ./build.sh [options]
Options:
    -h, --help: Display this information
    --builddir: Build output directory, default is ./build
    clean: Clean all distros.

Example:
    ./build.sh --help
    ./build.sh --build_dir=./workspace # build distros
    ./build.sh --build_dir=./workspace clean 	# clean distros
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

docker_status=`sudo service docker status|grep "running"`
if [ x"$docker_status" = x"" ]; then
    sudo service docker start
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
distros=$(get_install_distros ${cfg_file})
envlist=$(get_envlist ${cfg_file})
DISTROS=$(get_install_distros ${cfg_file} | tr ' ' ',')

cat << EOF
##############################################################################
# platform:	${platforms}
# distro:	${distros}
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
if ! check_ftp_update $version . ; then
    echo "##############################################################################"
    echo "# Update estuary configuration file"
    echo "##############################################################################"
    if ! update_ftp_cfgfile $version $DOWNLOAD_FTP_ADDR . ; then
        echo -e "\033[31mError! Update Estuary FTP configuration file failed!\033[0m" ; exit 1
    fi
    rm -f prebuild/.*.sum prebuild/*.sum 2>/dev/null
fi

###################################################################################
# Download binaries
###################################################################################
if [ x"$platforms" != x"" ] && [ x"$action" != x"clean" ]; then
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
# Download UEFI and kernel depository
###################################################################################
if [ x"$action" != x"clean" ]; then
    binary_dir=${build_dir}/out/release/${version}/binary
    cd ${build_dir} && rm -rf ${binary_dir}
    mkdir -p ${binary_dir} && cd ${binary_dir}
    git clone --depth 1 -b ${version} https://github.com/open-estuary/estuary-uefi.git .
    cd ${top_dir}
    if [ ! -d "kernel" ]; then
        git clone --depth 1 -b ${version} https://github.com/open-estuary/kernel.git
    else
        (cd kernel ; git pull || true)
    fi
    if [ x"$build_kernel_pkg_only" = x"true" ] && [ ! -d "distro-repo" ]; then
        git clone --depth 1 -b ${version} https://github.com/open-estuary/distro-repo.git
    elif [ -d "distro-repo" ];then
        (cd distro-repo ; git pull || true)
    fi

    echo "Download UEFI and kernel depository done!"
fi

###################################################################################
# Copy binaries/docs ...
###################################################################################
if [ x"$platforms" != x"" ] && [ x"$action" != x"clean" ]; then
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
for dist in ${distros};do
        tag=3.1-full
        image=openestuary/${dist}:${tag}
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
done

echo "${action} distros done!"

###################################################################################
# Build/clean minirootfs
###################################################################################
if [ x"$DISTROS" != x"" ]; then
        ./submodules/${action}-distro.sh --distro=minifs \
                --version=${version} --envlist="${envlist}" \
                --build_dir=${build_dir} --build_kernel=${build_kernel_pkg_only}
        if [ $? -ne 0 ]; then
            exit 1
        fi
fi

echo "${action} minirootfs done!"

###################################################################################
# Build/clean kernel packages finish here
###################################################################################

if [ x"$build_kernel_pkg_only" = x"true" ]; then
    exit 0
    echo "${action} kernel packages done!"
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

    rootfs_dir=$build_dir/out/release/${version}/rootfs
    if ! uncompress_distros $DISTROS distro $rootfs_dir; then
        echo -e "\033[31mError! Uncompress distro files failed!\033[0m" ; exit 1
    fi
    echo ""
fi

###################################################################################
# Build distros tar
###################################################################################
if [ x"$DISTROS" != x"" ] && [ x"$action" != x"clean" ]; then

    echo "/*---------------------------------------------------------------"
    echo "- create distros (distros: $DISTROS, distro dir: $build_dir/rootfs)"
    echo "---------------------------------------------------------------*/"
    if ! create_distros $DISTROS $rootfs_dir; then
        echo -e "\033[31mError! Create distro files failed!\033[0m" ; exit 1
    fi
    sudo rm -rf $rootfs_dir

    echo "Build distros done!"
    echo ""
fi


