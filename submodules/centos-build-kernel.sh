#!/bin/bash

set -ex

build_dir=$(cd /root/$2 && pwd)
version=$1 # branch or tag
version=${version:-master}

top_dir=$(cd `dirname $0`; cd ..; pwd)
out_rpm=${build_dir}/out/kernel-pkg/${version}/centos
distro_dir=${build_dir}/tmp/centos
workspace=${distro_dir}/kernel

# Install build tools,do not change !
sudo yum install -y epel-release 
sudo yum install -y python34 dpkg-dev quilt
sudo yum install -y wget git rpm-build yum-utils make openssl-devel
sudo yum install -y net-tools bc xmlto asciidoc openssl-devel audit-libs-devel 'perl(ExtUtils::Embed)'
sudo wget http://repo.linaro.org/rpm/linaro-overlay/centos-7/linaro-overlay.repo -O /etc/yum.repos.d/linaro-overlay.repo
sudo yum groupinstall -y "Development tools"

# Install estuary latest kernel
sudo wget -O /etc/yum.repos.d/estuary.repo https://raw.githubusercontent.com/open-estuary/distro-repo/master/estuaryftp.repo
sudo chmod +r /etc/yum.repos.d/estuary.repo
sudo rpm --import http://repo.estuarydev.org/releases/ESTUARY-GPG-KEY
yum clean dbcache
yum install --disablerepo=* --enablerepo=Estuary kernel -y

#find build_num
if [ ! -z "$(yum info installed kernel)" ]; then
        build_num=$(yum info installed kernel|grep estuary|awk -F ' ' '{print $3}'|awk -F '.' '{print $2}')
        build_num=$((build_num + 1))
else
        build_num=500
fi
build_num=${BUILD_NUM:-${build_num}}

# Checkout source code
rm -rf ${out_rpm} ~/rpmbuild ${workspace}/orig
mkdir -p ${workspace} && cd ${workspace}
mkdir -p ${out_rpm} && mkdir -p debian-pkg
git clone --depth 1 -b ${version} https://github.com/open-estuary/distro-repo.git
git clone --depth 1 -b ${version} https://github.com/open-estuary/kernel.git linux

# Export the kernel packaging version
cd ${workspace}/linux
kernel_version=$(make kernelversion)
export KDEB_PKGVERSION="${kernel_version}.estuary.${build_num}-1"
git tag -f v${kernel_version}

# Build the source kernel
cd ../debian-pkg
cp -r ../distro-repo/deb/kernel/debian-package/debian .

# Use build number as ABI
sed -i "s/^abiname:.*/abiname: ${build_num}/g" debian/config/defines

cat << EOF > debian/changelog
linux ($KDEB_PKGVERSION) unstable; urgency=medium

  * Auto build:
    - URL: ${GIT_URL}
    - Branch: ${GIT_BRANCH}
    - Commit: ${GIT_COMMIT}

 -- OpenEstuary <sjtuhjh@hotmail.com>  $(date -R)

EOF

debian/bin/genorig.py ../linux
debian/rules orig

# Build rpm source package
rpmversion=${kernel_version//-*/}
cd ${workspace} 
rm -rf kernel-aarch64
(mkdir -p kernel-aarch64 && cd kernel-aarch64)
cp -rf ${workspace}/distro-repo/rpm/kernel/centos-package/* .

sed -i "s/\%define rpmversion.*/\%define rpmversion $rpmversion/g" SPECS/kernel-aarch64.spec
sed -i "s/\%define pkgrelease.*/\%define pkgrelease estuary.${build_num}/g" SPECS/kernel-aarch64.spec
sed -i "s/\%define signmodules 1/\%define signmodules 0/g" SPECS/kernel-aarch64.spec
sed -i "s/\%{gitrelease}/\%{pkgrelease}/g" SPECS/kernel-aarch64.spec
sed -i "/_without_debug:/a%define with_debug 0" SPECS/kernel-aarch64.spec
sed -i "/_without_debuginfo:/a%define with_debuginfo 0" SPECS/kernel-aarch64.spec
sed -i "s/mv linux-\%{rheltarball}/mv linux-\*/g" SPECS/kernel-aarch64.spec
sed -i '/\%{_libexecdir}\/perf-core\/\*/a\%{_datadir}\/perf-core\/\*' SPECS/kernel-aarch64.spec
sed -i "s/^BuildRequires: openssl$/BuildRequires: openssl-devel/g" SPECS/kernel-aarch64.spec
sed -i "s/0.0.0/0.0.1/g" SPECS/kernel-aarch64.spec
sed -i "/%define pkgrelease.*/a\%define _unpackaged_files_terminate_build 0" SPECS/kernel-aarch64.spec

cp ${workspace}/orig/*.orig.tar.xz SOURCES/linux-${rpmversion}-estuary.${build_num}.tar.xz
rpmbuild --nodeps --define "%_topdir `pwd`" -bs SPECS/kernel-aarch64.spec

# Copy back the resulted artifacts
mkdir -p $out_rpm
cp -p $workspace/SRPMS/*.src.rpm $out_rpm
echo "Source packages available at $out_rpm"

cd $out_rpm
rpmbuild --rebuild *.src.rpm
cp ~/rpmbuild/RPMS/aarch64/*.rpm .
