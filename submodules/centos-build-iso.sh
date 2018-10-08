#!/bin/bash

set -ex

top_dir=$(cd `dirname $0`; cd ..; pwd)
version=$1 # branch or tag
build_dir=$(cd /root/$2 && pwd)

. ${top_dir}/include/mirror-func.sh
set_centos_mirror
set_docker_loop

out=${build_dir}/out/release/${version}/CentOS
kernel_rpm_dir=${build_dir}/out/kernel-pkg/${version}/centos
dest_dir=/root/centos-iso
. ${top_dir}/include/checksum-func.sh
rm -rf ${dest_dir}

# download ISO
ISO=CentOS-7-aarch64-Minimal-1804.iso
http_addr=${CENTOS_ISO_MIRROR:-"ftp://117.78.41.188/utils/distro-binary/centos"}
mkdir -p /root/iso && cd /root/iso
rm -f ${ISO}.sum
wget ${http_addr}/${ISO}.sum || exit 1
if [ ! -f $ISO ] || ! check_sum . ${ISO}.sum; then
    rm -f $ISO 2>/dev/null
    wget -T 120 -c ${http_addr}/${ISO} || exit 1
    check_sum . ${ISO}.sum || exit 1
fi

# Create a working directory for your customized media.
mkdir -p ${dest_dir}/temp

# Copy the source media to the working directory.
xorriso -osirrox on -indev ${ISO} -extract / ${dest_dir}

# Change permissions on the working directory.
chmod -R u+w ${dest_dir}
cfg_path="${top_dir}/configs/auto-install/centos/"
cp -f $cfg_path/auto-iso/grub.cfg ${dest_dir}/EFI/BOOT/grub.cfg

# Download any additional RPMs to the directory structure and update the metadata.
mkdir -p ${kernel_rpm_dir}
if [ -f "${build_dir}/build-centos-kernel" ]; then
    build_kernel=true
fi
if [ x"$build_kernel" != x"true" ]; then
    package_name="kernel kernel-devel kernel-headers kernel-tools kernel-tools-libs kernel-tools-libs-devel perf python-perf"
    yum install -q --downloadonly --downloaddir=${kernel_rpm_dir} --disablerepo=* --enablerepo=Estuary ${package_name}
fi
yum remove -y wget epel-release
yum install -q --downloadonly --downloaddir=${kernel_rpm_dir}  epel-release wget bash-completion
kernel_abi=$(basename -a ${kernel_rpm_dir}/kernel-4*.aarch64.rpm | tail -1 | sed -e 's/kernel-//g ; s/.aarch64.rpm//g')
yum install -q -y ${kernel_rpm_dir}/kernel-${kernel_abi}.aarch64.rpm
cp -f /boot/vmlinuz-${kernel_abi}.aarch64 ${dest_dir}/images/pxeboot/vmlinuz

# Make initrd.img
cd ${dest_dir}/images/pxeboot
mkdir initrd; cd initrd
sh -c 'xzcat ../initrd.img | cpio -d -i -m'
cp -f $cfg_path/auto-iso/ks-iso.cfg .
cp -f $cfg_path/auto-pxe/ks.cfg .
rm -rf lib/modules/4.*
cp -rf /lib/modules/${kernel_abi}.aarch64 lib/modules/
sh -c 'find . | cpio --quiet -o -H newc --owner 0:0 | xz --threads=0 --check=crc32 -c > ../initrd.img'
cd ..; rm -rf initrd

# Make squashfs.img
cd ${dest_dir}/LiveOS
unsquashfs squashfs.img
mount -o loop squashfs-root/LiveOS/rootfs.img /opt
rm -rf /opt/usr/lib/modules/4.* ${dest_dir}/LiveOS/squashfs.img
cp -rf /lib/modules/${kernel_abi}.aarch64 /opt/usr/lib/modules/
umount /opt
mksquashfs squashfs-root/ ${dest_dir}/LiveOS/squashfs.img
rm -rf squashfs-root

# createrepo for kernel packages
cp ${kernel_rpm_dir}/*.rpm ${dest_dir}/Packages
cd ${dest_dir}
xmlfile=`basename repodata/*comps.xml`
cd repodata
mv $xmlfile comps.xml
shopt -s extglob
rm -f !(comps.xml)
find . -name TRANS.TBL|xargs rm -f
cd ${dest_dir}
createrepo -q -g repodata/comps.xml .

# Create the new ISO file.
mkdir -p ${out}
mkisofs -quiet -o ${out}/centos-everything-${version}.iso -eltorito-alt-boot \
        -e images/efiboot.img -no-emul-boot -R -J -V 'CentOS 7 aarch64' -T ${dest_dir}

# Rebuild boot.iso
if [ x"$build_kernel" != x"true" ]; then
    cp -f $cfg_path/auto-pxe/grub.cfg ${dest_dir}/EFI/BOOT/grub.cfg
    mkisofs -quiet -o ${out}/centos-netboot-${version}.iso -eltorito-alt-boot \
        -e images/efiboot.img -no-emul-boot -R -J -V 'CentOS 7 aarch64' -T \
        -graft-points \
        images/pxeboot=${dest_dir}/images/pxeboot \
        LiveOS=${dest_dir}/LiveOS \
        EFI/BOOT=${dest_dir}/EFI/BOOT \
        images/efiboot.img=${dest_dir}/images/efiboot.img
    cd ${dest_dir}
    rm -rf Packages repodata temp
    tar -cf - . | pigz > ${out}/centos-netboot-${version}.tar.gz
fi
