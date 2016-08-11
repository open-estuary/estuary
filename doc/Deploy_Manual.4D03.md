* [Introduction](#1)
* [Preparation](#2)
   * [Prerequisite](#2.1)
   * [Check the hardware board](#2.2)
   * [Upgrade UEFI and trust firmware](#2.3)
   * [Upgrade DTB file](#2.4)
* [Bring up System](#3)
   * [Boot via ESL](#3.1)
   * [Boot via PXE](#3.2)
   * [Boot via NFS](#3.3)
   * [Boot via DISK(SAS/USB/SATA)](#3.4)
   * [Boot via ACPI](#3.5)

<h2 id="1">Introduction</h2>

This documentation describes how to get, build, deploy and bring up target system based Estuary Project, it will help you to make your Estuary Environment setup from ZERO.

All following sections will take the D03 board as example, other boards have the similar steps to do, for more detail difference between them, please refer to Hardware Boards sections in http://open-estuary.com/hardware-boards/.

<h2 id="2">Preparation</h2>

<h3 id="2.1">Prerequisite</h3>

Local network: To connect hardware boards and host machine, so that they can communicate each other.

Serial cable: To connect hardware board’s serial port to host machine, so that you can access the target board’s UART in host machine.

Two methods are provided to **connect the board's UART port to a host machine**:

**Method 1** : connect the board's UART in openlab environment

 Use `board_connect` command.(Details please refer to `board_connect --help`)

**Method 2** : directly connect the board by UART cable

   a. Connect the board's UART port to a host machine with a serial cable.<br>
   b. Install a serial port application in host machine, e.g.: kermit or minicom.<br>
   c. Config serial port setting:115200/8/N/1 on host machine.<br>

For more details, please refer to [UEFI_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/UEFI_Manual.4D03.md)
"Upgrade UEFI" chapter.

<h3 id="2.2">Check the hardware board</h3>

Hardware board should be ready and checked carefully to make sure it is available, more detail information about different hardware board, please refer to http://open-estuary.org/d03/.

<h3 id="2.3">Upgrade UEFI and trust firmware</h3>

You can upgrade UEFI and trust firmare yourself based on FTP service, but this is not necessary. If you really want to do it, please refer to [UEFI_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/UEFI_Manual.4D03.md).

<h3 id="2.4">Upgrade DTB file(Necessary step) </h3>

Because this dtb file is important to this D03 boards, firstly you must flash this DTB file
into spiflash before any methods of bringing up systerm. 

 "EFI internal shell" mode and "Embedded Boot Loader(EBL)" mode often used to upgrade DTB file , about how to enter two modes and how to switch between them, please refer to [UEFI_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/UEFI_Manual.4D03.md)  "Upgarde UEFI" chapter..

1. IP address config at "EFI Internal Shell" mode (Optional, you can ignore this step if DHCP works well)

   Press any key except "enter" key to enter into UEFI main menu. Select "Boot Manager"->"EFI Internal Shell".
  ```
 # Config board's IP address
 ifconfig -s eth0 static <IP address> <mask> <gateway> 
   ```
  e.g.: 
  
  `ifconfig -s eth0 static 192.168.1.4 255.255.255.0 192.168.1.1`

2. Download dtb file from FTP at "Embedded Boot Loader(EBL)" mode

   Enter "exit" from "EFI internal shell" to the UEFI main menu and choose "Boot Manager"-> "Embedded Boot Loader(EBL)"after setting the IP address done. 
   ```
   # Download file from FTP server to target board's RAM
   provision <server IP> -u <ftp user name> -p <ftp password> -f <dtb file> -a <download target address>
   # Write data into FLASH
   sfcerase <source address> <target address> <data length>
   sfcwrite <source address> <target address> <data length>
   ```
   e.g.:
   ```
   provision 192.168.1.107 -u sch -p aaa -f hip06-d03.dtb -a 0x100000
   sfcerase 0x7C0000 0x10000
   sfcwrite 0x100000 0x7C0000 0x10000
   ```
3. Reboot your D03 board

   You must reboot your D03 board after above two steps, this new DTB file will be used on booting board.

   Note: It is necessary to flash the DTB file to SPI flash to solve a known MAC address duplicate Issue.Also it is to be noted that the DTB file should not be input in the Grub config file. So if you wish to use a modified DTB file, then you should always have it flashed to SPI flash before bootup.

<h2 id="3">Bring up System</h2>

There are several methods to bring up system, you can select following anyone fitting you to boot up.

<h3 id="3.1">Boot via ESL</h3>

In this boot mode, the kernel image, dtb file and rootfs file should be downloaded into
RAM at first and then start the system by ESL.
After reboot or power off, all downloaded data will be lost.
This boot mode is just used for debugging.

Boot D03 to UEFI menu. Select "Boot Manager"->"Eebedded Boot Loader(EBL)" and type the
follow commands in EBL:

1. Download Image binary file from FTP server to target board's RAM
   ```
    # Download Image binary file from FTP server to target board's RAM
    provision <server IP> -u <ftp user name> -p <ftp password> -f <Image binary file> -a <download target address>
   ```
    e.g.: 
    
    `provision 192.168.1.107 -u sch -p aaa -f Image -a 0x80000`
 
2. Download dtb file from FTP server to target board's RAM
   ```
   # Download dtb file from FTP server to target board's RAM
    provision <server IP> -u <ftp user name> -p <ftp password> -f <dtb file> -a <download target address>
     ```
   e.g.: 
   
    `provision 192.168.1.107 -u sch -p aaa -f hip06-d03.dtb -a 0x06000000`
 
3. Download rootfs file from FTP server
    ```
    # Download rootfs file from FTP server to target board's RAM
    provision <server IP> -u <ftp user name> -p <ftp password> -f <rootfs file> -a <download target address>
     ```
     e.g.:
  
    `provision 192.168.1.107 -u sch -p aaa -f mini-rootfs-arm64.cpio.gz -a 0x07000000`
 
4. Start operating system
  
  Type "exit" to exit EBL. Select "Boot Manager"->"ESL Start OS" menu to start operating system.

<h3 id="3.2">Boot via PXE</h3>

In this boot mode, the UEFI will get grub from PXE server.The grub will get the configuration file from TFTP service configured by PXE server.

1. Setup PXE environment on host

   Enable both DHCP and TFTP services on one of your host machines according to [Setup_PXE_Env_on_Host.md](https://github.com/open-estuary/estuary/blob/master/doc/Setup_PXE_Env_on_Host.4All.md).
   
2. Reboot and press anykey except "enter" to enter UEFI Boot Menu

3. Select boot option "Boot Manager"->"EFI Network `<No>`" boot option and press "Enter".
  
   Note:
     
    If you are connecting the D03 boards of openlab, please select "EFI Network 2".

    The value of `<No>` is depended on which D03 GE port is connected. D03 board support 4 on-board network ports at maximun.To enable any one of them by connecting to network cable or optical fiber. From left to right, followed by two GE ports, two 10GE ports which corresponding to UEFI startup interface are EFI Network 2, EFI Network 3, EFI Network 0, EFI Network 1.
  
4. After several seconds, D03 will boot by PXE automatically.

To config the grub.cfg to support PXE boot, please refer to  [Grub_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/Grub_Manual.4All.md).

<h3 id="3.3">Boot via NFS</h3>

In this boot mode, the root parameter in grub.cfg menuentry will set to /dev/nfs and nfsroot will be set to the path of rootfs on NFS server. You can use `"showmount -e <server ip address>" `to list the exported NFS directories on the NFS server.
 
D03 supports booting via NFS, you can try it as following steps:

1. Enable DHCP, TFTP and NFS service according to [Setup_PXE_Env_on_Host.md](https://github.com/open-estuary/estuary/blob/master/doc/Setup_PXE_Env_on_Host.4All.md).

2. Get and config grub file to support NFS boot according to [Grub_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/Grub_Manual.4All.md).

3. Reboot D03 and press anykey except "enter" to enter UEFI Boot Menu

4. Select boot option "Boot Manager"->"EFI Network `<No>`" boot option to enter.
  
  Note: The value of `<No>` is depended on which D03 GE port is connected.
   
<h3 id="3.4">Boot via DISK(SAS/USB/SATA)</h3>

D03 board supports booting via SAS, USB and SATA by default. The UEFI will directly get the grub from the EFI system partition on the hard disk. The grub will load the grub configuration file from the EFI system partition. So grubaa64.efi, grub.cfg, Image and different estuary release distributions are stored on disk.

1. Boot by PXE (please refer to "Boot via PXE") to part and format hardware disk before booting D03 board

   Format hardware disk, e.g.: 
   
   `sudo mkfs.vfat /dev/sda1`; `sudo mkfs.ext4 /dev/sda2`
   
   Part hardware disk with `"sudo fdisk /dev/sda"` as follow:<br>
    add a gpt to this disk : 
       
      `fdisk /dev/sda` 
        
      `g`-------add a gpt partition
       
     add some EFI partition : 
       
      `n`-------add a partition
       
      `1`-------the number of partition
     
      type "Enter" key ------ First sector
       
      `+200M`---------Last sector, size of partition
       
      `t`-------change the type of partition
       
       EFI system
      
       add some another partition  `...`<br>
       save the change           : `w`<br>
       format EFI partition  : `sudo mkfs.vfat /dev/sda1`<br>
       format ext4 partition : `sudo mkfs.ext4 /dev/sda2`<br>
       
       ```
          +---------+-----------+--------------+------------------+
          | Name    |   Size    |    Type      |   USB/SAS/SATA   |
          +---------+-----------+--------------+------------------+
          | sda1    |   200M    |  EFI system  |   EFI            |
          +---------+-----------+--------------+------------------+
          | sda2    |   10G     |    ext4      | linux filesystem |
          +---------+-----------+--------------+------------------+
          | sda3    |   10G     |    ext4      | linux filesystem |
          +---------+-----------+--------------+------------------+
          | sda4    |   10G     |    ext4      | linux filesystem |
          +---------+-----------+--------------+------------------+
          | sda5    |rest space |    ext4      | linux swap       |
          +---------+-----------+--------------+------------------+
       ```
        
   Note: EFI partition must be a fat filesystem, so you should format sda1 with `“sudo mkfs.vfat /dev/sda1″`.

2. Download files and store them into hardware disk as below.

  （SAS/USB/SATA）Related files are placed as follow: 
   ```
       sda1: -------EFI
              |       |
              |       GRUB2------grubaa64.efi  //grub binary file
              |
              |-------------grub.cfg           //grub config file
              |
              |-------------Image          //kernel binary Image
        sda2: Ubuntu distribution
        sda3: Fedora distribution
   ```     
    To get kernel image and dtb file, please refer to [Readme.md](https://github.com/open-estuary/estuary/blob/master/doc/Readme.4D03.md).<br>
    To get and config grub and grub.cfg, please refer to [Grub_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/Grub_Manual.4All.md).<br>
    To get different distributions, please refer to [Distributions_Guider](https://github.com/open-estuary/estuary/blob/master/doc/Distributions_Guide.4All.md).<br> 
    
3. Boot the board via SAS/USB/SATA

   a. Modify grub config file(please refer to [Grub_Manual.4All.md](https://github.com/open-estuary/estuary/blob/master/doc/Grub_Manual.4All.md))<br>
       e.g.: <br>
       grub.cfg file for official versions after V2.2 is modified as follow:
       ``` 
	        # Sample GRUB configuration file
	        #
	        # Boot automatically after 5 secs.
	        set timeout=5
	        # By default, boot the Estuary with Ubuntu filesystem
	        set default=ubuntu
	        # For booting GNU/Linux

           menuentry "ubuntu" --id ubuntu {
           search --no-floppy --fs-uuid --set=root <UUID>
           linux /Image rdinit=/init root=PARTUUID=<PARTUUID> rootwait rootfstype=ext4 rw console=ttyS0,115200 earlycon=hisilpcuart,mmio,0xa01b0000,0,0x2f8 ip=dhcp
            }
       ```

       grub.cfg file for official V2.2 and previous versions is modified as follow:
       ```
                # Sample GRUB configuration file
                #
                # Boot automatically after 5 secs.
                set timeout=5
                # By default, boot the Estuary with Ubuntu filesystem
                set default=ubuntu
                # For booting GNU/Linux

           menuentry "ubuntu" --id ubuntu {
           search --no-floppy --fs-uuid --set=root <UUID>
           linux /Image rdinit=/init root=PARTUUID=<PARTUUID> rootwait rootfstype=ext4 rw console=ttyS1,115200 earlycon=hisilpcuart,mmio,0xa01b0000,0,0x2f8 ip=dhcp
            }
       ```

       Note:<br>
        *  The value of console is `ttyS0` for official versions after V2.2. If you use official V2.2 and previous versions, the value of console is `ttyS1`
	* `<UUID> `means the UUID of that partition which your EFI System is located in.<br>
          `<PARTUUID>` means the PARTUUID of that partition which your linux distribution is located in. <br>
           To see the values of UUID and PARTUUID, please use the command: `$blkid`.<br>
	* If you want to use another linux distribution, please refer above steps.
            
  b. Reboot and press anykey except "enter" to enter UEFI main menu.

  c. For USB: Select "Boot Manager"-> "EFI USB Device"-> to enter grub selection menu.

    For SAS: Select "Boot Manager"-> "EFI Misc Device 1" to enter grub selection menu.

    For SATA: Select "Boot Manager"-> "EFI Hard Drive" to enter grub selection menu.

  
  d. Press arrow key up or down to select grub boot option to decide which distribution should boot.


<h3 id="3.5">Boot via ACPI</h3>

D03 also supports booting via ACPI, you can bring up this systerm which is similar with DTS mode, you must fix some point as follow:

1. Delete DTB file and don't burn DTB file

2. Set the parameters of booting via ACPI

you must add `"acpi=force"` property in `"linux=...."` line for "grub.cfg" file.

e.g.:
```shell
# Booting from NFS with Ubuntu rootfs
menuentry "D03 Ubuntu NFS(ACPI)" --id d03_ubuntu_nfs {
    set root=(tftp,192.168.1.107)
    linux /Image rdinit=/init console=ttyS0,115200 earlycon=hisilpcuart,mmio,0xa01b0000,0,0x2f8 root=/dev/nfs rw nfsroot=192.168.1.107:/home/ftp/user/rootfs_ubuntu64 ip=dhcp acpi=force
}
```

NOTE: you can get more information about setting grub.cfg from [Grub_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/Grub_Manual.4All.md).
