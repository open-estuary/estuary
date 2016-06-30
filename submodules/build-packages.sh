#!/bin/bash

PKG_DIR=packages

PLATFORM=
PKGS=
CROSS_COMPILE=
DISTRO=
ROOTFS=
KERNEL=

###################################################################################
# Const vars
###################################################################################
lastupdate="2015-10-15"
OpenSuse_rc="/etc/rc.d/after.local"
Fedora_rc="/etc/rc.d/rc.local"
Default_rc="/etc/rc.local"

###################################################################################
# build_pcakages_usage
###################################################################################
build_pcakages_usage()
{
cat << EOF
Usage: build-packages.sh --platform=xxx --packages=xxx,xxx --distro=xxx --rootfs=xxx --kernel=xxx
	--platform: which platform to build (D02, D03, HiKey)
	--packages: packages to build
	--distro: distro that the packages will be built for
	--rootfs: target rootfs which the package will be installed into
	--kernel: kernel output directory

Example:
	build-packages.sh --platform=D02 --packages=docker,armor,mysql \\
	--distro=Ubuntu --rootfs=./workspace/distro/Ubuntu --kernel=./workspace/kernel

EOF
}

###################################################################################
# install_pkgs_script <distro> <distro_dir>
###################################################################################
install_pkgs_script()
{
	(
	distro=$1
	distro_dir=$2
	sudo mkdir -p $distro_dir/usr/bin/estuary 2>/dev/null
	rm -f /tmp/post_install.sh 2>/dev/null
	cp estuary/post_install.sh /tmp/
	sed -i "s/lastupdate=.*/lastupdate=\"$lastupdate\"/" /tmp/post_install.sh
	sudo cp /tmp/post_install.sh $rootfs/usr/bin/estuary/
	sudo chmod 755 $distro_dir/usr/bin/estuary/post_install.sh
	eval rc_local_file=\$${distro}_rc
	if [ x"$rc_local_file" = x"" ]; then
		rc_local_file=$Default_rc
	fi
	if ! grep "/usr/bin/estuary/post_install.sh" $distro_dir/$rc_local_file >/dev/null; then
		if grep -E "^(exit)" $distro_dir/$rc_local_file >/dev/null; then
			sudo sed -i "/^exit/i/usr/bin/estuary/post_install.sh" $distro_dir/$rc_local_file
		else
			sudo sed -i '$ a /usr/bin/estuary/post_install.sh' $distro_dir/$rc_local_file
		fi
	fi

	return 0
	)
}

###################################################################################
# build_package <package> <platform> <distro> <rootfs> <kernel>
###################################################################################
build_package()
{
	(
	package=$1
	platform=$2
	distro=$3
	rootfs=$4
	kernel=$5

	pkg_dir=$PKG_DIR/$package
	$pkg_dir/build.sh $platform $distro $rootfs $kernel
	)
}

###################################################################################
# build_packages <packages> <platform> <distro> <rootfs> <kernel>
###################################################################################
build_packages()
{
	(
	packages=($(echo $1 | tr ',' ' '))
	platform=$2
	distro=$3
	rootfs=$(cd $4; pwd)
	kernel=$(cd $5; pwd)

	roofs_topdir=$(cd $rootfs/../; pwd)
	distro_file=${distro}_ARM64.tar.gz
	if [ ! -f $roofs_topdir/$distro_file ]; then
		sudo mkdir -p $rootfs/usr/bin/estuary 2>/dev/null
		for pkg in ${packages[@]}; do
			build_package $pkg $platform $distro $rootfs $kernel
		done

		install_pkgs_script $distro $rootfs
	fi

	return 0
	)
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
                --platform) PLATFORM=$ac_optarg ;;
                --packages) PKGS=$ac_optarg ;;
                --distro) DISTRO=$ac_optarg ;;
                --rootfs) ROOTFS=$ac_optarg ;;
                --kernel) KERNEL=$ac_optarg ;;
                *) echo -e "\033[31mUnknown option $ac_option!\033[0m"
			build_pcakages_usage ; exit 1 ;;
        esac

        shift
done

###################################################################################
# Check args
###################################################################################
if [ x"$PLATFORM" = x"" ] || [ x"$PKGS" = x"" ] \
	|| [ x"$DISTRO" = x"" ] || [ x"$ROOTFS" = x"" ] \
	|| [ x"$KERNEL" = x"" ]; then
		echo "Error! platform: $PLATFORM, distro: $DISTRO, pkgs: $PKGS, kernel: $KERNEL"
        build_pcakages_usage ; exit 1
fi

###################################################################################
# Build packages
###################################################################################
if build_packages $PKGS $PLATFORM $DISTRO $ROOTFS $KERNEL; then
	exit 0
else
	exit 1
fi

