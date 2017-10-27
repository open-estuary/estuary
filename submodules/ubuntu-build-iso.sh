#!/bin/bash

set -ex

top_dir=$(cd `dirname $0`; cd ..; pwd)
version=$1 # branch or tag
build_dir=$(cd /root/$2 && pwd)

out=${build_dir}/out/release/${version}/ubuntu
distro_dir=${build_dir}/tmp/ubuntu
cdrom_installer_dir=${distro_dir}/installer/out/images
workspace=${distro_dir}/ubuntu-cd

export UBUNTU_CD=${workspace}

cdimage=${workspace}/cd-image
mnt=${workspace}/mnt
grubfiles=${workspace}/grubfiles
download=${workspace}/download

# set mirror
. ${top_dir}/include/mirror-func.sh
set_ubuntu_mirror

apt-get install -y apt-utils
apt-get install -y xorriso
apt-get install -y expect

mkdir -p ${workspace}
mkdir -p ${cdimage}
rm -rf ${cdimage}/* || true
mkdir -p ${mnt}
umount ${mnt} || true
mkdir -p ${download}
rm -rf ${download}/* || true

# download debs and filesystem
cd ${download}
wget ftp://repoftp:repopushez7411@117.78.41.188/releases/5.0/ubuntu/pool/main/linux-*4.12.0*.deb

wget http://open-estuary.org/download/AllDownloads/FolderNotVisibleOnWebsite/EstuaryInternalConfig/linux/Ubuntu/filesystem/filesystem.squashfs
wget http://open-estuary.org/download/AllDownloads/FolderNotVisibleOnWebsite/EstuaryInternalConfig/linux/Ubuntu/filesystem/filesystem.size

cd ${workspace}
# download iso and decompress
wget http://cdimage.ubuntu.com/ubuntu/releases/16.04/release/ubuntu-16.04.3-server-arm64.iso

mount -o loop ubuntu-16.04.3-server-arm64.iso ${mnt}
rsync -av ${mnt}/ ${cdimage}/

# copy debs to extras
mkdir -p ${cdimage}/pool/extras
cp ${download}/*.deb ${cdimage}/pool/extras

# copy vmlinuz and initrd.gz from installer
cp ${cdrom_installer_dir}/cdrom/vmlinuz ${cdimage}/install/vmlinuz
cp ${cdrom_installer_dir}/cdrom/initrd.gz ${cdimage}/install/initrd.gz

# copy grub files from installer
mkdir -p ${grubfiles}
cp ${cdrom_installer_dir}/cdrom/debian-cd_info.tar.gz ${grubfiles}
cd ${grubfiles}
tar -xzvf debian-cd_info.tar.gz

cp -r ${grubfiles}/grub/arm64-efi ${cdimage}/boot/grub/
cp -r ${grubfiles}/grub/efi.img ${cdimage}/boot/grub/
cp -r ${grubfiles}/grub/font.pf2 ${cdimage}/boot/grub/

# copy filesystem to install
cp ${download}/filesystem.size ${cdimage}/install/
cp ${download}/filesystem.squashfs ${cdimage}/install/

cd ..

# make cd
mkdir -p ${cdimage}/dists/xenial/extras/binary-arm64

mkdir -p ./ubuntu-cd-make/apt-ftparchive
mkdir -p ./ubuntu-cd-make/indices
mkdir -p ./ubuntu-cd-make/script_for_ubuntu_cd

cat > ./ubuntu-cd-make/apt-ftparchive/apt-ftparchive-deb.conf << EOF 
Dir {
  ArchiveDir "${workspace}/cd-image";
};

TreeDefault {
  Directory "pool/";
};

BinDirectory "pool/main" {
  Packages "dists/xenial/main/binary-arm64/Packages";
  BinOverride "${workspace}/ubuntu-cd-make/indices/override.xenial.main";
};

Default {
  Packages {
    Extensions ".deb";
    Compress ". gzip";
  };
};

Contents {
  Compress "gzip";
};
EOF

cat > ./ubuntu-cd-make/apt-ftparchive/apt-ftparchive-extras.conf << EOF 
Dir {
  ArchiveDir "${workspace}/cd-image";
};

TreeDefault {
  Directory "pool/";
};

BinDirectory "pool/extras" {
  Packages "dists/xenial/extras/binary-arm64/Packages";
};

Default {
  Packages {
    Extensions ".deb";
    Compress ". gzip";
  };
};

Contents {
  Compress "gzip";
};
EOF

cat > ./ubuntu-cd-make/apt-ftparchive/apt-ftparchive-udeb.conf << EOF
Dir {
  ArchiveDir "${workspace}/cd-image/";
};

TreeDefault {
  Directory "pool/";
};

BinDirectory "pool/main" {
  Packages "dists/xenial/main/debian-installer/binary-arm64/Packages";
  BinOverride "${workspace}/ubuntu-cd-make/indices/override.xenial.main.debian-installer";
};

Default {
  Packages {
    Extensions ".udeb";
    Compress ". gzip";
  };
};

Contents {
  Compress "gzip";
};
EOF

cat > ./ubuntu-cd-make/apt-ftparchive/release.conf << EOF
APT::FTPArchive::Release::Origin "Ubuntu";
APT::FTPArchive::Release::Label "Ubuntu";
APT::FTPArchive::Release::Suite "xenial";
APT::FTPArchive::Release::Version "16.04";
APT::FTPArchive::Release::Codename "xenial";
APT::FTPArchive::Release::Architectures "arm64";
APT::FTPArchive::Release::Components "main extras";
APT::FTPArchive::Release::Description "Ubuntu 16.04 LTS";
EOF

cat > ./ubuntu-cd-make/script_for_ubuntu_cd/indices.sh << EOF
#!/bin/bash

cd ${workspace}/ubuntu-cd-make/indices/
DIST=xenial
for SUFFIX in extra.main main main.debian-installer restricted restricted.debian-installer; do
  wget http://archive.ubuntu.com/ubuntu/indices/override.\$DIST.\$SUFFIX
done
EOF

chmod a+x ./ubuntu-cd-make/script_for_ubuntu_cd/indices.sh

cat > ./ubuntu-cd-make/script_for_ubuntu_cd/scan_make.sh << EOF
set -ex

BUILD=${workspace}/cd-image
APTCONF=${workspace}/ubuntu-cd-make/apt-ftparchive/release.conf
DISTNAME=xenial

pushd \$BUILD
apt-ftparchive -c \$APTCONF generate ${workspace}/ubuntu-cd-make/apt-ftparchive/apt-ftparchive-deb.conf
apt-ftparchive -c \$APTCONF generate ${workspace}/ubuntu-cd-make/apt-ftparchive/apt-ftparchive-udeb.conf
apt-ftparchive -c \$APTCONF generate ${workspace}/ubuntu-cd-make/apt-ftparchive/apt-ftparchive-extras.conf
apt-ftparchive -c \$APTCONF release \$BUILD/dists/\$DISTNAME > \$BUILD/dists/\$DISTNAME/Release

expect <<-END
        set timeout -1
        spawn gpg --default-key "3108CDA4" --output \$BUILD/dists/\$DISTNAME/Release.gpg -ba \$BUILD/dists/\$DISTNAME/Release
        expect {
                "Enter passphrase:" {send "OPENESTUARY@123\r"}
                timeout {send_user "Enter pass phrase timeout\n"}
        }
        expect {
                "Overwrite" {send "y\r"}
                timeout {send_user "Enter pass phrase timeout\n"}
        }
        expect eof
END

find . -type f -print0 | xargs -0 md5sum > md5sum.txt
popd

mkdir -p ${workspace}/output
rm -rf ${workspace}/output/ubuntu.iso

xorriso -as mkisofs -r -checksum_algorithm_iso md5,sha1 -V 'custom' -o ${workspace}/output/ubuntu.iso -J -joliet-long -cache-inodes -e boot/grub/efi.img -no-emul-boot -append_partition 2 0xef ${workspace}/cd-image/boot/grub/efi.img -partition_cyl_align all ${workspace}/cd-image
EOF

chmod a+x ./ubuntu-cd-make/script_for_ubuntu_cd/scan_make.sh

./ubuntu-cd-make/script_for_ubuntu_cd/indices.sh
./ubuntu-cd-make/script_for_ubuntu_cd/scan_make.sh

# add prefix name 
export CDNAME=estuary-${version}-ubuntu

# publish
mkdir -p ${out}
cp output/*.iso ${out}/${CDNAME}.iso

#scp ${out}/${CDNAME}.iso wangxiaochun@192.168.1.107:/home/wangxiaochun

