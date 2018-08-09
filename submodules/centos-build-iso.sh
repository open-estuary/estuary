#!/bin/bash

set -ex

top_dir=$(cd `dirname $0`; cd ..; pwd)
version=$1 # branch or tag
build_dir=$(cd /root/$2 && pwd)

. ${top_dir}/include/mirror-func.sh
set_centos_mirror
yum remove epel-release -y
set_docker_loop

out=${build_dir}/out/release/${version}/CentOS
distro_dir=${build_dir}/tmp/centos
cdrom_installer_dir=${distro_dir}/installer/out/images/pxeboot
live_os_dir=${distro_dir}/installer/out/LiveOS
kernel_rpm_dir=${build_dir}/out/kernel-pkg/${version}/centos
dest_dir=/root/centos-iso
. ${top_dir}/include/checksum-func.sh
rm -rf ${dest_dir}

# download ISO
ISO=CentOS-7-aarch64-Everything.iso
http_addr=${CENTOS_ISO_MIRROR:-"http://open-estuary.org/download/AllDownloads/FolderNotVisibleOnWebsite/EstuaryInternalConfig/linux/CentOS"}
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
mount -o loop ${ISO} /opt
pushd /opt
tar cf - . | (cd ${dest_dir}; tar xf -)
popd
umount /opt

# Replace estuary binary for customized media.
cd ${cdrom_installer_dir}
cp initrd.img vmlinuz ${dest_dir}/images/pxeboot
cd ${live_os_dir}
cp squashfs.img ${dest_dir}/LiveOS

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
yum install -q --downloadonly --downloaddir=${kernel_rpm_dir} --disablerepo=* --enablerepo=extras epel-release

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
cd ${dest_dir} && mkisofs -quiet -o ${out}/${ISO} -eltorito-alt-boot -e images/efiboot.img -no-emul-boot -R -J -V 'CentOS 7 aarch64' -T .
