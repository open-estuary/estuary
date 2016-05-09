This is the readme file for D02 platform

After you do `./estuary/build.sh -p D02 -d Ubuntu`, all targets files will be produced into `<project root>/build/D02` directory, they are:

### UEFI_D02.fd 
### CH02TEVBC_V03.bin 

**description**: UEFI_D02.fd is the UEFI bios for D02 platform, CH02TEVBC_V03.bin is the CPLD binary for D02 board, the others are binaries for trust firmware.

**target**: `<project root>/build/D02/binary/`

**source**: `<project root>/uefi`

build commands(supposedly, you are in `<project root>` currently):
```shell
    export ARCH=
    export CROSS_COMPILE=aarch64-linux-gnu-
    pushd uefi
    # roll back to special version for D02
    git reset --hard
    git checkout open-estuary/master
    # build uefi
    export LC_CTYPE=C
    git submodule init
    git submodule update

    uefi-tools/uefi-build.sh -c LinaroPkg/platforms.config d02

    cp Build/Pv660D02/RELEASE_GCC49/FV/PV660D02.fd ../build/D02/binary/UEFI_D02.fd
    popd
```
Then you will find *.fd in <project root>/uefi/Build.

### grubaa64.efi 
### grub.cfg 

**description**: 
    grubaa64.efi is used to load kernel image and dtb files from SATA, SAS, USB Disk, or NFS into RAM and start the kernel.
    grub.cfg is used by grubaa64.efi to config boot options.
    More detail about them, please refer to [Grub_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/Grub_Manual.4All.md).
    
**target**: `<project root>/build/D02/grub/`

**source**: `<project root>/grub`

build commands(supposedly, you are in `<project root>` currently):
```shell
    export CROSS_COMPILE=aarch64-linux-gnu-
    pushd grub
    # Apply patch for boot from indicated MAC address
    git reset --hard
    git checkout grub/master
    git apply ../patches/001-Search-for-specific-config-file-for-netboot.patch

    make distclean
    ./autogen.sh
    ./configure --prefix="/home/<user>/<grubbuild>" --with-platform=efi --build=x86_64-suse-linux-gnu --target=aarch64-linux-gnu --disable-werror --host=x86_64-suse-linux-gnu
    make -j14
    make  install
    popd

    pushd /home/<user>/<grubbuild>
    ./bin/grub-mkimage -v -o grubaa64.efi -O arm64-efi -p / boot chain configfile configfile efinet ext2 fat gettext help hfsplus loadenv lsefi normal normal ntfs ntfscomp part_gpt part_msdos part_msdos read search search_fs_file search_fs_uuid search_label terminal terminfo tftp linux
    popd

```

Note: `<user>` means hostname of computer, `<grubbuild>` is folder new created.
### Image ###
### hip05-d02.dtb ###

**descriptions**: Image is the kernel executable program, and hip05-d02.dtb is the device tree binary.

**target**: 
Image in `<project root>/build/D02/kernel/arch/arm64/boot/Image`

hip05-d02.dtb in `<project root>/build/D02/kernel/arch/arm64/boot/dts/hisilicon/hip05-d02.dtb`

**source**: `<project root>/kernel`

build commands(supposedly, you are in `<project root>` currently):
```shell
    export ARCH=arm64
    export CROSS_COMPILE=aarch64-linux-gnu-

    pushd kernel
    make mrproper
    make defconfig
    make -j14 Image
    make hisilicon/hip05-d02.dtb

    cp arch/arm64/boot/Image ../build/D02/binary/Image_D02
    cp arch/arm64/boot/dts/hisilicon/hip05-d02.dtb ../build/D02/binary
    popd
```
More detail about distributions, please refer to [Distributions_Guide.md](https://github.com/open-estuary/estuary/blob/master/doc/Distributions_Guide.4All.md).

More detail about toolchains, please refer to [Toolchains_Guide.md](https://github.com/open-estuary/estuary/blob/master/doc/Toolchains_Guide.4All.md).

More detail about how to deploy target system into D02 board, please refer to [Deployment_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/Deploy_Manual.4D02.md).

More detail about how to debug, analyse, diagnose system, please refer to [Armor_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/Armor_Manual.4All.md).

More detail about how to benchmark system, please refer to [Caliper_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/Caliper_Manual.4All.md).

More detail about how to access remote boards in OpenLab, please refer to [Boards_in_OpenLab](http://open-estuary.org/accessing-boards-in-open-lab/).
