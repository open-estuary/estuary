#!/bin/bash

set -ex

top_dir=$(cd `dirname $0`; cd ..; pwd)
version=$1 # branch or tag
build_dir=$(cd /root/$2 && pwd)
WGET_OPTS="-T 120 -c"

out=${build_dir}/out/release/${version}/OpenSuse
kernel_rpm_dir=${build_dir}/out/kernel-pkg/${version}/opensuse
distro_dir=${build_dir}/tmp/opensuse
kernel_rpm_dir=${build_dir}/out/kernel-pkg/${version}/opensuse
ports_url="http://ftp.neowiz.com/opensuse/ports/"
dvdiso_url=${OPENSUSE_ISO_MIRROR:-"${ports_url}/aarch64/distribution/leap/42.3/iso/"}
opensuse_url=${OPENSUSE_MIRROR:-"http://htsat.vicp.cc:804/opensuse"}
ISO=openSUSE-Leap-42.3-DVD-aarch64-Build0200-Media.iso

if [ -f "${build_dir}/build-opensuse-kernel" ]; then
    build_kernel=true
fi
if [ x"$build_kernel" != x"true" ]; then
    wget -N ${opensuse_url}/
    kernel_abi=`grep  -o -P '(?<=kernel-default-)[0-9].*(?=.aarch64.rpm">)' index.html |tail -1`
    kernel_path=${opensuse_url}
else
    kernel_rpm="kernel-default-[0-9]*.aarch64.rpm"
    kernel_abi=`basename ${kernel_rpm_dir}/${kernel_rpm} | sed -e 's/kernel-default-//g ; s/.aarch64.rpm//g'`
    kernel_path=${kernel_rpm_dir}
fi
rpm -ivh --root=/ ${kernel_path}/kernel-default-${kernel_abi}.aarch64.rpm

# download ISO
iso_dir=/root/iso
mkdir -p ${iso_dir} && cd ${iso_dir}
rm -f ${ISO}.sha256
wget ${dvdiso_url}/${ISO}.sha256 || exit 1
if [ ! -f $ISO ] || ! (sha256sum -c --status ${ISO}.sha256); then
    rm -f $ISO 2>/dev/null
    wget ${WGET_OPTS} ${dvdiso_url}/${ISO} || exit 1
    sha256sum -c --status ${ISO}.sha256 || exit 1
fi

# create the DVD image
mkdir -p ${kernel_rpm_dir} ${out}
if [ x"$build_kernel" != x"true" ]; then
    wget -N ${WGET_OPTS} -r -nd -np -L -A *.aarch64.rpm ${opensuse_url}/ -P ${kernel_rpm_dir}
fi
cd ${distro_dir}; rm -rf dvdiso
xorriso -osirrox on -indev ${iso_dir}/${ISO} -extract / dvdiso
cd dvdiso
rm -f EFI/BOOT/bootaa64.efi boot/aarch64/efi
wget ${WGET_OPTS} -O EFI/BOOT/bootaa64.efi ${opensuse_url}/bootaa64.efi
wget ${WGET_OPTS} -O boot/aarch64/efi ${opensuse_url}/efi

cp /boot/Image-${kernel_abi}-default boot/aarch64/linux
mkdir initrd; cd initrd
sh -c 'xzcat ../boot/aarch64/initrd | cpio -d -i -m -u'
wget ${WGET_OPTS} -O autoinst.xml ${opensuse_url}/autoinst-iso.xml
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

rm -rf suse/aarch64/kernel-*
cp ${kernel_rpm_dir}/kernel-default* suse/aarch64/
rm -rf suse/setup/descr/packages.*
create_package_descr -d suse/ -o suse/setup/descr/  -l english -l german
find . -name "packages*" |xargs gzip -f

# Create the new ISO file.
mksusecd --create ${out}/${ISO} --no-hybrid .
