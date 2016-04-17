* [D01 Board Hardware Features](#1)
* [D01 Software Solution and Status](#2)
* [Major Components](#3)
   * [UEFI:](#3.1)
   * [BootWrapper](#3.2)
   * [GRUB](#3.3)
   * [EFI-STUB](#3.4)
   * [Kernel](#3.5)
    *[Ethernet Driver](#3.5.1)
    *[ VGIC](#3.5.2)  
    *[SMMU with SATA](#3.5.3)
    *[Reboot](#3.5.4)
   * [Linux Distributionsl](#3.6)
   * [ToolChain](#3.7)
* [D01 Hacking](#4)
   * [UEFI Hacking](#4.1)
    *[Compile UEFI](#4.1.1)
    *[Boot D01 to UEFI shell(EBL)](#4.1.2)
    *[Upgrade UEFI](#4.1.3)
    *[Restore the UEFI when the UEFI did not work](#4.1.4)
   * [BootWrapper Hacking](#4.2)
    *[Compile BootWrapper](#4.2.1)
    *[Upgrade Bootwrapper](#4.2.2)
   * [Grub Hacking](#4.3)
   * [Kernel Hacking](#4.4)
 * [Boot via NAND](#5)
   * [Upgrade kernel and NAND rootfs](#5.1)
   * [Boot into NAND rootfs(#5.2)
 * [Boot via NFS](#6)
   * [Boot into Ubuntu on SATA](#6.2)
 * [Boot via PXE](#7)
    * [Set up TFTP server on Ubuntu](#7.1)
    * [Set up DHCP server on Ubuntu](#7.2)
 * [Boot via EFI-stub](#8)
 * [Boot via GRUB](#9)
 * [KVM on D01](#10)
 * [Xen on D01](#11)
 * [Reference](#12)
 
<h2 id="1">D01 Board Hardware Features</h2>

Please refer D01 Hardware Details here

<h2 id="2">D01 Software Solution and Status</h2>

The software architecture on D01 is consisted of UEFI, BootWrapper, GRUB, EFI Stub, Kernel, Distributions and Toolchain. The big picture is like following:
```
      +--------------------------+ +-----+
      |  NANDRootfs Ubuntu       | |  T  |
      |  OpenSuse Debian Fedora  | |  o  |
      +--------------------------+ |  o  |
      |         Kernel           | |  l  |
      +-----------+              | |  C  |
      |    GRUB   |   EFI-STUB   | |  h  |
      +----+------+--------+-----+ |  a  |
      |    |  BootWrapper  |     | |  i  |
      |    +---------------+     | |  n  |
      |           UEFI           | |     |
      | +-------+-------+-----+  | |     |
      | | NANDC | SATAC | PXE |  | |     |
      | +-------+-------+-----+  | |     |
      +--------------------------+ +-----+
```
And you could download the binary from the link:

https://github.com/hisilicon/boards/tree/master/D01/release
```
    +------------------+------------------------------------+       
    |  filename        |    description                     |
    +------------------+------------------------------------+       
    |  D01.fd          |    UEFI binary                     |
    +------------------+------------------------------------+       
    |  .text           |    bootwrapper, HYP switch part    |   
    +------------------+------------------------------------+       
    |  .monitor        |    bootwrapper, monitor part       |
    +------------------+------------------------------------+       
    |  grub2.efi       |    grub binary                     |
    +------------------+------------------------------------+       
    |  grub.cfg        |    grub configure                  |       
    +------------------+------------------------------------+       
    |  .kernel         |    zImage, with dtb concatenatea   |   
    +------------------+------------------------------------+       
    |  zImage          |    kernel image                    |
    +------------------+------------------------------------+       
    |  hip04-d01.dtb   |    D01 device tree bianry          |   
    +------------------+------------------------------------+       
    |  .filesystem     |    initramfs stored in NAND        |   
    +------------------+------------------------------------+       
```
Linaro also provide a monthly release for it:

http://www.linaro.org/downloads/ 

<h2 id="3">Major Components</h2>

<h3 id="3.1">UEFI</h3>

Responsible for loading and booting kernelcould get the source code from following git tree

https://github.com/hisilicon/UEFI.git
https://git.linaro.org/landing-teams/working/hisilicon/uefi.git
https://git.linaro.org/uefi/linaro-edk2.git

And could download monthly binary from:

http://releases.linaro.org/latest/components/kernel/uefi-linaro

<h3 id="3.2">BootWrapper</h3>

Responsible for switching into HYP mode for slave corescould get the source code from following git tree

https://github.com/hisilicon/bootwrapper.git

And it is based on following git tree:

https://git.linaro.org/arm/models/boot-wrapper.git
https://github.com/virtualopensystems/boot-wrapper.git

<h3 id="3.3">GRUB</h3>

Responsible for loading kernelcould get the source code from following git tree

https://github.com/hisilicon/grub.git

And it is based on Leif’s grub:

http://bazaar.launchpad.net/~leif-lindholm/linaro-grub/arm-uefi

It is confrimed that we could not use the mainline grub:

git://git.savannah.gnu.org/grub.git

<h3 id="3.4">EFI-STUB</h3>

Responsible for adding PE HEAD into Kernel Image and making it like a UEFI application. In this case, UEFI could directly load and boot the kernel
from the FAT32 partion(because our UEFI SATA driver could only support this type) in the harddisk without GRUB.

<h3 id="3.5">Kernel</h3>

The operating system source code can be found from following git tree

https://github.com/hisilicon/linux-hisi.git tag:D01-3.18-release

https://git.linaro.org/landing-teams/working/hisilicon/kernel.git 
branch: integration-hilt-linux-linaro or integration-hilt-working-v3.14

https://git.linaro.org/kernel/linux-linaro-tracking.git
https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git

Most of the featuers have already merged into kernel mainline. But some of features is not accepted like: Ethernet driver, VGIC, SMMU with SATA
and reboot.

Following is the commits list need to maintain by ourselves

<h4 id="3.5.1">Ethernet Driver</h4>

791a2af hip04: dts: update eth resource

a162505 hip04: dts: add mdio resource

90edc4d hip04: dts: add ether resource

bbdab0b hip04: serdes: fix build error due to macro __DATE__

2d326b0 misc: add sirdes driver

<h4 id="3.5.2">VGIC</h4>

http://article.gmane.org/gmane.linux.ports.arm.kernel/344932/raw

<h4 id="3.5.3">SMMU with SATA</h4>

commits: e5baf66 2921667 on branch: testing/0429-for-xuwei in https://git.linaro.org/landing-teams/working/hisilicon/kernel.git

<h4 id="3.5.4">Reboot</h4>

commit: 4469f84 at branch: integration-hilt-d01 in https://git.linaro.org/landing-teams/working/hisilicon/kernel.git

And you could run following commands to pick them up:

```shell
git cherry-pick --strategy recursive -X theirs 2d326b0
git cherry-pick bbdab0b
git cherry-pick --strategy recursive -X theirs 90edc4d
git cherry-pick --strategy recursive -X theirs a162505
git cherry-pick --strategy recursive -X theirs 791a2af 
```
<h3 id="3.6">Linux Distributions</h3>

Each distribution is downloaded from itself website or from Linaro.
```
+-----------+------------------------------------------------+
|  Ubuntu   |  http://releases.linaro.org/latest/ubuntu      |
+-----------+------------------------------------------------+
|  OpenSuse |                                                |
+-----------+------------------------------------------------+
|  Fedora   |                                                |
+-----------+------------------------------------------------+
|  Debian   |                                                |
+-----------+------------------------------------------------+
```
But the NAND Rootfs is created by ourselves and it could download from:

https://github.com/hisilicon/boards/blob/master/D01/release/.filesystem
http://releases.linaro.org/latest/ubuntu/boards/lt-d01/.filesystem 

<h3 id="3.7">ToolChain</h3>
 
Used to compile and debug and downdload from

http://releases.linaro.org/14.09/components/toolchain/binaries/gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux.tar.xz       

<h2 id="4">D01 Hacking</h2>

<h3 id="4.1">UEFI Hacking</h3>

FTP protocol is used in D01 UEFI for file downloading. So, before this step, please make sure you have a working FTP server running in your local network. And D01 can use FTP to get files from network.

<h4 id="4..1.1">Compile UEFI</h4>

A general guideline is here: https://wiki.linaro.org/LEG/Engineering/Kernel/UEFI/build

For simplicity, to build UEFI for D01 board, follow these steps:

 Prepare build environment on your Ubuntu PC:
 
 ```shell
   sudo apt-get install uuid-dev build-essential gcc-arm-linux-gnueabi
    sudo apt-get install gcc-arm-linux-gnueabihf
```
 Clone Linaro’s uefi tools.
 ```shell
    cd ~
    git clone git://git.linaro.org/uefi/uefi-tools.git
    export PATH=$PATH:~/uefi-tools.git
  ```
   Enter uefi-tools, add a build item for D01. Note: This will be submitted into Linaro uefi-tools.git soon.
   If you found it already there, don’t panic.
   
 ```shell
 diff --git a/platforms.config b/platforms.config
    index 2c29a29..7710b80 100755
    --- a/platforms.config
    +++ b/platforms.config
    @@ -132,3 +132,10 @@ BUILDFLAGS=
     DSC=BeagleBoardPkg/BeagleBoardPkg.dsc
     ARCH=ARM
     [/]
    +
    +[d01]
    +LONGNAME=HiSilicon D01 Cortex-A15 16-cores
    +BUILDFLAGS=-D EDK2_ARMVE_STANDALONE=1
    +DSC=HisiPkg/D01BoardPkg/D01BoardPkg.dsc
    +ARCH=ARM
    +[/]
```

 download D01 UEFI source code from above section
    Enter your uefi source code folder, and run uefi-build.sh to build.
    
  ```shell
    cd your/path/to/uefi/source;
    uefi-build.sh -b DEBUG d01
  ```
  Note: for a release version. 
  
  uefi-build.sh -b RELEASE d01
  
   When finished, you can find the build result here:
   
   `ls -la Build/D01/DEBUG_GCC46/FV/D01.fd`
    
    Note: for a release version:
    
   `ls -la Build/D01/RELEASE_GCC46/FV/D01.fd`
   
<h4 id="4.1.2">Boot D01 to UEFI shell(EBL)</h4>
  
  
<h4 id="4.1.3">Upgrade UEFI</h4>
   
<h4 id="4.1.4">Restore the UEFI when the UEFI did not work</h4>

In case of failure in UEFI, you can always switch to a factory default (known-good, non-erasable) UEFI by shorting Pin 2 and Pin 3 of J39.
(Refer to Mark 18 of d01-portrait.png)

```
Power off the board, disconnect power supply
    Short Pin 2 and Pin 3 of J39 (Leave Pin 1 unconnected)
    On your client (minicom or similar tools),
    change UART baudrate to 9600 or 115200
    Apply power to the board, turn it on
    Following above steps to upgrade UEFI
    Power off the board, disconnect power supply
    Short Pin 1 and Pin 2 of J39 (Leave Pin 3 unconnected)
    On your client, change UART baudrate to 115200. (That’s usually the case.
    Unless you know that you are using a 9600 baudrate UEFI.)
```

<h3 id="4.2">BootWrapper Hacking</h3>
   
<h4 id="4.2.1">Compile BootWrapper</h4>

Download BootWrapper source code from above section

use make command to compile and it will generate .text and .monitor

<h4 id="4.2.2">Upgrade Bootwrapper</h4>

Boot D01 to UEFI shell. And in EBL, type in these commands:

    IP address config: > ifconfig -s eth0 [IP.address] [mask] [gateway] eg. ifconfig -s eth0 192.168.10.155 255.255.255.0 192.168.10.1
    download BootWrapper binary from FTP server (Note, filenames must not be changed):
```
  > provision [server.IP] -u [user.name] -p [passwd] -f .text
  > provision [server.IP] -u [user.name] -p [passwd] -f .monitor
```
   eg. provision 192.168.10.6 -u dj -p dj -f .text
   
   eg. provision 192.168.10.6 -u dj -p dj -f .monitor
   
    Reboot D01
    
    
<h3 id="4.3">Grub Hacking</h3>   

Prepare build environment on your Ubuntu PC:

    sudo apt-get install autoconf autogen automake bison flex libfreetype6 libfreetype6-dev

    Download Grub source code from above section
    Run following commands to build:
    
 ```shell
    cd grub
    ./autogen.sh
    CROSS_COMPILE=arm-linux-gnueabihf- ./configure --target=arm-linux-gnueabihf --with-platform=efi --prefix=$HOME/grub2-build/
    make && make install
 ```   
 
<h3 id="4.4">Kernel Hacking</h3> 

 Download kernel source code from above section
 Use following command to compile:
```shell
    make  ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- O=../linux-next.build hisi_defconfig
    make  ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- O=../linux-next.build -j8 zImage
    make  ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- O=../linux-next.build hip04-d01.dtb
    cat ../linux-next.build/arch/arm/boot/zImage ../linux-next.build/arch/arm/boot/dts/hip04-d01.dtb > /$(FTP-server-path)/.kernel
```

<h2 id="5">Boot via NAND</h2> 

if booting via NAND, could use following method to upgrade kernel and NAND rootfs. And by changing the command lineto boot into different root filesystem.
Upgrade kernel and NAND rootfs

Boot D01 to UEFI shell. And in EBL, type in these commands:

    IP address config: > ifconfig -s eth0 [IP.address] [mask] [gateway] eg. ifconfig -s eth0 192.168.10.155 255.255.255.0 192.168.10.1
    download kernel binary from FTP server (Note, filenames must not be changed):

   ```shell
    > provision [server.IP] -u [user.name] -p [passwd] -f .filesystem
    > provision [server.IP] -u [user.name] -p [passwd] -f .kernel
  ```
      eg. provision 192.168.10.6 -u dj -p dj -f .filesystem
      
      eg. provision 192.168.10.6 -u dj -p dj -f .kernel

    Reboot D01
