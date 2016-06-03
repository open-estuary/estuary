This is the readme file for HiKey platform

Above all, you need install some applications firstly as follows:
sudo apt-get install -y wget automake1.11 make bc libncurses5-dev libtool li
bc6:i386 libncurses5:i386 libstdc++6:i386 lib32z1 bison flex uuid-dev build-esse
ntial iasl gcc zlib1g-dev libperl-dev libgtk2.0-dev libfdt-dev

After you do `./estuary/build.sh -p HiKey -d Ubuntu`, all targets files will be produced into `<project root>/build/HiKey` directory, they are:

### l-loader 
### fip.bin 
### ptable-linux.img 
### AndroidFastbootApp.efi 

**description**: l-loader.bin - used to switch from aarch32 to aarch64 and boot, fip.bin - firmware package, ptable-linux.img - partition tables for Linux images. 

**target**: `<project root>/build/HiKey/binary/`

**source**: `<project root>/uefi`

build commands(supposedly, you are in `<project root>` currently:
```shell
    BUILD_OPTION=DEBUG
    BUILD_PATH=${PWD}
    EDK2_DIR=${BUILD_PATH}
    EDK2_OUTPUT_DIR=${EDK2_DIR}/Build/HiKey/${BUILD_OPTION}_${AARCH64_TOOLCHAIN}

    export AARCH64_TOOLCHAIN=GCC49
    export UEFI_TOOLS_DIR=${BUILD_PATH}/uefi-tools
    export EDK2_DIR

    ${UEFI_TOOLS_DIR}/uefi-build.sh -b ${BUILD_OPTION} -a ./arm-trusted-firmware hikey

    cd ${BUILD_PATH}/l-loader
    cp ${EDK2_OUTPUT_DIR}/FV/bl1.bin ./
    cp ${EDK2_OUTPUT_DIR}/FV/fip.bin ./

    arm-linux-gnueabihf-gcc -c -o start.o start.S
    arm-linux-gnueabihf-gcc -c -o debug.o debug.S
    arm-linux-gnueabihf-ld -Bstatic -Tl-loader.lds -Ttext 0xf9800800 start.o debug.o -o loader
    arm-linux-gnueabihf-objcopy -O binary loader temp
    python gen_loader.py -o l-loader.bin --img_loader=temp --img_bl1=bl1.bin

    sudo PTABLE=linux-8g bash -x generate_ptable.sh
    python gen_loader.py -o ptable.img --img_prm_ptable=prm_ptable.img --img_sec_ptable=sec_ptable.img

    cp l-loader.bin build/HiKey/binary/
    cp fip.bin      build/HiKey/binary/
    cp ptable-linux.img build/HiKey/binary/
    cp ${EDK2_DIR}/Build/HiKey/RELEASE_GCC49/AARCH64/AndroidFastbootApp.efi build/HiKey/binary/

    cd ../
  ```
The files fip.bin, l-loader.bin and ptable-linux.img are now built. All the image files are in `$BUILD/l-loader` directory. The Fastboot App is at `adk2/Build/HiKey/RELEASE_GCC49/AARCH64/AndroidFastbootApp.efi`

### grubaa64.efi 
### grub.cfg 

**description**: 

grubaa64.efi is used to load kernel image and dtb files from SD card, nandflash into RAM and start the kernel.
    
grub.cfg is used by grubaa64.efi to config boot options.
    
More detail about them, please refer to [Grub_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/Grub_Manual.4All.md).
    
**target**: `<project root>/build/HiKey/grub/`

**source**: `<project root>/grub`

build commands(supposedly, you are in `<project root>` currently:
```shell
    export CROSS_COMPILE=aarch64-linux-gnu-
    pushd grub
    # Apply patch for boot from indicated MAC address
    git reset --hard
    git checkout grub/master
    git checkout 8e3d2c80ed1b9c2d150910cf3611d7ecb7d3dc6f
    git am ../patches/001-Search-for-specific-config-file-for-netboot.patch

    make distclean
    ./autogen.sh
    ./configure --prefix="/home/user/grubbuild" --with-platform=efi --build=x86_64-suse-linux-gnu --target=aarch64-linux-gnu --disable-werror --host=x86_64-suse-linux-gnu
    make -j14
    make  install
    popd

    pushd /home/user/grubbuild
    ./bin/grub-mkimage -v -o grubaa64.efi -O arm64-efi -p / boot chain configfile configfile efinet ext2 fat gettext help hfsplus loadenv lsefi normal normal ntfs ntfscomp part_gpt part_msdos part_msdos read search search_fs_file search_fs_uuid search_label terminal terminfo tftp linux
    popd
```

### Image 
### hi6220-hikey.dtb 

**descriptions**: Image is the kernel executable program, and hi6220-hikey.dtb is the device tree binary.

**target**: 
Image in `<project root>/build/HiKey/kernel/arch/arm64/boot/Image`

hi6220-hikey.dtb in `<project root>/build/D02/kernel/arch/arm64/boot/dts/hisilicon/hi6220-hikey.dtb`

**source**: `<project root>/kernel`

**Note**: Before compiling kernel, gcc-linaro-aarch64-linux-gnu-4.9-2014.09_linux(https://github.com/open-estuary/estuary/blob/master/doc/Toolchains_Guide.4All.md) and

libssl-dev should be installed first.

build commands(supposedly, you are in `<project root>` currently:
```shell
build_dir=build
KERNEL_DIR=kernel
mkdir -p $build_dir/HiKey/$KERNEL_DIR 2>/dev/null
kernel_dir=$build_dir/HiKey/$KERNEL_DIR
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

sed -i 's/\(CONFIG_CDROM_PKTCDVD=\)\(.*\)/\1y/' ../$kernel_dir/.config
sed -i 's/\(CONFIG_ISO9660_FS=\)\(.*\)/\1y/' ../$kernel_dir/.config
sed -i 's/\(CONFIG_BLK_DEV_SR=\)\(.*\)/\1y/' ../$kernel_dir/.config
sed -i 's/\(CONFIG_CHR_DEV_SG=\)\(.*\)/\1y/' ../$kernel_dir/.config

make O=../$kernel_dir -j${corenum} ${KERNEL_BIN##*/}
dtb_dir=${DTB_BIN#*arch/}
dtb_dir=${DTB_BIN%/*}
dtb_dir=../${kernel_dir}/arch/${dtb_dir}

mkdir -p $dtb_dir 2>/dev/null

make O=../$kernel_dir ${DTB_BIN#*/boot/dts/}

```
If you get more information about uefi, please visit https://github.com/96boards/documentation/wiki/HiKeyUEFI

More detail information about how to deploy target system into HiKey board, please refer to [Deploy_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/Deploy_Manual.4HiKey.md).

More detail information about how to config this WiFi function into HiKey board, please refer to [Setup_HiKey_Wifi_Env.md](https://github.com/open-estuary/estuary/blob/master/doc/Setup_HiKey_WiFi_Env.4HiKey.md).

More detail information about distributions, please refer to [Distributions_Guider.md](https://github.com/open-estuary/estuary/blob/master/doc/Distributions_Guide.4All.md).

More detail information about toolchains, please refer to [Toolchains_Guider.md](https://github.com/open-estuary/estuary/blob/master/doc/Toolchains_Guide.4All.md).

More detail information about how to benchmark system, please refer to [Caliper_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/Caliper_Manual.4All.md).

More detail information about how to access remote boards in OpenLab, please refer to [Boards_in_OpenLab](http://open-estuary.org/accessing-boards-in-open-lab/).
