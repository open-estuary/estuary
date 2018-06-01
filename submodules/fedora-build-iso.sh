#!/bin/bash
set -ex

top_dir=$(cd `dirname $0`; cd ..; pwd)
version=$1 # branch or tag
build_dir=$(cd /root/$2 && pwd)
WGET_OPTS="-T 120 -c"

out=${build_dir}/out/release/${version}/Fedora
distro_dir=${build_dir}/tmp/fedora
cdrom_installer_dir=${distro_dir}/installer/out/images/pxeboot
live_os_dir=${distro_dir}/installer/out/images
kernel_rpm_dir=${build_dir}/out/kernel-pkg/${version}/fedora
dest_dir=/root/fedora-iso
rm -rf ${dest_dir}

# Update fedora repo
. ${top_dir}/include/mirror-func.sh
. ${top_dir}/include/checksum-func.sh
set_fedora_mirror


# download ISO
ISO=Fedora-Server-dvd-aarch64-26-1.5.iso
http_addr=${FEDORA_ISO_MIRROR:-"http://htsat.vicp.cc:804/fedora"}
iso_dir=/root/iso
mkdir -p ${iso_dir} && cd ${iso_dir}
rm -f ${ISO}.sum
wget ${WGET_OPTS} ${http_addr}/${ISO}.sum || exit 1
if [ ! -f $ISO ] || ! check_sum . ${ISO}.sum; then
    rm -f $ISO 2>/dev/null
    wget ${WGET_OPTS} ${http_addr}/${ISO} || exit 1
    check_sum . ${ISO}.sum || exit 1
fi

# Create a working directory for your customized media.
mkdir -p ${dest_dir}/temp

# Copy the source media to the working directory.
xorriso -osirrox on -indev ${ISO} -extract / ${dest_dir}

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
rm -rf ${kernel_rpm_dir} && mkdir -p ${kernel_rpm_dir}
wget ${WGET_OPTS} -O /etc/yum.repos.d/estuary.repo ${http_addr}/estuaryftp.repo
chmod +r /etc/yum.repos.d/estuary.repo
dnf clean dbcache
package_name="kernel kernel-core kernel-cross-headers kernel-devel kernel-headers kernel-modules kernel-modules-extra"
dnf install -y --downloadonly --downloaddir=${kernel_rpm_dir} --disablerepo=* --enablerepo=Estuary,fedora ${package_name}

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
createrepo -g repodata/comps.xml .


# Create the new ISO file.
cd ${dest_dir} && genisoimage -e images/efiboot.img -no-emul-boot -T -J -R -c boot.catalog -hide boot.catalog -V "Fedora-S-dvd-aarch64-26" -o ${out}/${ISO} .

# Clean
rm -rf ${dest_dir} 
