#!/bin/bash

set -ex

top_dir=$(cd `dirname $0`; cd ..; pwd)
version=$1 # branch or tag
build_dir=$(cd /root/$2 && pwd)
WGET_OPTS="-T 120 -c -q"

out=${build_dir}/out/release/${version}/OpenSuse
kernel_rpm_dir=${build_dir}/out/kernel-pkg/${version}/opensuse
dvdiso_dir=${build_dir}/tmp/opensuse/dvdiso
official_url=http://download.opensuse.org
leap_path=ports/aarch64/distribution/leap/15.0
config_url=ftp://117.78.41.188/utils/distro-binary/opensuse
dvdiso_url=${OPENSUSE_ISO_MIRROR:-"${official_url}/ports/aarch64/distribution/leap/15.0/iso"}
private_url=${OPENSUSE_MIRROR:-"${config_url}"}
ISO=openSUSE-Leap-15.0-DVD-aarch64-Build124.1-Media.iso

. ${top_dir}/include/mirror-func.sh
set_docker_loop

if [ -f "${build_dir}/build-opensuse-kernel" ]; then
    build_kernel=true
fi
if [ x"$build_kernel" != x"true" ]; then
    wget -N ${private_url}/
    kernel_abi=`grep  -o -P '(?<=kernel-default-)[0-9].*(?=.aarch64.rpm">)' index.html |tail -1`
    kernel_path=${private_url}
else
    kernel_rpm="kernel-default-[0-9]*.aarch64.rpm"
    kernel_abi=`basename ${kernel_rpm_dir}/${kernel_rpm} | sed -e 's/kernel-default-//g ; s/.aarch64.rpm//g'`
    kernel_path=${kernel_rpm_dir}
fi
rpm -ivh --root=/ ${kernel_path}/kernel-default-${kernel_abi}.aarch64.rpm 2>/dev/null

# download ISO
iso_dir=/root/iso
mkdir -p ${iso_dir} && cd ${iso_dir}
wget -N ${dvdiso_url}/${ISO}.sha256 || exit 1
if [ ! -f $ISO ] || ! (sha256sum -c --status ${ISO}.sha256); then
    wget -N ${WGET_OPTS} ${dvdiso_url}/${ISO} || exit 1
    sha256sum -c --status ${ISO}.sha256 || exit 1
fi

# create the DVD image
mkdir -p ${kernel_rpm_dir} ${out}
if [ x"$build_kernel" != x"true" ]; then
    wget -N ${WGET_OPTS} -r -nd -np -L -A *.aarch64.rpm ${private_url}/ -P ${kernel_rpm_dir}
fi
rm -rf ${dvdiso_dir}; mkdir -p ${dvdiso_dir}
xorriso -osirrox on -indev ${ISO} -extract / ${dvdiso_dir}
cd ${dvdiso_dir}

cp /boot/Image-${kernel_abi}-default boot/aarch64/linux
mkdir initrd; cd initrd
sh -c 'xzcat ../boot/aarch64/initrd | cpio -d -i -m -u'
wget ${WGET_OPTS} -O autoinst.xml ${private_url}/autoinst-iso-15.0.xml
rm -rf modules lib/modules/*
cp -rf /lib/modules/${kernel_abi}-default lib/modules/
sh -c 'find . | cpio --quiet -o -H newc --owner 0:0 | xz --check=crc32 -c --threads=0 > ../boot/aarch64/initrd'
cd ..; rm -rf initrd

rm -rf aarch64/kernel-* repodata
cp ${kernel_rpm_dir}/kernel-default* aarch64/
mkdir -p suse
mv aarch64 noarch suse/
create_package_descr -d suse/ -o suse/setup/descr/  -l english -l german
find suse/setup/descr/ -name "packages*" |xargs gzip -f
touch content

# Create the new ISO file.
mksusecd --create ${out}/${ISO} --no-hybrid .
if [ x"$build_kernel" != x"true" ]; then
    mksusecd --boot "autoyast=${config_url}/autoinst-15.0.xml install=${config_url}/${leap_path}/repo/oss ifcfg=eth*=dhcp" --micro --create ${out}/boot.iso --no-hybrid .
    xorriso -osirrox on -indev ${out}/boot.iso -extract / netboot
    tar -cf - netboot/ | pigz > ${out}/netboot.tar.gz
    rm -rf netboot/
fi
