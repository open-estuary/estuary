#!/bin/bash

set -ex

top_dir=$(cd `dirname $0`; cd ..; pwd)
version=$1 # branch or tag
build_dir=$(cd /root/$2 && pwd)

out=${build_dir}/out/release/${version}/centos/netboot
distro_dir=${build_dir}/tmp/centos
workspace=${distro_dir}/installer
out_installer=${workspace}/out

rm -rf ${workspace}
mkdir -p ${workspace} && cd ${workspace}
mkdir -p centos-installer

# Make sure the base image is updated to 7.4.1708
sudo sed -i 's/\$releasever/7.4.1708/g' /etc/yum.repos.d/CentOS-Base.repo

sudo yum makecache -y
sudo yum install -y cpio lorax python-requests wget xz createrepo

# Call lorax to create the netinstall image
cd centos-installer
sudo rm -rf netinstall
sudo lorax '--product=CentOS Linux' --version=7 --release=7.4.1708 \
  --source=http://mirror.centos.org/altarch/7/os/aarch64/ \
  --source=ftp://repoftp:repopushez7411@117.78.41.188/releases/5.0/centos/ \
  --isfinal --nomacboot --noupgrade --buildarch=aarch64 '--volid=CentOS 7 aarch64' netinstall/

# Modify initrd to include a default kickstart (that includes the external repository)
cd netinstall/images/pxeboot/
sudo mkdir initrd; cd initrd
sudo sh -c 'xzcat ../initrd.img | cpio -d -i -m'
cat > /tmp/ks.cfg << EOF
repo --name="estuary" --baseurl=ftp://repoftp:repopushez7411@117.78.41.188/releases/5.0/centos/
EOF
sudo cp /tmp/ks.cfg ks.cfg
sudo sh -c 'find . | cpio -o -H newc | xz --check=crc32 --lzma2=dict=512KiB > ../initrd.img'
cd ..; sudo rm -rf initrd

# Final preparation for publishing
mkdir -p ${out_installer} && mkdir -p ${out}
cd ${workspace}/centos-installer
cp -rf lorax.log netinstall/.discinfo netinstall/.treeinfo netinstall/EFI netinstall/images netinstall/LiveOS ${out_installer}
cp -rf  ${out_installer}/* ${out}

# Build information
KERNEL_VERSION=`cat ${out}/images/pxeboot/vmlinuz | gzip -d - | grep -a "Linux version"`
cat > ${out}/HEADER.textile << EOF

h4. Reference Platform - CentOS Installer

CentOS Installer (7) produced with the Reference Platform Kernel package.

Check "https://platforms.linaro.org/documentation/Reference-Platform/Platforms/Enterprise/Documentation/Installation/Centos/README.md":https://platforms.linaro.org/documentation/Reference-Platform/Platforms/Enterprise/Documentation/Installation/Centos/README.md for the install instructions.

Build Description:
* Kernel: $KERNEL_VERSION
EOF
