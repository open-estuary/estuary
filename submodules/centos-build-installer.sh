#!/bin/bash

set -ex

top_dir=$(cd `dirname $0`; cd ..; pwd)
version=$1 # branch or tag
build_dir=$(cd /root/$2 && pwd)

out=${build_dir}/out/release/${version}/centos/netboot
distro_dir=${build_dir}/tmp/centos
workspace=${distro_dir}/installer
out_installer=${workspace}/out
source_url=http://repo.estuarydev.org/releases/5.0/centos/
curl -m 10 -s -o /dev/null http://repo.estuary.cloud
if [ $? -eq 0 ];then
   base_url=http://repo.estuary.cloud/centos/7/os/aarch64/
else
   base_url=http://mirror.centos.org/altarch/7/os/aarch64/
fi

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
  --source=${base_url} \
  --source=${source_url}  \
  --isfinal --nomacboot --noupgrade --buildarch=aarch64 '--volid=CentOS 7 aarch64' netinstall/

# Modify initrd to include a default kickstart (that includes the external repository)
cd netinstall/images/pxeboot/
sudo mkdir initrd; cd initrd
sudo sh -c 'xzcat ../initrd.img | cpio -d -i -m'
cat > /tmp/ks.cfg << EOF
text
url --url="http://mirror.centos.org/altarch/7/os/aarch64/"
repo --name="estuary" --baseurl=${source_url}
network  --bootproto=dhcp --device=eth0 --ipv6=auto --no-activate

%post --interpreter=/bin/bash
yum install -y wget
wget -O /etc/yum.repos.d/estuary.repo https://raw.githubusercontent.com/open-estuary/distro-repo/master/estuaryhttp.repo
chmod +r /etc/yum.repos.d/estuary.repo
rpm --import http://repo.estuarydev.org/releases/ESTUARY-GPG-KEY
yum clean dbcache
%end
EOF
sudo cp /tmp/ks.cfg ks.cfg

cat > /tmp/ks-iso.cfg << EOF
text
network  --bootproto=dhcp --device=eth0 --ipv6=auto --no-activate

%packages
wget
%end

%post --interpreter=/bin/bash
wget -O /etc/yum.repos.d/estuary.repo https://raw.githubusercontent.com/open-estuary/distro-repo/master/estuaryhttp.repo
chmod +r /etc/yum.repos.d/estuary.repo
rpm --import http://repo.estuarydev.org/releases/ESTUARY-GPG-KEY
yum clean dbcache
%end
EOF
sudo cp /tmp/ks-iso.cfg ks-iso.cfg

sudo sh -c 'find . | cpio -o -H newc | xz --check=crc32 --lzma2=dict=512KiB > ../initrd.img'
cd ..; sudo rm -rf initrd

# Rebuild boot.iso
netinstall_dir=${workspace}/centos-installer/netinstall
sed -i 's/vmlinuz.*/& inst.ks=file:\/ks.cfg ip=dhcp/' ${netinstall_dir}/EFI/BOOT/grub.cfg
rm -rf ${netinstall_dir}/images/boot.iso
mkisofs -o ${netinstall_dir}/images/boot.iso -eltorito-alt-boot \
  -e images/efiboot.img -no-emul-boot -R -J -V 'CentOS 7 aarch64' -T \
  -graft-points \
  images/pxeboot=${netinstall_dir}/images/pxeboot \
  LiveOS=${netinstall_dir}/LiveOS \
  EFI/BOOT=${netinstall_dir}/EFI/BOOT \
  images/efiboot.img=${netinstall_dir}/images/efiboot.img


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
