#!/bin/bash

set -ex

top_dir=$(cd `dirname $0`; cd ..; pwd)
version=$1 # branch or tag
build_dir=$(cd /root/$2 && pwd)

out_deb=${build_dir}/out/kernel-pkg/${version}/debian
distro_dir=${build_dir}/tmp/debian
workspace=${distro_dir}/kernel

kernel_url=${KERNEL_URL:-https://${GITHUB_MIRROR}/open-estuary/kernel.git}

export DEB_BUILD_OPTIONS=parallel=`getconf _NPROCESSORS_ONLN`

# set mirror
estuary_repo=${DEBIAN_ESTUARY_REPO:-"ftp://repoftp:repopushez7411@117.78.41.188/releases/5.2/debian"}
estuary_dist=${DEBIAN_ESTUARY_DIST:-estuary-5.2}
. ${top_dir}/include/mirror-func.sh
echo "deb-src http://mirrors.163.com/debian/ stretch main" >> /etc/apt/sources.list
set_debian_mirror
apt-get update -q=2

# 1) build kernel packages debs, udebs
mkdir -p ${workspace}
cd ${workspace}
workspace=${workspace}/kernel
rm -rf kernel ${out_deb}
git clone --depth 1 -b ${version} https://${GITHUB_MIRROR}/open-estuary/debian-kernel-packages.git kernel
mkdir -p ${workspace}/linux
cd $build_dir/../../kernel/
tar cf - . | (cd ${workspace}/linux; tar xf -)

# Export the kernel packaging version
cd ${workspace}/linux

#find build_num
if [ ! -z "$(apt-cache show linux-image-estuary-arm64)" ]; then
	build_num=$(apt-cache policy linux-image-estuary-arm64|grep Candidate:|awk -F '+' '{print $2}')
	build_num=$((build_num + 1))
else
	build_num=500
fi
build_num=${BUILD_NUM:-${build_num}}

kernel_version=$(make kernelversion)
kernel_deb_pkg_version=$(echo ${kernel_version} | sed -e 's/\.0-rc/~rc/')
export KDEB_PKGVERSION="${kernel_deb_pkg_version}.estuary.${build_num}-1"
git tag -f v${kernel_deb_pkg_version//\~/-}

# Build the debian package
cd ${workspace}/debian-package
rm -rf orig

# Use build_num as ABI

sed -i "s/^abiname:.*/abiname: ${build_num}/g" debian/config/defines

cat << EOF > debian/changelog
linux ($KDEB_PKGVERSION) unstable; urgency=medium

  * Auto build:
    - URL: ${kernel_url}
    - version: ${verion}

 -- OpenEstuary <xinliang.liu@linaro.org>  $(date -R)

EOF

debian/rules clean || true
debian/bin/genorig.py ../linux
debian/rules orig
fakeroot debian/rules source
dpkg-buildpackage -rfakeroot -sa -uc -us -d


# 2) Build the kernel package 
package_version=${build_num}
kernel_abi_version=$(basename ${workspace}/linux-support*|sed -e "s/linux-support-//g" -e "s/_.*//g")
dpkg -i ${workspace}/linux-support*
dpkg -i ${workspace}/linux-kbuild*
dpkg -i ${workspace}/linux-headers*

cd ${workspace}/debian-meta-package
cp -rf ../debian-package/debian/lib debian/
sed -i -e "s@sys.path.append.*@sys.path.append(\"debian/lib/python\")@" debian/bin/gencontrol.py
sed -i "s/KERNELVERSION :=.*/KERNELVERSION := ${kernel_abi_version}/" debian/rules.defs
sed -i "s/src/share/" debian/rules
./debian/rules debian/control || true
NAME="OpenEstuary" EMAIL=xinliang.liu@linaro.org dch -v "${package_version}" -D stretch --force-distribution "bump ABI to ${kernel_abi_version}"
./debian/rules debian/control || true
dpkg-buildpackage -rfakeroot -sa -uc -us -d

# 3) Build the customer installer udeb package
cd ${workspace}/debian-di
dpkg-buildpackage -rfakeroot -sa -uc -us -d


# 4) publish
 cd ${workspace}
(mkdir -p ${out_deb} && cp -f *deb *.dsc *.tar.xz *.changes ${out_deb})
#(cd ${out_deb} && dpkg-scanpackages -t udeb . > Packages)
