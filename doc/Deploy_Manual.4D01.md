* [Introduction](#1)
* [Preparation](#2)
   * [Prerequisite](#2.1)
   * [Check the hardware board](#2.2)
   * [Upgrade UEFI and trust firmware](#2.3)
   * [Show & change kernel cmdline in UEFI](#2.4)
* [Bring up System](#3)
   * [Boot via NORFLASH](#3.1)
   * [Boot via PXE](#3.2)
   * [Boot via NORFLASH with NFS as rootfs](#3.3)
   * [Boot via NORFLASH with HD as rootfs](#3.4)
   * [Boot via EFI-STUB](#3.5)
   * [Boot via GRUB](#3.6)
   * [KVM on D01](#3.7)


<h2 id="1">Introduction</h2>
This documentation describes how to get, build, deploy and bring up target system based Estuary Project, it will help you to make your Estuary Environment setup from ZERO.

All following sections will take the D01 board as example, other boards have the similar steps to do, for more detail difference between them, please refer to Hardware Boards sections in http://open-estuary.com/hardware-boards/.

<h2 id="2">Preparation</h2>

<h3 id="2.1">Prerequisite</h3>

Local network: To connect hardware boards and host machine, so that they can communicate each other.

Serial cable: To connect hardware board’s serial port to host machine, so that you can access the target board’s UART in host machine.

<h3 id="2.2">Check the hardware board</h3>

Hardware board should be ready and checked carefully to make sure it is available, more detail information about different hardware board, please refer to http://open-estuary.com/d01-2/.

<h3 id="2.3">Upgrade UEFI and trust firmware</h3>
You can upgrade UEFI and trust firmare yourself based on FTP service, but this is not necessary. If you really want to do it, please refer to [UEFI_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/UEFI_Manual.4D01.md).

<h3 id="2.4">Show & change kernel cmdline in UEFI</h3>

1. Boot D01 to enter UEFI "EBL".
   We will often do some commands UEFI "EBL" after here, about how to enter it, please refer to [UEFI_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/UEFI_Manual.4D01.md).

2. Use getlinuxatag to see current kernel parameter

   `getlinuxatag`
3. Use changelinuxatag to change kernel cmdline to this

   ```
   changelinuxatag
      ...
   console=ttyS0,115200 initrd=0x10d00000,0x18000000 rdinit=/linuxrc earlyprintk
      ...
   ```
4. Use setlinuxatag to save comandline to FLASH

   `setlinuxatag`
5. Reboot the board.

<h2 id="3"> Bring up System</h2>

There are several methods to bring up system, you can select following anyone fitting you to boot up.

<h3 id="3.1">Boot via NORFLASH</h3>

 Boot D01 to UEFI "EBL", and type the following commands in "EBL":
 
  1. IP address config
     ```
     # Config board's IP address
     ifconfig -s eth0 <IP address> <mask> <gateway>
   ```
   e.g.: 
   
  ` ifconfig -s eth0 192.168.1.4 255.255.255.0 192.168.1.1`
  
  2. Download .kernel binary file from FTP
     ```
     # Download file from FTP server to target board's Flash
     provision <server IP> -u <ftp user name> -p <ftp password> -f <.kernel image file>
     # Write data into NORFLASH
     norwfmem <source address> <target address> <data length>
    ```
     e.g.:
   
    `provision 192.168.1.107 -u sch -p aaa -f .kernel`
   
  3. Download rootfs file from FTP
 
    ```
    # Download fiel from FTP server to target board's Flash
    provision <server IP> -u <ftp user name> -p <ftp password> -f <rootfs image>
   ```
     e.g.:
    
    `provision 192.168.1.107 -u sch -p aaa -f .filesystem`
    
  4. Change command line as follows according to "Show & change kernel cmdline in UEFI"
 
    `console=ttyS0,115200 initrd=0x10d00000,0x18000000 rdinit=/linuxrc earlyprintk`

  5. Reboot the board.
    Note: the name of ".kernel" and ".filesystem" can not be changed!
    To get all binaries mentioned above, please refer to [readme.md](https://github.com/open-estuary/estuary/blob/master/doc/Readme.4D01.md).

<h3 id="3.2">Boot via PXE</h3>
 1. Setup PXE environment on host
    Enable both DHCP and TFTP services on one of your host machines according to [Setup_PXE_Env_on_Host.md](https://github.com/open-estuary/estuary/blob/master/doc/Setup_PXE_Env_on_Host.4All.md).

 2. Reboot and enter UEFI "Boot Menu".
   
      Do follows in UEF "Boot Menu":

    `2`    //Boot Manager<br>
    `1`    //Add Boot Device Entry<br>
    `3`    //PXE on MAC Address:...<br>
    `PXE`  //Description for this new Entry<br>
    `5`    //Return to main menu<br>
    `2`    //Boot from PXE<br>
       
 3. After several seconds, D01 will boot by PXE automatically.
    To config the grub.cfg to support PXE boot, please refer to [Grub_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/Grub_Manual.4All.md).

<h3 id="3.3">Boot via NORFLASH with NFS as rootfs</h3>

   D01 supports booting via NFS, you can try it as following steps:
    
   1. Enable DHCP, TFTP and NFS service according to [Setup_PXE_Env_on_Host.md](https://github.com/open-estuary/estuary/blob/master/doc/Setup_PXE_Env_on_Host.4All.md).
  
   2. Change command line as follow according in "Show & change kernel cmdline in UEFI"
      Change kernel cmdline to:
     ```
     console=ttyS0,115200 earlyprintk rootfstype=nfsroot root=/dev/nfs rw nfsroot=<NFS-server-ip>:<path-to-exported-NFS-files> ip=<client-ip>:<NFS-server-ip>:<gw-ip>:<netmask>::eth0:on:<dns0-ip>:<dns1-ip> user_debug=31 nfsrootdebug
     ```
  
     Here is an example: 
    ```
    console=ttyS0,115200 earlyprintk rootfstype=nfsroot root=/dev/nfs rw nfsroot=192.168.1.107:/Users/docularxu/Downloads/mnt ip=192.168.1.150:192.168.1.107:192.168.1.1:255.255.255.0::eth0:on:192.168.1.1:8.8.8.8 user_debug=31 nfsrootdebug
    ```

   Note, this is an example. Please change the values according to your local environment. Explanation of each parameter can be found in kernel source Documentations. Like:
   
   `ip=<client-ip>:<server-ip>:<gw-ip>:<netmask>:<hostname>:<device>:<autoconf>:<dns0-ip>:<dns1-ip>`
   
   3. Reboot the board. 
   
<h3 id="3.4">Boot via NORFLASH with HD as rootfs</h3>
This part will tell you how to boot D01 via hardware disk with ".kernel" image stored in NORFLASH.<br>
In my case, my hardware disk only has one partition: sda1(Ubuntu rootfs).

   1. Boot by NORFLASH, PXE or NFS firstly according above descriptions.
      
   2. Part and format hardware disk
       Format hardware disk, e.g.: 
         `sudo mkfs.vfat /dev/sda1;` 
         `sudo mkfs.ext4 /dev/sda2`
    
       Partition hardware disk with "sudo fdisk /dev/sda" as follow:
      ```
       +---------+-----------+--------------+------------------+
       | Name    |   Size    |    Type      |   Tag            |
       +---------+-----------+--------------+------------------+
       | sda1    |   200M    |  W95 FAT32   |   MBR            |
       +---------+-----------+--------------+------------------+
       | sda2    |   10G     |    ext4      | linux filesystem |
       +---------+-----------+--------------+------------------+
    ```
    Note: MBR partition must be a fat filesystem, so you should format sda1 with 
    `“sudo mkfs.vfat /dev/sda1″`.
   
   3. Download Ubuntu distribution from FTP server and uncompress it into /dev/sda2.
       ```
       sda1: Empty
       sda2: Ubuntu distribution
       ```
       To get different distributions, please refer to [Distributions_Guider.md](https://github.com/open-estuary/estuary/blob/master/doc/Distributions_Guide.4All.md). 
   
   4. Reboot and enter UEFI "EBL" Shell.
    
   5. Change kernel cmdline as follow according to "Show & change kernel cmdline in UEFI"
      ```
      console=ttyS0,115200 root=/dev/sda2 rootfstype=ext4 rw earlyprintk ip=192.168.1.150:192.168.1.107:192.168.1.1:255.255.255.0::eth0:on:192.168.1.1:8.8.8.8
      ```
       This is just an example, maybe you need change above parameters according your real local environment.
       
   6. Reboot the board.   
    
<h3 id="3.5">Boot via EFI-STUB</h3>
  1. Rebuild kernel to produce zImage_D01 with "EFI-STUB" option
  
  2. Part and format the hardware disk firstly just like above section "Boot via NORFLASH with HD as rootfs".

  3. Download the corresponding files from FTP server and store them into hardware disk as below.
     ```
        sda1: |-------------zImage_D01         //kernel binary Image for D01
              |
              |-------------hip04-d01.dtb      //device tree binary for D01
        sda2: Ubuntu distribution
    ```
    To get kernel zImage_D01 and dtb file, please refer to [Readme.md](https://github.com/open-estuary/estuary/blob/master/doc/Readme.4D01.md).<br>
    To get different distributions, please refer to [Distributions_Guider.md](https://github.com/open-estuary/estuary/blob/master/doc/Distributions_Guide.4All.md).<br>

  4. Launch EFI-stub Kernel in the UEFI shell
 
    a. boot the board.<br>
    b. Press `s`to Start Boot Menu.<br>
    c. Press `4` to select "Shell" option.<br>
    d. Shell>` FS0:`<br>
    f. FS0:\> `zImage_D01 dtb=hip04-d01.dtb console=ttyS0,115200 root=/dev/sda2 rw earlyprintk`
   
Then the board will boot from kernel with EFI-stub.

<h3 id="3.6">Boot via GRUB</h3>

 1. Part and format the hardware disk firstly just like above section "Boot via NORFLASH with HD as rootfs".

 2. Download the corresponding files from ftp and store them into hardware disk as below.
   ```
        sda1: |-----EFI
              |       |
              |     GRUB2-----grubarm32.efi      //grub binary file for ARM32 architecture
              |
              |-------------grub.cfg           //grub config file
              |
              |-------------zImage_D01         //kernel binary Image for D01
              |
              |-------------hip04-d01.dtb      //device tree binary for D01
        sda2: Ubuntu distribution
 ```
   To get kernel zImage_D01 and dtb file, please refer to [Readme.md](https://github.com/open-estuary/estuary/blob/master/doc/Readme.4D01.md).<br>
   To get and config grub and grub.cfg, please refer to [Grub_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/Grub_Manual.4All.md).<br>
   To get different distributions, please refer to [Distributions_Guider.md](https://github.com/open-estuary/estuary/blob/master/doc/Distributions_Guide.4All.md).<br>

 3. Reboot board and enter UEFI Shell, then input these commands in turn:
    
      `2`     //Boot Manager<br>
      `1`      //Add Boot Device Entry<br>
      `2`     //Pci(0x0,0x0)/Sata(0x1,0x0,0x0)...<br>
      `grubarm32.efi`  //File path of the EFI Application or the kernel<br>
      `y`     //Is an EFI Application? [y/n]<br>
      `y`      //Is your application is an OS loader? [y/n]<br>
      `5`      //Return to main menu<br>
      `3`      //GRUB
   
 4. Then the board will boot according configurations in grub.cfg
  
<h3 id="3.7">KVM on D01</h3>
Host Kernel on D01 is already support KVM. steps to build kernel could refer to Kernal hacking.

Steps to build and run guest:

  Clone the Torvalds kernel

  `git clone git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git`

  Checkout to v3.12 branch
 
  `git checkout -b linux-3.12 v3.12`
 
 Cross compile the kernel
 ```
   make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- vexpress_defconfig
   make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j2
 ```
 Grab Pawel’s DTS tree: git://linux-arm.org/arm-dts.git
 ```
   git clone git://linux-arm.org/arm-dts.git
   git chechout -b v3_12 v3.12
 ```
 From your kernel tree, run:
 ```
  ./script/dtc/dtc -O dtb -o rtsm_ve-cortex_a15x4.dtb  wherever_your_arm-dts_tree_is/fast_models/rtsm_ve-cortex_a15x4.dts
 ```
  
 Launch QEMU on D01:
 ``` 
  qemu-system-arm -enable-kvm -kernel zImage -dtb rtsm_ve-cortex_a15x4.dtb -initrd initrd.cpio.gz -append "console=ttyAMA0 earlyprintk rdinit=/linuxrc" -nographic -machine vexpress-a15,kernel_irqchip=on -m 128 -smp 4 -cpu cortex-a15 -rtc base=localtime
  ```
