#!/bin/bash
set -ex

top_dir=$(cd `dirname $0`; cd ..; pwd)
version=$1 # branch or tag
build_dir=$(cd /root/$2 && pwd)
WGET_OPTS="-T 120 -c"

out=${build_dir}/out/release/${version}/Fedora
kernel_rpm_dir=${build_dir}/out/kernel-pkg/${version}/fedora
distro_dir=${build_dir}/tmp/fedora
cdrom_installer_dir=${distro_dir}/installer/out/images/pxeboot
live_os_dir=${distro_dir}/installer/out/images
kernel_rpm_dir=${build_dir}/out/kernel-pkg/${version}/fedora
dest_dir=/root/fedora-iso
ISO=Fedora-Server-dvd-aarch64-28-1.1.iso
http_addr=${FEDORA_ISO_MIRROR:-"ftp://117.78.41.188/utils/distro-binary/fedora"}
rm -rf ${dest_dir}

# Update fedora repo
. ${top_dir}/include/mirror-func.sh
. ${top_dir}/include/checksum-func.sh
wget ${WGET_OPTS} -O /etc/yum.repos.d/estuary.repo ${http_addr}/estuaryftp.repo
chmod +r /etc/yum.repos.d/estuary.repo
set_fedora_mirror
set_docker_loop

# download ISO
mkdir -p /root/iso ${dest_dir} && cd /root/iso
rm -f ${ISO}.sum
wget ${WGET_OPTS} ${http_addr}/${ISO}.sum || exit 1
if [ ! -f $ISO ] || ! check_sum . ${ISO}.sum; then
    rm -f $ISO 2>/dev/null
    wget ${WGET_OPTS} ${http_addr}/${ISO} || exit 1
    check_sum . ${ISO}.sum || exit 1
fi

# Copy the source media to the working directory.
mount -o loop ${ISO} /opt
pushd /opt
tar cf - . | (cd ${dest_dir}; tar xf -)
popd
umount /opt

# Change permissions on the working directory.
chmod -R u+w ${dest_dir}
cfg_path="${top_dir}/configs/auto-install/fedora/"
cp -f $cfg_path/auto-iso/grub.cfg ${dest_dir}/EFI/BOOT/grub.cfg

# Download any additional RPMs to the directory structure and update the metadata.
mkdir -p ${kernel_rpm_dir}
if [ -f "${build_dir}/build-fedora-kernel" ]; then
    build_kernel=true
fi

package_name="kernel kernel-core kernel-cross-headers kernel-devel kernel-headers kernel-modules kernel-modules-extra"
dnf remove -q -y kernel-headers
if [ x"$build_kernel" != x"true" ]; then
    dnf install -y --downloadonly --downloaddir=/tmp --disablerepo=* --enablerepo=Estuary,fedora ${package_name}
    cp -rf /tmp/*.rpm ${kernel_rpm_dir}
else
    cp -rf ${kernel_rpm_dir}/* /tmp
fi
kernel_abi=$(basename -a ${kernel_rpm_dir}/kernel-4*.aarch64.rpm | tail -1 | sed -e 's/kernel-//g ; s/.aarch64.rpm//g')
dnf install -q -y /tmp/kernel-core-${kernel_abi}.aarch64.rpm
dnf install -q -y /tmp/kernel-modules-${kernel_abi}.aarch64.rpm
dnf install -q -y /tmp/kernel-${kernel_abi}.aarch64.rpm
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
cd ${dest_dir}/images
unsquashfs install.img
mount -o loop squashfs-root/LiveOS/rootfs.img /opt
rm -rf /opt/usr/lib/modules/4.* ${dest_dir}/images/install.img
cp -rf /lib/modules/${kernel_abi}.aarch64 /opt/usr/lib/modules/
umount /opt
mksquashfs squashfs-root/ ${dest_dir}/images/install.img
rm -rf squashfs-root

rm -rf ${dest_dir}/Packages/k/kernel*4.[0-9][0-9].[0-9]*.rpm
mkdir -p ${dest_dir}/Packages/extra
cp -f ${kernel_rpm_dir}/*.rpm ${dest_dir}/Packages/extra/
cd ${dest_dir}
xmlfile=`basename repodata/*comps*.xml`
cd repodata
mv $xmlfile comps.xml
shopt -s extglob
rm -f !(comps.xml)
find . -name TRANS.TBL|xargs rm -f
cd ${dest_dir}
createrepo -q -g repodata/comps.xml .


# Create the new ISO file.
mkdir -p ${out}
cd ${dest_dir} && genisoimage -quiet -e images/efiboot.img -no-emul-boot -T -J -R -c boot.catalog -hide boot.catalog -V "Fedora-S-dvd-aarch64-28" -o ${out}/${ISO} .

# Rebuild boot.iso
if [ x"$build_kernel" != x"true" ]; then
    cp -f $cfg_path/auto-pxe/grub.cfg ${dest_dir}/EFI/BOOT/grub.cfg
    cd ${dest_dir}
    rm -rf Packages repodata temp
    genisoimage -quiet -o ${out}/boot.iso -eltorito-alt-boot \
      -e images/efiboot.img -no-emul-boot -R -J -V 'Fedora-S-dvd-aarch64-28' -T \
      -allow-limited-size .
    tar -cf - . | pigz > ${out}/netboot.tar.gz
fi
