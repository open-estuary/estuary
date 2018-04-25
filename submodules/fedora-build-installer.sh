#!/bin/bash
set -ex

top_dir=$(cd `dirname $0`; cd ..; pwd)
version=$1 # branch or tag
build_dir=$(cd /root/$2 && pwd)

out=${build_dir}/out/release/${version}/Fedora/netboot
distro_dir=${build_dir}/tmp/fedora
workspace=${distro_dir}/installer
out_installer=${workspace}/out
source_url=${FEDORA_ESTUARY_REPO:-"ftp://repoftp:repopushez7411@117.78.41.188/releases/5.1/fedora"}
base_url=${FEDORA_MIRROR:-"http://dl.fedoraproject.org/pub/fedora-secondary"}/releases/26/Everything/aarch64/os/

rm -rf ${workspace}
mkdir -p ${workspace} && cd ${workspace}
mkdir -p fedora-installer

# Update fedora repo
. ${top_dir}/include/mirror-func.sh
set_fedora_mirror

# Install build tools and fix dependence problem
dnf install -y yum-plugin-ovl
dnf install -y cpio lorax python-requests xz createrepo libselinux-utils hfsplus-tools

sed -i 's#"setfiles",#"setfiles","-e","/usr/lib/systemd",#g' /usr/lib/python3.6/site-packages/pylorax/imgutils.py
seq 0 7 | xargs -I {} mknod -m 660 /dev/loop{} b 7 {} || true
chgrp disk /dev/loop[0-7]

# Call lorax to create the netinstall image
cd fedora-installer
rm -rf netinstall
lorax '--product=Fedora' --version=26 --release=26 \
  --source=${base_url} \
  --source=${source_url} \
  --isfinal --nomacboot --noupgrade --buildarch=aarch64 '--volid=Fedora-S-dvd-aarch64-26' netinstall/


# Modify initrd to include a default kickstart (that includes the external repository)
cd netinstall/images/pxeboot/
mkdir initrd; cd initrd
sh -c 'xzcat ../initrd.img | cpio -d -i -m'
cat > /tmp/ks.cfg << EOF
url --url="http://dl.fedoraproject.org/pub/fedora-secondary/releases/26/Everything/aarch64/os/"
repo --name="estuary" --baseurl=${source_url}
text

%packages
bash-completion
wget
%end

%post --interpreter=/bin/bash
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config || true
%end

EOF
cp /tmp/ks.cfg ks.cfg
sed '1,2d' ks.cfg > ks-iso.cfg

sh -c 'find . | cpio -o -H newc | xz --check=crc32 --lzma2=dict=512KiB > ../initrd.img'
cd ..; rm -rf initrd

# Rebuild boot.iso
netinstall_dir=${workspace}/fedora-installer/netinstall
sed -i 's/vmlinuz.*/& inst.ks=file:\/ks.cfg ip=dhcp/' ${netinstall_dir}/EFI/BOOT/grub.cfg
rm -rf ${netinstall_dir}/images/boot.iso
mkisofs -o ${netinstall_dir}/images/boot.iso -eltorito-alt-boot \
  -e images/efiboot.img -no-emul-boot -R -J -V 'Fedora-S-dvd-aarch64-26' -T \
  -graft-points \
  images/pxeboot=${netinstall_dir}/images/pxeboot \
  EFI/BOOT=${netinstall_dir}/EFI/BOOT \
  images/efiboot.img=${netinstall_dir}/images/efiboot.img \
  images/install.img=${netinstall_dir}/images/install.img

# Final preparation for publishing
mkdir -p ${out_installer} && mkdir -p ${out}
cd ${workspace}/fedora-installer
cp -rf lorax.log netinstall/.discinfo netinstall/.treeinfo netinstall/EFI netinstall/images ${out_installer}
cp -rf  ${out_installer}/* ${out}

# Publish
out=${build_dir}/out/release/${version}/Fedora
cd ${out}
mv netboot/images/boot.iso .
tar -czvf netboot.tar.gz netboot/

# Clean
rm -rf netboot/
