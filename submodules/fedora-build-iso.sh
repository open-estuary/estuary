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

# Replace estuary binary for customized media.
cd ${cdrom_installer_dir}
cp initrd.img vmlinuz ${dest_dir}/images/pxeboot
cd ${live_os_dir}
cp install.img ${dest_dir}/images

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
if [ x"$build_kernel" != x"true" ]; then
    dnf install -y --downloadonly --downloaddir=${kernel_rpm_dir} --disablerepo=* --enablerepo=Estuary,fedora ${package_name}
fi

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
cd ${dest_dir} && genisoimage -quiet -e images/efiboot.img -no-emul-boot -T -J -R -c boot.catalog -hide boot.catalog -V "Fedora-S-dvd-aarch64-28" -o ${out}/${ISO} .
