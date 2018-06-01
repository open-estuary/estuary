#!/bin/bash

set -ex

top_dir=$(cd `dirname $0`; cd ..; pwd)
version=$1 # branch or tag
build_dir=$(cd /root/$2 && pwd)
WGET_OPTS="-T 120 -c"

out=${build_dir}/out/release/${version}/OpenSuse
release_dir=${build_dir}/out/release/${version}/OpenSuse/netboot
distro_dir=${build_dir}/tmp/opensuse
workspace=${distro_dir}/installer
ports_url="http://ftp.neowiz.com/opensuse/ports/"
netiso_url=${OPENSUSE_ISO_MIRROR:-"${ports_url}/aarch64/distribution/leap/42.3/iso/"}
opensuse_url=${OPENSUSE_MIRROR:-"http://htsat.vicp.cc:804/opensuse"}
ISO=openSUSE-Leap-42.3-NET-aarch64-Build0200-Media.iso

kernel_abi="4.16.3-0.gd41301c"
rpm -ivh --root=/  ${opensuse_url}/kernel-default-${kernel_abi}.aarch64.rpm
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
sed -i 's/silent.*/& autoyast=http:\/\/htsat.vicp.cc:804\/opensuse\/autoinst.xml ifcfg=eth*=dhcp/' EFI/BOOT/grub.cfg
rm -f EFI/BOOT/bootaa64.efi boot/aarch64/efi
wget ${WGET_OPTS} -O EFI/BOOT/bootaa64.efi ${opensuse_url}/bootaa64.efi
wget ${WGET_OPTS} -O boot/aarch64/efi ${opensuse_url}/efi

cp /boot/Image-${kernel_abi}-default boot/aarch64/linux
mkdir initrd; cd initrd
sh -c 'xzcat ../boot/aarch64/initrd | cpio -d -i -m -u'
sed -i "s#http://download.opensuse.org/#${ports_url}/aarch64/#g" linuxrc.config
sed -i "s#http://download.opensuse.org/ports/#${ports_url}#g" etc/YaST2/control.xml
rm -rf modules
mkdir -p lib/modules/${kernel_abi}-default/initrd
ln -sf lib/modules/${kernel_abi}-default/initrd modules
find /lib/modules/${kernel_abi}-default -name "loop.ko"|xargs -i cp -v {} modules/
find /lib/modules/${kernel_abi}-default -name "squashfs.ko"|xargs -i cp -v {} modules/
cp -rvf /lib/modules/${kernel_abi}-default lib/modules/
sh -c 'find . | cpio -o -H newc | xz --check=crc32 --lzma2=dict=512KiB > ../boot/aarch64/initrd'
cd ..; rm -rf initrd

mkisofs  -R -o boot.iso -b boot/aarch64/efi -c boot.catalog -no-emul-boot .

# Final preparation for publishing
mkdir -p ${release_dir}
cp -rf ${workspace}/opensuse-installer/netinstall/* ${release_dir}

# Publish
cd ${out}
mv netboot/boot.iso .
wget ${WGET_OPTS} ${opensuse_url}/autoinst.xml -O netboot/autoinst.xml
tar -czvf netboot.tar.gz netboot/

# Clean
rm -rf netboot/
