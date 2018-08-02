#!/bin/bash

set -ex

version=$1 # branch or tag
build_dir=$(cd /root/$2 && pwd)
WGET_OPTS="-T 120 -c -q"

out=${build_dir}/out/release/${version}/OpenSuse
release_dir=${build_dir}/out/release/${version}/OpenSuse/netboot
workspace=${build_dir}/tmp/opensuse/installer
leap_path=ports/aarch64/distribution/leap/15.0
official_url=http://ftp.neowiz.com/opensuse/${leap_path}
netiso_url=${OPENSUSE_ISO_MIRROR:-"${official_url}/iso"}
config_url=ftp://117.78.41.188/utils/distro-binary/opensuse
private_url=${OPENSUSE_MIRROR:-"${config_url}"}
ISO=openSUSE-Leap-15.0-NET-aarch64-Build124.1-Media.iso

if [ -f "${build_dir}/build-opensuse-kernel" ]; then
    exit 0
fi
wget -N ${private_url}/
kernel_abi=`grep  -o -P '(?<=kernel-default-)[0-9].*(?=.aarch64.rpm">)' index.html |tail -1`
rpm -ivh --root=/  ${private_url}/kernel-default-${kernel_abi}.aarch64.rpm
rm -rf ${workspace}
mkdir -p ${workspace} && cd ${workspace}
mkdir -p opensuse-installer

# download ISO
iso_dir=/root/iso
mkdir -p ${iso_dir} && cd ${iso_dir}
rm -f ${ISO}.sha256
wget ${netiso_url}/${ISO}.sha256 || exit 1
if [ ! -f $ISO ] || ! (sha256sum -c --status ${ISO}.sha256); then
    rm -f $ISO 2>/dev/null
    wget ${WGET_OPTS} ${netiso_url}/${ISO} || exit 1
    sha256sum -c --status ${ISO}.sha256 || exit 1
fi

# create the netinstall image
cd ${workspace}/opensuse-installer; rm -rf netinstall
xorriso -osirrox on -indev ${iso_dir}/${ISO} -extract / netinstall
cd netinstall
sed -i "s#silent.*#& install=${official_url}/repo/oss ifcfg=eth*=dhcp#" EFI/BOOT/grub.cfg
cp /boot/Image-${kernel_abi}-default boot/aarch64/linux
mkdir initrd; cd initrd
wget ${WGET_OPTS} ${private_url}/autoinst-15.0.xml -O autoinst.xml
defined_abi=`grep  -o -P '(?<=kernel-default-)[0-9].*(?=.aarch64.rpm)' autoinst.xml`
sed -i "s/${defined_abi}/${kernel_abi}/" autoinst.xml
sh -c 'xzcat ../boot/aarch64/initrd | cpio -d -i -m -u'
rm -rf modules lib/modules/*
mkdir -p lib/modules/${kernel_abi}-default/initrd
ln -sf lib/modules/${kernel_abi}-default/initrd modules
find /lib/modules/${kernel_abi}-default -name "loop.ko"|xargs -i cp -v {} modules/
find /lib/modules/${kernel_abi}-default -name "squashfs.ko"|xargs -i cp -v {} modules/
cp -rf /lib/modules/${kernel_abi}-default lib/modules/
sh -c 'find . | cpio --quiet -o -H newc --owner 0:0 | xz --threads=0 --check=crc32 -c > ../boot/aarch64/initrd'
cd ..; rm -rf initrd

filename="control.xml bind common config gdb libstoragemgmt rescue root cracklib-dict-full.rpm"
for file in ${filename}; do
    wget ${WGET_OPTS} ${private_url}/${leap_path}/repo/oss/boot/aarch64/${file} -P boot/aarch64/
done

mkisofs  -R -o boot.iso -b boot/aarch64/efi -no-emul-boot .

# Final preparation for publishing
mkdir -p ${release_dir}
cp -rf ${workspace}/opensuse-installer/netinstall/* ${release_dir}

# Publish
cd ${out}
mv netboot/boot.iso .
tar -czvf netboot.tar.gz netboot/

# Clean
rm -rf netboot/
