This is the guide for distributions

Distribution indicates a specially total rootfs for linux kernel.  
After you run `./estuary/build.sh -d <Platform Name> -p <Distribution Name>`, the corresponding distribution tarball will be created into `<project root>/build/<platform name>/distro`.  
By default, it is named as <Distribution Name>_<ARM arch>.tar.gz, and the default username and password for them are "root,root".

You can do following commands to uncompress the tarball into any special block device's partition, e.g.: SATA, SAS or USB disk.
```bash
mkdir tempdir
sudo mount /dev/<block device name> tempdir
sudo tar -xzf <Distribution Name>_<Arm arch>.tar.gz -C tempdir 
```
You can also simply uncompress the tarball into a special directory as follows, and use the directory as the NFS's rootfs.
```bash
mkdir nfsdir
sudo tar -xzf <Distribution Name>_<Arm arch>.tar.gz -C nfsdir 
```
If you want to produce a rootfs image file for QEMU, you can try as belows
```bash
mkdir tempdir
sudo tar -xzf <Distribution Name>_<Arm arch>.tar.gz -C tempdir 

pushd tempdir
dd if=/dev/zero of=../rootfs.img bs=1M count=10240
mkfs.ext4 ../rootfs.img -F
mkdir -p ../tempdir 2>/dev/null
sudo mount ../rootfs.img ../tempdir
sudo cp -a * ../tempdir/
sudo umount ../tempdir
rm -rf ../tempdir
popd
```
Then you will get the rootfs image file as rootfs.img

**You can download above distributions by following commands manually**.

All validated distributions can be obtained in [HTTP Download](http://download.open-estuary.org/)/[release|pre-releases]/`<version>`/linux/`<distro name>`/.

e.g.:  
You can get Ubuntu distribution of estuary v2.2-rc1 pre-releases version as follow:  
`wget -c http://download.open-estuary.org/AllDownloads/DownloadsEstuary/pre-releases/2.2/rc1/linux/Ubuntu/Common/Ubuntu_ARM64.tar.gz`

For other distributions please refer to the description aboved.

**And all original distributions can be gotten by following commands**:

Ubuntu:  
`wget -c https://cloud-images.ubuntu.com/vivid/current/vivid-server-cloudimg-arm64.tar.gz`

OpenSUSE:  
`wget -c http://download.opensuse.org/ports/aarch64/distribution/13.2/appliances/openSUSE-13.2-ARM-JeOS.aarch64-rootfs.aarch64-Current.tbz`

Fedora:  
`wget -c http://dmarlin.fedorapeople.org/fedora-arm/aarch64/F21-20140407-foundation-v8.tar.xz`

Redhat: TBD

Debian:  
`wget -c http://people.debian.org/~wookey/bootstrap/rootfs/debian-unstable-arm64.tar.gz`

OpenEmbedded:  
`wget -c http://releases.linaro.org/14.06/openembedded/aarch64/vexpress64-openembedded_minimal-armv8-gcc-4.8_20140623-668.img.gz`

More detail about how to deploy target system into target board, please refer to Deployment_Manual.md.

