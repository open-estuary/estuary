#!/bin/bash -e

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
    clean: Clean all distros.

Example:
    ./build.sh --help
    ./build.sh 		# build distros
    ./build.sh clean 	# clean distros
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
        -h | --help) Usage ; exit 0 ;;
        *) Usage ; echo "Unknown option $1" ; exit 1 ;;
    esac

    ${ac_shift}
    shift
done


###################################################################################
# Install development tools
###################################################################################
install_dev_tools

# get estuary repo version
tag=$(cd ${top_dir} && git describe --tags --exact-match || true)
version=${tag:-${version}}


###################################################################################
# Parse configuration file
###################################################################################
platforms=$(get_install_platforms ${cfg_file})
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


###################################################################################
# Build/clean distros
###################################################################################
for dist in ${distros}; do
	echo "/*---------------------------------------------------------------"
	echo "- ${action}  $dist"
	echo "---------------------------------------------------------------*/"
	./submodules/${action}-distro.sh --distro=${dist} \
		--version=${version} --envlist="${envlist}"
	if [ $? -ne 0 ]; then
	    exit 1
	fi
done

echo "${action} distros done!"
