#!/bin/bash

set -ex

top_dir=$(cd `dirname $0`; cd ..; pwd)
version=$1 # branch or tag
build_dir=$(cd /root/$2 && pwd)

out=${build_dir}/out/release/${version}/Debian
distro_dir=${build_dir}/tmp/debian
cdrom_installer_dir=${distro_dir}/installer/out/images
workspace=${distro_dir}/simple-cdd

# set mirror
. ${top_dir}/include/mirror-func.sh
set_debian_mirror


mirror=${DEBIAN_MIRROR:-http://ftp.jp.debian.org/debian/}
securiry_mirror=${DEBIAN_SECURITY_MIRROR:-http://security.debian.org/}
estuary_repo=${DEBIAN_ESTUARY_REPO:-"http://repo.estuarydev.org/releases/5.0/debian/"}
estuary_dist=${DEBIAN_ESTUARY_DIST:-estuary-5.0}

apt-get update -q=2
apt-get install simple-cdd debian-archive-keyring -y

mkdir -p ${workspace}
cd ${workspace}

# add estuary repo key
wget -O - http://repo.estuarydev.org/releases/ESTUARY-GPG-KEY | \
	apt-key --keyring /usr/share/keyrings/debian-archive-keyring.gpg add -

# create custom installer dir
(mkdir -p installer/arm64/ && cd installer/arm64/ && ln -fs ${cdrom_installer_dir} images)

# create simple-cdd profiles
mkdir -p profiles
cat > profiles/debian.conf << EOF
custom_installer="${workspace}/installer"
debian_mirror="${mirror}"
security_mirror="${securiry_mirror}"
debian_mirror_extra="${estuary_repo}"
debian_mirror_extra_dist="${estuary_dist}"
mirror_components_extra="main"
EOF

cat > profiles/debian.packages << EOF
linux-image-estuary-arm64
grub-efi-arm64
sudo
EOF

# add prefix name 
export CDNAME=estuary-${version}-debian

# build 
build-simple-cdd --force-root \
	--dist stretch -p debian

# publish
mkdir -p ${out}
cp images/*.iso ${out}
