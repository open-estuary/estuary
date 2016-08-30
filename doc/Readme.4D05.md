This is the readme file for D05 platform

After you executed `./estuary/build.sh --file=./estuary/estuarycfg.json --builddir=./workspace` for D05, all targets files will be produced. they are:

### UEFI_D05.fd 

**description**: UEFI_D05.fd is the UEFI bios for D05 platform.

**target**: `<project root>/workspace/binary/D05/UEFI_D05.fd`

**source**: `<project root>/uefi`

build commands(supposedly, you are in `<project root>` currently):
```shell
./estuary/submodules/build-uefi.sh --platform=D05 --output=workspace
```

### grubaa64.efi 

**description**: 

grubaa64.efi is used to load kernel image and dtb files from SATA, SAS, USB Disk, or NFS into RAM and start the kernel.
    
**target**: `<project root>/workspace/binary/arm64/grubaa64.efi`

**source**: `<project root>/grub`

build commands(supposedly, you are in `<project root>` currently):

`./estuary/submodules/build-grub.sh --output=./workspace`, if your host is not arm architecture, please execute`build-grub.sh --output=./workspace --cross=aarch64-linux-gnu-`

Note: more details about how to install gcc-linaro-aarch64-linux-gnu-4.9-2014.09_linux, please refer to https://github.com/open-estuary/estuary/blob/master/doc/Toolchains_Guide.4All.md.

### Image 

**descriptions**: Image is the kernel executable program.

**target**:
 
Image in `<project root>/workspace/binary/arm64/Image`

**source**: `<project root>/kernel`

build commands(supposedly, you are in `<project root>` currently):

`./estuary/submodules/build-kernel.sh --platform=D05 --output=workspace`, if your host is not arm architecture, please execute `./estuary/submodules/build-kernel.sh --platform=D05 --output=workspace --cross=aarch64-linux-gnu-`.

Note: more details about how to install gcc-linaro-aarch64-linux-gnu-4.9-2014.09_linux, please refer to https://github.com/open-estuary/estuary/blob/master/doc/Toolchains_Guide.4All.md.

More detail about distributions, please refer to [Distributions_Guide.md](https://github.com/open-estuary/estuary/blob/master/doc/Distributions_Guide.4All.md).

More detail about toolchains, please refer to [Toolchains_Guide.md](https://github.com/open-estuary/estuary/blob/master/doc/Toolchains_Guide.4All.md).

More detail about how to deploy target system into D05 board, please refer to [Deployment_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/Deploy_Manual.4D05.md).

More detail about how to debug, analyse, diagnose system, please refer to [Armor_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/Armor_Manual.4All.md).

More detail about how to benchmark system, please refer to [Caliper_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/Caliper_Manual.4All.md).

More detail about how to access remote boards in OpenLab, please refer to [Boards_in_OpenLab](http://open-estuary.org/accessing-boards-in-open-lab/).
