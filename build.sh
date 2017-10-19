#!/bin/bash

###################################################################################
# Const Variables, PATH
###################################################################################
top_dir=$(cd `dirname $0` ; pwd)

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

# get absolute path
build_dir=$(mkdir -p ${build_dir} && cd ${build_dir} && pwd)

###################################################################################
# Parse configuration file
###################################################################################
platforms=$(get_install_platforms ${cfg_file} | tr ' ' ',')
distros=$(get_install_distros ${cfg_file})
envlist=$(get_envlist ${cfg_file})

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


###################################################################################
# Update Estuary FTP configuration file
###################################################################################
DOWNLOAD_FTP_ADDR=`grep -Po "(?<=estuary_interal_ftp: )(.*)" $top_dir/estuary.txt`
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
if [ x"$platforms" != x"" ]; then
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
# Download UEFI 
###################################################################################
binary_dir=${build_dir}/out/release/${version}/binary
cd ${build_dir} && rm -rf ${binary_dir}
mkdir -p ${binary_dir} && cd ${binary_dir}
git clone --depth 1 -b ${version} https://github.com/open-estuary/estuary-uefi.git .
cd ${top_dir}

echo "Download UEFI binary done!"

###################################################################################
# Copy binaries/docs ...
###################################################################################
if [ x"$platforms" != x"" ]; then
    echo "##############################################################################"
    echo "# Copy binaries/docs"
    echo "##############################################################################"
    binary_src_dir="./prebuild"
    doc_src_dir="./doc"
    doc_dir=${build_dir}/out/release/${version}/doc

    if ! copy_all_binaries $platforms $binary_src_dir $binary_dir; then
        echo -e "\033[31mError! Copy binaries failed!\033[0m" ; exit 1
    fi

    if ! copy_all_docs $platforms $doc_src_dir $doc_dir; then
        echo -e "\033[31mError! Copy docs failed!\033[0m" ; exit 1
    fi
fi

###################################################################################
# Build/clean distros
###################################################################################
for dist in ${distros}; do
	echo "/*---------------------------------------------------------------"
	echo "- ${action}  $dist"
	echo "---------------------------------------------------------------*/"
	./submodules/${action}-distro.sh --distro=${dist} \
		--version=${version} --envlist="${envlist}" \
		--build_dir=${build_dir}
	if [ $? -ne 0 ]; then
	    exit 1
	fi
done

echo "${action} distros done!"


