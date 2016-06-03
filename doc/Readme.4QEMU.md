This is the readme file for QEMU platform

After you do `./estuary/build.sh -p QEMU -d Ubuntu`, all targets files will be produced into `<project root>/build/QEMU` directory, they are:

UEFI, grub and dtb files are not necessary for QEMU platform

### Image 

**descriptions**: Image is the kernel executable program.

**target**: `<project root>/build/QEMU/kernel/arch/arm64/boot/Image`

**source**: `<project root>/kernel`

**Note**: Before compiling kernel, gcc-linaro-aarch64-linux-gnu-4.9-2014.09_linux(https://github.com/open-estuary/estuary/blob/master/doc/Toolchains_Guide.4All.md) and

libssl-dev should be installed first.

build commands(supposedly, you are in `<project root>`currently:
```shell
build_dir=build
KERNEL_DIR=kernel
mkdir -p $build_dir/QEMU/$KERNEL_DIR 2>/dev/null
kernel_dir=$build_dir/QEMU/$KERNEL_DIR
KERNEL_BIN=$kernel_dir/arch/arm64/boot/Image
CFG_FILE=defconfig
DTB_BIN=$kernel_dir/arch/arm64/boot/dts/hisilicon/hi6220-hikey.dtb
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-

pushd $KERNEL_DIR/

git clean -fdx
git reset --hard
sudo rm -rf ../$kernel_dir/*
make O=../$kernel_dir mrproper

./scripts/kconfig/merge_config.sh -O ../$kernel_dir -m arch/arm64/configs/defconfig arch/arm64/configs/distro.config arch/arm64/configs/estuary_defconfig

mv -f ../$kernel_dir/.config ../$kernel_dir/.merged.config

make O=../$kernel_dir KCONFIG_ALLCONFIG=../$kernel_dir/.merged.config alldefconfig

sed -i -e '/# CONFIG_ATA_OVER_ETH is not set/ a\CONFIG_VIRTIO_BLK=y' ../$kernel_dir/.config
sed -i -e '/# CONFIG_SCSI_BFA_FC is not set/ a\# CONFIG_SCSI_VIRTIO is not set' ../$kernel_dir/.config
sed -i -e '/# CONFIG_VETH is not set/ a\# CONFIG_VIRTIO_NET is not set' ../$kernel_dir/.config
sed -i -e '/# CONFIG_SERIAL_FSL_LPUART is not set/ a\# CONFIG_VIRTIO_CONSOLE is not set' ../$kernel_dir/.config
sed -i -e '/# CONFIG_VIRT_DRIVERS is not set/ a\CONFIG_VIRTIO=y' ../$kernel_dir/.config
sed -i -e '/# CONFIG_VIRTIO_PCI is not set/ a\# CONFIG_VIRTIO_BALLOON is not set' ../$kernel_dir/.config
sed -i -e '/# CONFIG_VIRTIO_MMIO is not set/ a\# CONFIG_VIRTIO_MMIO_CMDLINE_DEVICES is not set' ../$kernel_dir/.config
sed -i 's/# CONFIG_VIRTIO_MMIO is not set/CONFIG_VIRTIO_MMIO=y/g' ../$kernel_dir/.config

make O=../$kernel_dir -j${corenum} ${KERNEL_BIN##*/}

 ```   
    
### qemu-system-aarch64 

**descriptions**: qemu-system-aarch64 is the QEMU executable program.

**target**: `<project root>/build/qemu/bin/qemu-system-aarch64`

**source**: `<project root>/qemu`

build commands(supposedly, you are in <project root> currently:
```shell
    sudo apt-get install -y gcc zlib1g-dev libperl-dev libgtk2.0-dev libfdt-dev

    pushd qemu
    ./configure --prefix="/home/user/qemubuild" --target-list=aarch64-softmmu
    make -j14
    make install
    popd

    /home/user/qemubuild/qemu-system-aarch64 -machine virt -cpu cortex-a57 \
        -kernel <project root>/build/QEMU/binary/Image_QEMU \
        -drive if=none,file=<distribution image>,id=fs \
        -device virtio-blk-device,drive=fs \
        -append "console=ttyAMA0 root=/dev/vda rw" \
        -nographic
```

More detail about distributions, please refer to [Distributions_Guide.md](https://github.com/open-estuary/estuary/blob/master/doc/Distributions_Guide.4All.md).

More detail about toolchains, please refer to [Toolchains_Guide.md](https://github.com/open-estuary/estuary/blob/master/doc/Toolchains_Guide.4All.md).

More detail about how to debug, analyse, diagnose system, please refer to [Armor_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/Armor_Manual.4All.md).

More detail about how to benchmark system, please refer to [Caliper_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/Caliper_Manual.4All.md).
