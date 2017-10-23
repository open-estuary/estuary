#!/bin/bash

set -ex

yum install genisoimage -y

top_dir=$(cd `dirname $0`; cd ..; pwd)
version=$1 # branch or tag
build_dir=$(cd /root/$2 && pwd)

out=${build_dir}/out/release/${version}/centos
distro_dir=${build_dir}/tmp/centos
cdrom_installer_dir=${distro_dir}/installer/out/images/pxeboot
live_os_dir=${distro_dir}/installer/out/LiveOS
kernel_rpm_dir=${build_dir}/out/kernel-pkg/${version}/centos
source_dir=/root/bootiso
dest_dir=/root/bootisoks
. ${top_dir}/include/checksum-func.sh
rm -rf ${source_dir} ${dest_dir}

# download ISO
ISO=CentOS-7-aarch64-Everything.iso
http_addr=http://open-estuary.org/download/AllDownloads/FolderNotVisibleOnWebsite/EstuaryInternalConfig/linux/CentOS
iso_dir=/root/iso
mkdir -p ${iso_dir} && cd ${iso_dir}
if [ ! -f ${ISO}.sum ]; then
    wget ${http_addr}/${ISO}.sum || exit 1
fi
if [ ! -f $ISO ] || ! check_sum . ${ISO}.sum; then
    rm -f $ISO 2>/dev/null
    wget -T 120 -c ${http_addr}/${ISO} || exit 1
    check_sum . ${ISO}.sum || exit 1
fi

# Create a directory to mount your source.
mkdir -p ${source_dir}
mount -o loop ${ISO} ${source_dir}

# Create a working directory for your customized media.
mkdir -p ${dest_dir}

# Copy the source media to the working directory.
cp -r ${source_dir}/* ${dest_dir}

# Unmount the source ISO and remove the directory.
umount ${source_dir} && rmdir ${source_dir}

# Replace estuary binary for customized media.
cd ${cdrom_installer_dir}
cp initrd.img vmlinuz ${dest_dir}/images/pxeboot
cd ${live_os_dir}
cp squashfs.img ${dest_dir}/LiveOS

# Change permissions on the working directory.
chmod -R u+w ${dest_dir}

# Download any additional RPMs to the directory structure and update the metadata.
rm -rf ${kernel_rpm_dir} && mkdir -p ${kernel_rpm_dir}
sudo wget -O /etc/yum.repos.d/estuary.repo https://raw.githubusercontent.com/open-estuary/distro-repo/master/estuaryftp.repo
sudo chmod +r /etc/yum.repos.d/estuary.repo
sudo rpm --import http://repo.estuarydev.org/releases/ESTUARY-GPG-KEY
yum clean dbcache
package_name="kernel kernel-devel kernel-headers kernel-tools kernel-tools-libs kernel-tools-libs-devel perf python-perf"
yum install --downloadonly --downloaddir=${kernel_rpm_dir} --disablerepo=* --enablerepo=Estuary ${package_name}

cp ${kernel_rpm_dir}/*.rpm ${dest_dir}/Packages
cd ${dest_dir}
xmlfile=`basename repodata/*comps.xml`
cd repodata
mv $xmlfile comps.xml
shopt -s extglob
rm -f !(comps.xml)
find . -name TRANS.TBL|xargs rm -f
cd ${dest_dir}
createrepo -g repodata/comps.xml .


# Create the new ISO file.
cd ${dest_dir} && genisoimage -e images/efiboot.img -no-emul-boot -T -J -R -c boot.catalog -hide boot.catalog -hide efiboot.img -V "CentOS 7 aarch64" -o ${out}/${ISO} .

# Publish
cd ${out}
mv netboot/images/boot.iso .
tar -czvf netboot.tar.gz netboot/

# Clean
rm -rf netboot/
rm -rf ${dest_dir} 
