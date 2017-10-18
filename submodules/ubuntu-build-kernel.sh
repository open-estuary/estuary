#!/bin/bash

set -ex

top_dir=$(cd `dirname $0`; cd ..; pwd)
version=$1 # branch or tag
build_dir=$(cd /root/$2 && pwd)

out_deb=${build_dir}/out/kernel-pkg/${version}/ubuntu
out_deb_not_meta=${out_deb}/not_meta
out_deb_meta=${out_deb}/meta

distro_dir=${build_dir}/tmp/ubuntu
workspace=${distro_dir}/kernel

kernel_url=${KERNEL_URL:-https://github.com/open-estuary/kernel.git}
kernel_pkg_url=${KERNEL_PKG_URL:-https://github.com/open-estuary/distro-repo.git}

#export DEB_BUILD_OPTIONS=parallel=`getconf _NPROCESSORS_ONLN`

# set mirror
. ${top_dir}/include/mirror-func.sh
set_ubuntu_mirror

sudo apt-get update -q=2

expect <<-END
        set timeout -1
        spawn apt-get build-dep -q --no-install-recommends -y linux
        expect {
                "or Enter to continue" {send "\r"}
                timeout {send_user "build-dep install timeout\n"}
        }
        expect eof
END

sudo apt-get install -y libnuma-dev
sudo apt-get install -y git graphviz

# 1) build kernel packages debs, udebs
mkdir -p ${workspace}
cd ${workspace}
git clone --depth 1 -b ${version} ${kernel_pkg_url}

workspace=${workspace}/distro-repo/deb/kernel
cd ${workspace}
git clone --depth 1 -b ${version} ${kernel_url} linux

# Export the kernel packaging version
cd ${workspace}/linux

#find build_num
if [ ! -z "$(apt-cache show linux-image-estuary-arm64)" ]; then
	build_num=$(apt-cache depends linux-image-estuary-arm64|grep Depends:|awk -F '-' '{print $4}')
	build_num=$((build_num + 1))
else
	build_num=500
fi
build_num=${BUILD_NUM:-${build_num}}

# find commit
if [ -z $(git tag -l|grep ${version}) ]; then
	pkg_partial_verion=$(git log --abbrev-commit|grep commit|awk '{print $2}')
else
	pkg_partial_verion=${version}
fi

kernel_version=$(make kernelversion)
kernel_deb_pkg_version=$(echo ${kernel_version} | sed -e 's/\.0-rc/~rc/')
export KDEB_PKGVERSION="${kernel_deb_pkg_version}-${build_num}.estuary"
git tag -f v${kernel_deb_pkg_version//\~/-}

echo "build_num is ${build_num}"
echo "pkg_partial_version is ${pkg_partial_verion}"
echo "kernel_version is ${kernel_version}"
echo "kernel_deb_pkg_version is ${kernel_deb_pkg_version}"
echo "KDEB_PKGVERSION is ${KDEB_PKGVERSION}"

# Build the ubuntu package
cd ${workspace}

rm -rf linux/debian/
rm -rf linux/debian.master/

cp -r ubuntu-package/debian/ linux
cp -r ubuntu-package/debian.master/ linux

cd ${workspace}/linux
# Use build_num as ABI
cat << EOF > debian.master/changelog
linux ($KDEB_PKGVERSION) unstable; urgency=medium

  * Auto build:
    - URL: ${kernel_url}
    - version: ${pkg_partial_verion}

 -- OpenEstuary <xinliang.liu@linaro.org>  $(date -R)

EOF

# Enable HISI SAS module
sed -i "s/CONFIG_SCSI_HISI_SAS=m/CONFIG_SCSI_HISI_SAS=y/g" debian.master/config/config.common.ubuntu

echo kernel build start......
debian/rules clean || true
dpkg-buildpackage -rfakeroot -sa -uc -us
echo kernel build end......

cd ..
echo ${out_deb_not_meta}
(mkdir -p ${out_deb_not_meta} && mv *.deb *.udeb *.tar.gz *.dsc *.changes ${out_deb_not_meta}) || true

# 2) Build the meta kernel package 
rm -rf linux/debian/
rm -rf linux/debian.master/

cp -r ubuntu-meta-package/debian/ linux

cd ${workspace}/linux

kernel_abi_version=${kernel_deb_pkg_version}.${build_num}.2
package_version=${build_num}

echo meta kernel build start...
NAME="OpenEstuary" EMAIL=xinliang.liu@linaro.org dch -v "${kernel_abi_version}" -D xenial --force-distribution "Bump ABI to ${kernel_abi_version}"
./debian/rules clean || true
dpkg-buildpackage -rfakeroot -sa -uc -us -d
echo meta kernel build end...

# 3) publish
 cd ${workspace}
(mkdir -p ${out_deb_meta} && mv *.deb *.dsc *.tar.gz *.changes ${out_deb_meta}) || true

exit 0
