#!/bin/bash
set -ex

top_dir=$(cd `dirname $0`; cd ..; pwd)
version=$1 # branch or tag
build_dir=$(cd /root/$2 && pwd)
WGET_OPTS="-T 120 -c"

out=${build_dir}/out/release/${version}/Fedora
kernel_rpm_dir=${build_dir}/out/kernel-pkg/${version}/fedora
dest_dir=/root/fedora-iso
ISO=Fedora-Server-dvd-aarch64-29_Beta-1.5.iso
http_addr=${FEDORA_ISO_MIRROR:-"ftp://117.78.41.188/utils/distro-binary/fedora"}
FEDORA_ESTUARY_REPO=${FEDORA_ESTUARY_REPO:-"ftp://repoftp:repopushez7411@117.78.41.188/releases/5.2/fedora"}

# Update fedora repo
. ${top_dir}/include/mirror-func.sh
. ${top_dir}/include/checksum-func.sh
wget ${WGET_OPTS} -O /etc/yum.repos.d/estuary.repo ${http_addr}/estuaryftp.repo
chmod +r /etc/yum.repos.d/estuary.repo
set_fedora_mirror
set_docker_loop

# download ISO
rm -rf ${dest_dir}
mkdir -p /root/iso ${kernel_rpm_dir} ${dest_dir}/Packages/extra ${out} ${dest_dir}/images/pxeboot/initrd
cd /root/iso
rm -f ${ISO}.sum
wget ${WGET_OPTS} ${http_addr}/${ISO}.sum || exit 1
if [ ! -f $ISO ] || ! check_sum . ${ISO}.sum; then
    rm -f $ISO 2>/dev/null
    wget ${WGET_OPTS} ${http_addr}/${ISO} || exit 1
    check_sum . ${ISO}.sum || exit 1
fi

# Copy the source media to the working directory.
xorriso -osirrox on -indev ${ISO} -extract / ${dest_dir}

# Change permissions on the working directory.
chmod -R u+w ${dest_dir}
cfg_path="${top_dir}/configs/auto-install/fedora/"
cp -f $cfg_path/auto-iso/grub.cfg ${dest_dir}/EFI/BOOT/grub.cfg

# Download any additional RPMs to the directory structure and update the metadata.
if [ -f "${build_dir}/build-fedora-kernel" ]; then
    build_kernel=true
fi
package_name="kernel kernel-core kernel-cross-headers kernel-devel kernel-headers kernel-modules kernel-modules-extra"
dnf remove -q -y kernel-headers
if [ x"$build_kernel" != x"true" ]; then
    rm -rf ${kernel_rpm_dir}/*
    dnf install -y --downloadonly --downloaddir=${kernel_rpm_dir} --disablerepo=* --enablerepo=Estuary,fedora ${package_name}
fi
cd ${kernel_rpm_dir}
kernel_abi=$(basename kernel-4.18*.rpm | sed -e "s/-estuary.*.rpm//g" -e "s/kernel-//g")
rpm -ivh kernel-core-4.18*.aarch64.rpm kernel-modules-4.18*.aarch64.rpm kernel-4.18*.aarch64.rpm

# Make initrd.img
cd ${dest_dir}/images/pxeboot/initrd
sh -c 'xzcat ../initrd.img | cpio -d -i -m'
cp -f $cfg_path/auto-iso/ks-iso.cfg $cfg_path/auto-pxe/ks.cfg .
sed -i "s/4.16.0/$kernel_abi/g" ks.cfg
rm -rf lib/modules/4.*
cp -rf /lib/modules/* lib/modules/
cp -f /boot/vmlinuz* ${dest_dir}/images/pxeboot/vmlinuz
sh -c 'find . | cpio --quiet -o -H newc --owner 0:0 | xz --threads=0 --check=crc32 -c > ../initrd.img'
cd ..; rm -rf initrd

# Make squashfs.img
cd ${dest_dir}/images
unsquashfs install.img
mount -o loop squashfs-root/LiveOS/rootfs.img /opt
rm -rf /opt/usr/lib/modules/4.* ${dest_dir}/images/install.img
cp -rf /lib/modules/* /opt/usr/lib/modules/
umount /opt
mksquashfs squashfs-root/ ${dest_dir}/images/install.img
rm -rf squashfs-root

# Create repo for packages
for pkg in $package_name; do
    rm -f ${dest_dir}/Packages/k/${pkg}-4*.rpm
    cp -f ${kernel_rpm_dir}/${pkg}-4.18*.rpm ${dest_dir}/Packages/extra/
done
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
cd ${dest_dir} && genisoimage -quiet -e images/efiboot.img -no-emul-boot -T -J -R -c boot.catalog -hide boot.catalog -V "Fedora-S-dvd-aarch64-29" -o ${out}/${ISO} .

# Rebuild boot.iso
if [ x"$build_kernel" != x"true" ]; then
    cp -f $cfg_path/auto-pxe/grub.cfg ${dest_dir}/EFI/BOOT/grub.cfg
    cd ${dest_dir}
    rm -rf Packages repodata temp
    genisoimage -quiet -o ${out}/fedora-netboot.iso -eltorito-alt-boot \
      -e images/efiboot.img -no-emul-boot -R -J -V 'Fedora-S-dvd-aarch64-29' -T \
      -allow-limited-size .
    tar -cf - . | pigz > ${out}/fedora-netboot.tar.gz
fi
