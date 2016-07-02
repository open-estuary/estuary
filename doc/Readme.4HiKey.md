This is the readme file for HiKey platform

Above all, you need install some applications firstly as follows:
sudo apt-get install -y wget automake1.11 make bc libncurses5-dev libtool li
bc6:i386 libncurses5:i386 libstdc++6:i386 lib32z1 bison flex uuid-dev build-esse
ntial iasl gcc zlib1g-dev libperl-dev libgtk2.0-dev libfdt-dev

After you executed `./estuary/build.sh --cfgfile=./estuary/estuarycfg.json --builddir=./workspace` for HiKey, all targets files will be produced. they are:

### l-loader.bin
### ptable-linux.img 
### AndroidFastbootApp.efi 
### UEFI_HiKey.fd

**description**: l-loader.bin - used to switch from aarch32 to aarch64 and boot, UEFI_HiKey.fd is the UEFI bios for HiKey, ptable-linux.img - partition tables for Linux images. 

**target**:
 
`<project root>/workspace/binary/HiKey/l-loader.bin`

`<project root>/workspace/binary/HiKey/ptable-linux.img`

`<project root>/workspace/binary/HiKey/AndroidFastbootApp.efi`

`<project root>/workspace/binary/HiKey/UEFI_HiKey.fd`.

**source**: `<project root>/uefi`

build commands(supposedly, you are in `<project root>` currently:

`./estuary/submodules/build-uefi.sh --platform=HiKey --output=workspace`

### grubaa64.efi 

**description**: 

grubaa64.efi is used to load kernel image and dtb files from SD card, nandflash into RAM and start the kernel.
    
**target**: `<project root>/workspace/binary/arm64/grubaa64.efi`

**source**: `<project root>/grub`

build commands(supposedly, you are in `<project root>` currently:

`./estuary/submodules/build-grub.sh --output=./workspace`, if your host is not arm architecture, please execute`build-grub.sh --output=./workspace --cross=aarch64-linux-gnu-`

Note: more details about how to install gcc-linaro-aarch64-linux-gnu-4.9-2014.09_linux, please refer to https://github.com/open-estuary/estuary/blob/master/doc/Toolchains_Guide.4All.md.

### Image 
### hi6220-hikey.dtb 

**descriptions**: Image is the kernel executable program, and hi6220-hikey.dtb is the device tree binary.

**target**: 
Image in `<project root>/workspace/binary/arm64/Image`

hi6220-hikey.dtb in `<project root>/workspace/binary/HiKey/hi6220-hikey.dtb`

**source**: `<project root>/kernel`

build commands(supposedly, you are in `<project root>` currently:

`./estuary/submodules/build-kernel.sh --platform=HiKey --output=workspace`, if your host is not arm architecture, please execute `./estuary/submodules/build-kernel.sh --platform=HiKey --output=workspace --cross=aarch64-linux-gnu-`.

Note: more details about how to install gcc-linaro-aarch64-linux-gnu-4.9-2014.09_linux, please refer to https://github.com/open-estuary/estuary/blob/master/doc/Toolchains_Guide.4All.md.

If you get more information about uefi, please visit https://github.com/96boards/documentation/wiki/HiKeyUEFI

More detail information about how to deploy target system into HiKey board, please refer to [Deploy_Manual.4HiKey.md](https://github.com/open-estuary/estuary/blob/master/doc/Deploy_Manual.4HiKey.md).

More detail information about how to config this WiFi function into HiKey board, please refer to [Setup_HiKey_Wifi_Env.md](https://github.com/open-estuary/estuary/blob/master/doc/Setup_HiKey_WiFi_Env.4HiKey.md).

More detail information about distributions, please refer to [Distributions_Guider.md](https://github.com/open-estuary/estuary/blob/master/doc/Distributions_Guide.4All.md).

More detail information about toolchains, please refer to [Toolchains_Guider.md](https://github.com/open-estuary/estuary/blob/master/doc/Toolchains_Guide.4All.md).

More detail information about how to benchmark system, please refer to [Caliper_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/Caliper_Manual.4All.md).

More detail information about how to access remote boards in OpenLab, please refer to [Boards_in_OpenLab](http://open-estuary.org/accessing-boards-in-open-lab/).
