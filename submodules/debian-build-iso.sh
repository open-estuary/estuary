#!/bin/bash

set -ex

top_dir=$(cd `dirname $0`; cd ..; pwd)
version=$1 # branch or tag
build_dir=$(cd /root/$2 && pwd)

out=${build_dir}/out/release/${version}/Debian
kernel_deb_dir=${build_dir}/out/kernel-pkg/${version}/debian
distro_dir=${build_dir}/tmp/debian
cdrom_installer_dir=${distro_dir}/installer/out/images
workspace=${distro_dir}/simple-cdd

if [ -f "${build_dir}/build-debian-kernel" ]; then
    build_kernel=true
fi

# set mirror
mirror=${DEBIAN_MIRROR:-http://deb.debian.org/debian/}
securiry_mirror=${DEBIAN_SECURITY_MIRROR:-http://security.debian.org/}
estuary_repo=${DEBIAN_ESTUARY_REPO:-"ftp://repoftp:repopushez7411@117.78.41.188/releases/5.1/debian"}
estuary_dist=${DEBIAN_ESTUARY_DIST:-estuary-5.1}
. ${top_dir}/include/mirror-func.sh
set_debian_mirror
apt-get update -q=2
apt-get install simple-cdd debian-archive-keyring -y

mkdir -p ${workspace}
cd ${workspace}

# create custom installer dir
(mkdir -p installer/arm64/ && cd installer/arm64/ && ln -fs ${cdrom_installer_dir} images)

# create simple-cdd profiles
mkdir -p profiles
cat > profiles/debian.conf << EOF
custom_installer="${workspace}/installer"
debian_mirror="${mirror}"
security_mirror="${securiry_mirror}"
EOF
if [ x"$build_kernel" != x"true" ]; then
    echo "debian_mirror_extra=${estuary_repo}" >> profiles/debian.conf
    echo "debian_mirror_extra_dist=${estuary_dist}" >> profiles/debian.conf
    echo "mirror_components_extra=main" >> profiles/debian.conf
else
    echo "local_packages=${kernel_deb_dir}" >> profiles/debian.conf
fi

cat > profiles/debian.packages << EOF
linux-image-estuary-arm64
grub-efi-arm64
sudo
EOF

# add prefix name 
export CDNAME=estuary-${version}-debian

# build 
build-simple-cdd --force-root \
	--debug --verbose --dist stretch -p debian

# publish
mkdir -p ${out}
cp images/*.iso ${out}
