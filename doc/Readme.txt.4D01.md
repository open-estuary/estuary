
After you do `./estuary/build.sh -p D01 -d Ubuntu`, all targets files will be produced into `<project root>/build/D01` directory, they are:

**UEFI_D01.fd**

*description*: UEFI_D01.fd is the UEFI bios for D01 platform.

*target*: `<project root>/build/D01/binary/`

*source*: `<project root>/uefi`

build commands(supposedly, you are in <project root> currently:

 ```
    export ARCH=
    export CROSS_COMPILE=arm-linux-gnueabihf-
    # prepare uefi-tools
    pushd tools/uefi/uefi-tools
    echo "[d01]" >> platforms.config 
    echo "LONGNAME=HiSilicon D01 Cortex-A15 16-cores" >> platforms.config
    echo "BUILDFLAGS=-D EDK2_ARMVE_STANDALONE=1" >> platforms.config
    echo "DSC=HisiPkg/D01BoardPkg/D01BoardPkg.dsc" >> platforms.config
    echo "ARCH=ARM" >> platforms.config
    popd
   
    # compile uefi for D01
    pushd uefi
    # roll back to special version for D01
    git reset --hard
    git checkout open-estuary/old
    
    ../tools/uefi-tools/uefi-build.sh -b DEBUG d01
    
    cp Build/D01/DEBUG_GCC49/FV/D01.fd ../build/D01/binary/UEFI_D01.fd
  ```
  
**.text**<br>
**.monitor**

*description*: boot wrapper files to take responsible of switching into HYP mode.

*target*: `<project root>/build/D01/bootwrapper/`

*source*: `<project root>/bootwrapper`

 `export CROSS_COMPILE=arm-linux-gnueabihf-make`   
   
   
**grubarm32.efi**<br>
**grub.cfg**

*description:*

grubarm32.efi is used to load kernel image and dtb files from SATA, SAS, USB Disk, or NFS into RAM and start the kernel.
    
grub.cfg is used by grubaa64.efi to config boot options.
    
More detail about them, please refer to Grub_Manual.txt.
    
*target*: ｀<project root>/build/D01/grub/｀

*source*: ｀<project root>/grub｀

build commands(supposedly, you are in <project root> currently:

```
    export CROSS_COMPILE=arm-linux-gnueabihf-
    pushd grub
    # rollbak the grub master
    git reset --hard
    git checkout grub/master
    git checkout 8e3d2c80ed1b9c2d150910cf3611d7ecb7d3dc6f

    # build grub
    make distclean
    ./autogen.sh
    ./configure --target=arm-linux-gnueabihf --with-platform=efi --prefix="/home/user/grubbuild"
    make -j14 
    make install
    popd

    pushd /home/user/grubbuild
    ./bin/grub-mkimage -v -o grubarm32.efi -O arm-efi -p / boot chain configfile configfile efinet ext2 fat gettext help hfsplus loadenv lsefi normal normal ntfs ntfscomp part_gpt part_msdos part_msdos read search search_fs_file search_fs_uuid search_label terminal terminfo tftp linux
    popd
```
    
**zImage**<br>
**hip04-d01.dtb**<br>
**.kernel**<br>
**.filesystem**

*descriptions*:

  zImage is the compressed kernel executable program.
    
  hip04-d01.dtb is the device tree binary.
   
  .kernel is the file combining zImage and hip04-d01.dtb.
   
  .filesystem is a special rootfs for D01 booting from NORFLASH.
   
*target*:

 zImage in <project root>/build/D01/kernel/arch/arm/boot/zImage

 hip04-d01.dtb in <project root>/build/D01/kernel/arch/arch/arm/boot/dts/hip04-d01.dtb
        
 .kernel in <project root>/build/D01/kernel/.kernel
        
 .filesystem in <project root>/build/D01/binary/.filesystem
        
*source*: <project root>/kernel

build commands(supposedly, you are in <project root> currently:
 ```
    export ARCH=arm
    export CROSS_COMPILE=arm-linux-gnueabihf-

    pushd kernel
    make mrproper
    make hisi_defconfig
    
    sed -i 's/CONFIG_HAVE_KVM_IRQCHIP=y/# CONFIG_VIRTUALIZATION is not set/g' .config
    sed -i 's/CONFIG_KVM_MMIO=y//g' .config
    sed -i 's/CONFIG_HAVE_KVM_CPU_RELAX_INTERCEPT=y//g' .config
    sed -i 's/CONFIG_VIRTUALIZATION=y//g' .config
    sed -i 's/CONFIG_KVM=y//g' .config
    sed -i 's/CONFIG_KVM_ARM_HOST=y//g' .config
    sed -i 's/CONFIG_KVM_ARM_MAX_VCPUS=4//g' .config
    sed -i 's/CONFIG_KVM_ARM_VGIC=y//g' .config
    sed -i 's/CONFIG_KVM_ARM_TIMER=y//g' .config
    
    make zImage
    make hip04-d01.dtb

    cat arch/arm/boot/zImage arch/arm/boot/dts/hip04-d01.dtb > .kernel

    cp arch/arm/boot/zImage ../build/D01/binary/zImage_D01
    cp arch/arm/boot/dts/hip04-d01.dtb ../build/D01/binary/
    cp .kernel ../build/D01/binary/
    popd
 ```
  
  
More detail about distributions, please refer to [Distributions_Guide.md](//github.com/open-estuary/estuary/blob/master/doc/Distributions_Guide.md.4All)

More detail about toolchains, please refer to [Toolchains_Guide.md](https://github.com/open-estuary/estuary/blob/master/doc/Toolchains_Guide.md.4All)

More detail about how to deploy target system into D01 board, please refer to [Deployment_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/Deploy_Manual.md.4D01).

More detail about how to debug, analyse, diagnose system, please refer to [Armor_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/Armor_Manual.md.4All)

More detail about how to benchmark system, please refer to [Caliper_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/Caliper_Manual.md.4All)

More detail about how to access remote boards in OpenLab, please refer to [Boards_in_OpenLab.md](http://open-estuary.org/accessing-boards-in-open-lab/)
