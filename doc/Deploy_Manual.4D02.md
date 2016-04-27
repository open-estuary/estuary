* [Introduction](#1)
* [Preparation](#2)
   * [Prerequisite](#2.1)
   * [Check the hardware board](#2.2)
   * [Upgrade UEFI and trust firmware](#2.3)
   * [Upgrade DTB file](#2.4)
* [Bring up System](#3)
   * [Boot via ESL](#3.1)
   * [Boot via NORFLASH](#3.2)
   * [Boot via PXE](#3.3)
   * [Boot via NFS](#3.4)
   * [Boot via DISK(SAS/USB/SATA) ](#3.5)
   * [Boot via ACPI](#3.6)
   
<h2 id="1">Introduction</h2>

This documentation describes how to get, build, deploy and bring up target system based Estuary Project, it will help you to make your Estuary Environment setup from ZERO.

All following sections will take the D02 board as example, other boards have the similar steps to do, for more detail difference between them, please refer to Hardware Boards sections in http://open-estuary.com/hardware-boards/.

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

For more details, please refer to [UEFI_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/UEFI_Manual.4D02.md)
"Upgrade UEFI" chapter.

<h3 id="2.2">Check the hardware board</h3>

Hardware board should be ready and checked carefully to make sure it is available, more detail information about different hardware board, please refer to http://open-estuary.com/d02-2/.

<h3 id="2.3">Upgrade UEFI and trust firmware</h3>

You can upgrade UEFI and trust firmare yourself based on FTP service, but this is not necessary. If you really want to do it, please refer to [UEFI_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/UEFI_Manual.4D02.md).

<h3 id="2.4">Upgrade DTB file(Necessary step)</h3>

 Because this dtb file is important to this D02 boards, firstly you must flash this DTB file
 into SPI flash before any methods of bringing up systerm. 
  
 "EFI internal shell" mode and "Embedded Boot Loader(EBL)" mode often used to upgrade DTB file , about how to enter two modes and how to switch between them, please refer to [UEFI_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/UEFI_Manual.4D02.md) "Upgarde UEFI" chapter.

1. IP address config at "EFI Internal Shell" mode(Optional, you can ignore this step if DHCP works well)

   Press any key except "enter" key to enter into UEFI main menu. Select "Boot Manager"->"EFI Internal Shell".
   
   ```
   # Config board's IP address
   ifconfig -s eth0 static <IP address> <mask> <gateway>
   ```
   e.g.: ifconfig -s eth0 static 192.168.1.4 255.255.255.0 192.168.1.1
 
 
2. Download dtb file from FTP at "Embedded Boot Loader(EBL)" mode

   Enter "exit" from "EFI Internal Shell" mode to the UEFI main menu and choose "Boot Manager"-> "Embedded Boot Loader(EBL)"after setting the IP address done. 

 ```
# Download file from FTP server to target board's RAM
provision <server IP> -u <ftp user name> -p <ftp password> -f <dtb file> -a <download target address>
```

 ```
# Write data into FLASH
 spiwfmem <source address> <target address> <data length>
 ```
 
 e.g.: provision 192.168.1.107 -u sch -p aaa -f hip05-d02.dtb -a 0x100000 <br>
 spiwfmem 0x100000 0x300000 0x100000

3. Reboot your D02 board

   You must reboot your D02 board after above two steps, this new DTB file will be used on booting board.

   Note: It is necessary to flash the DTB file to SPI flash to solve a known MAC address duplicate Issue.
   Also it is to be noted that the DTB file should not be input in the Grub config file. So if you
    wish to use a modified DTB file, then you should always have it flashed to SPI flash before bootup.

<h2 id="3">Bring up System</h2>

There are several methods to bring up system, you can select following anyone fitting you to boot up.

<h3 id="3.1">Boot via ESL</h3>

 In this boot mode, the kernel image, dtb file and rootfs file should be downloaded into RAM at first and then start the system by ESL.<br>
 After reboot or power off, all downloaded data will be lost.<br>
 This boot mode is just used for debugging.

 Boot D02 to UEFI main menu. Select "Boot Manager"->"Eembedded Boot Loader(EBL)" and type the follow commands in EBL:

1. Download Image binary file from FTP server to target board's RAM

 ```
# Download Image binary file from FTP server to target board's RAM
 provision <server IP> -u <ftp user name> -p <ftp password> -f <Image binary file> -a <download target address>
 ```
 e.g.: provision 192.168.1.107 -u sch -p aaa -f Image_D02 -a 0x80000
 
 
2. Download dtb file from FTP server to target board's RAM
 ```
 # Download dtb file from FTP server to target board's RAM
  provision <server IP> -u <ftp user name> -p <ftp password> -f <dtb file> -a <download target address>
 ```
  e.g.: provision 192.168.1.107 -u sch -p aaa -f hip05-d02.dtb -a 0x06000000
 
 
3. Download rootfs file from FTP server to target board's RAM
 ```
  # Download rootfs file from FTP server to target board's RAM
   provision <server IP> -u <ftp user name> -p <ftp password> -f <rootfs file> -a <download target address>
  ```
   e.g.: provision 192.168.1.107 -u sch -p aaa -f mini-rootfs-arm64.cpio.gz -a 0x07000000

 
4. Start operating system
  
  Type "exit" to exit EBL. Select "Boot Manager"->"ESL Start OS" menu to start operating system.

<h3 id="3.2">Boot via NORFLASH</h3>

 In this boot mode, kernel image, dtb file and rootfs file will be writen into NORFLASH. 
 Before the kernel start, the kernel image, dtb fille and rootfs file will be loaded into RAM from NORFLASH.

 Boot D02 to UEFI main menu. Select "Boot Manager"->"Eembedded Boot Loader(EBL)" and type the follow commands in EBL:

1. Download Image binary file from FTP
 ```
 # Download file from FTP server to target board's RAM
 provision <server IP> -u <ftp user name> -p <ftp password> -f <kernel image file> -a <download target address>
 ```
 
 ```
 # Write data into NORFLASH
 norwfmem <source address> <target address> <data length>
 ```
 e.g.: provision 192.168.1.107 -u sch -p aaa -f Image_D02 -a 0x100000<br>
 norwfmem 0x100000 0x100000 0x1f00000


2. Download rootfs file from FTP

 ```
  # Download file from FTP server to target board's RAM
  provision <server IP> -u <ftp user name> -p <ftp password> -f <rootfs image> -a <download target address>
  ```

 ```
 # Write data into NORFLASH
 norwfmem <source address> <target address> <data length>
   ```
 e.g.: provision 192.168.1.107 -u sch -p aaa -f mini-rootfs-arm64.cpio.gz -a 0x100000<br>
 norwfmem 0x100000 0x2000000 0x4000000

  
3. Reboot D02 and press anykey except "enter" to enter UEFI Boot Menu

4. Select "Boot Manager"->"FLASH Start OS" boot option and press "Enter"
 
To get all binaries mentioned above, please refer to [Readme.md](https://github.com/open-estuary/estuary/blob/master/doc/Readme.4D02.md).

<h3 id="3.3">Boot via PXE</h3>

In this boot mode, the UEFI will get grub from PXE server.

The grub will get the configuration file from TFTP service configured by PXE server.

1. Setup PXE environment on host

   Enable both DHCP and TFTP services on one of your host machines according to [Setup_PXE_Env_on_Host.md](https://github.com/open-estuary/estuary/blob/master/doc/Setup_PXE_Env_on_Host.4All.md).
   
2. Reboot and press anykey except "enter" to enter UEFI main Menu

3. Select "Boot Manager"->"EFI Network" and press "Enter".

4. After several seconds, D02 will boot by PXE automatically.

To config the grub.cfg to support PXE boot, please refer to [Grub_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/Grub_Manual.4All.md).

<h3 id="3.4">Boot via NFS</h3>

In this boot mode, the root parameter in grub.cfg menuentry will set to /dev/nfs and nfsroot will be set to the path of rootfs on NFS server.You can use `"showmount -e <server ip address>"` to list the exported NFS directories on the NFS server.

You can use "showmount -e <server ip address>" to list the exported NFS directories on the NFS server.

D02 supports booting via NFS, you can try it as following steps:

1. Enable DHCP, TFTP and NFS service according to [Setup_PXE_Env_on_Host.md](https://github.com/open-estuary/estuary/blob/master/doc/Setup_PXE_Env_on_Host.4All.md).

2. Get and config grub file to support NFS boot according to [Grub_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/Grub_Manual.4All.md).

3. Reboot D02 and press anykey except "enter" to enter UEFI main Menu

4. Select  "Boot Manager"->"EFI Network" to and press enter key.

<h3 id="3.5">Boot via DISK(SAS/USB/SATA)</h3>

D02 board supports booting via SAS and USB disk by default, if you want to boot via SATA, there are two different methods for you, one is to plug SATA disk into PCIE-to-SATA convert card(model:PEC-2024) which connect to D02 board, another is to connect SATA disk into SATA interface on D02 board directly. Usually the first is more stable than the second, so we suggest you to use the first method.

For SAS and USB, the UEFI will directly get the grub from the EFI system partition on the hard disk. The grub will load the grub configuration file from the EFI system partition. So grubaa64.efi, grub.cfg, Image and different estuary release distributions are stored on disk. But for SATA boot mode, the kernel image will be loaded from NORFLASH into RAM on target board. The root parameter passed to the kernel will be specified in hip05-d02.dts and it will point to the root partition on SATA disk.

1. Boot by PXE or NORFLASH(please refer to "#Boot via PXE" or "#Boot via NORFLASH") to part and format hardware disk before booting D02 board

   Format hardware disk, e.g.: `sudo mkfs.vfat /dev/sda1`; `sudo mkfs.ext4 /dev/sda2`
   
   Part hardware disk with `"sudo fdisk /dev/sda" as follow:`<br>

        +---------+-----------+--------------+------------------+------------------+
        | Name    |   Size    |    Type      |   USB/SAS        |   SATA           |
        +---------+-----------+--------------+------------------+------------------+
        | sda1    |   200M    |  EFI system  |   EFI            |    NULL          |
        +---------+-----------+--------------+------------------+------------------+
        | sda2    |   10G     |    ext4      | linux filesystem | linux filesystem |
        +---------+-----------+--------------+------------------+------------------+
        | sda3    |   10G     |    ext4      | linux filesystem | linux filesystem |
        +---------+-----------+--------------+------------------+------------------+
        | sda4    |   10G     |    ext4      | linux filesystem | linux filesystem |
        +---------+-----------+--------------+------------------+------------------+
        | sda5    |rest space |    ext4      | linux swap       | linux swap       | 
        +---------+-----------+--------------+------------------+------------------+
        
        
  Note: EFI partition must be a fat filesystem, so you should format sda1 with “sudo mkfs.vfat /dev/sda1″.

   *Preprocess when the disk can’t be identified*
   
    In case of the SATA disk is not be identified by D02, you can try the following step to process the disk.
    (it can be useful for some specfic disk such as seagate disk made by samsung.
    
   a. Find a PC or another board which can identify SATA disk.
    
       You should find a PC or another board which can identify this disk, and the system of PC or board should be linux system. For us,we can use D01 board.

   b. Use tool fdisk to process this disk
    
      format the disk firstly: 
      
      `sudo mkfs.ext4 /dev/sda`
       
      add a gpt to this disk : 
      
      `fdisk /dev/sda`
        
       `g`-------add a gpt partition
       
       add some EFI partition : 
       
       `n`-------add a partition
        
       `1`-------the number of partition
        
       `+200M`---------size of partition
        
       `t`-------change the type of partition
        
       EFI system
 
       add some anther partition ` ...`
       
       save the change           : `w`
       
       format EFI partition  : `sudo mkfs.vfat /dev/sda1`
       
       Then this disk can be identified by D02 board.
         
2. Download files and store them into hardware disk as below:

   (SAS/USB）Related files are placed as follow:
    ```
        sda1: -------EFI
              |       |
              |      GRUB2------grubaa64.efi  //grub binary file
              |
              |-------------grub.cfg           //grub config file
              |
              |-------------Image_D02          //kernel binary Image
        sda2: Ubuntu distribution
        sda3: Fedora distribution
    ```     
   
   （SATA）Related files are placed as follow:
    ```
 
        sda1: -------NULL
        sda2: Ubuntu distribution
        sda3: OpenSUSE distribution
    ```
    To get kernel image and dtb file, please refer to [Readme.md](https://github.com/open-estuary/estuary/blob/master/doc/Readme.4D02.md).<br>
    To get and config grub and grub.cfg, please refer to [Grub_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/Grub_Manual.4All.md).<br>
    To get different distributions, please refer to [Distributions_Guider.md](https://github.com/open-estuary/estuary/blob/master/doc/Distributions_Guide.4All.md).<br> 
    
3. Boot the board via SAS/USB/SATA

 **Boot via SAS/USB**
         
   a. modify grub config file(please refer to [Grub_Manual.4All.md] (https://github.com/open-estuary/estuary/blob/master/doc/Grub_Manual.4All.md))
   
     e.g.: the context of grub.cfg file is modified as follow:
    
     ```shell
	       #
	       # Sample GRUB configuration file
	       #
	       # Boot automatically after 5 secs.
	       set timeout=5
	       # By default, boot the Estuary with Ubuntu filesystem
	       set default=ubuntu
	       # For booting GNU/Linux

         menuentry "ubuntu" --id ubuntu {
         search --no-floppy --fs-uuid --set=root <UUID>
         linux /Image_D02 rdinit=/init root=PARTUUID=<PARTUUID> rootwait rootfstype=ext4 rw console=ttyS0,115200 earlycon=uart8250,mmio32,0x80300000 ip=dhcp
         }
     ```
    Note:
      
    1. <UUID> means the UUID of that partition which your EFI System is located in.
    
       <PARTUUID> means the PARTUUID of that partition which your linux distribution is located in. 
       
       To see the values of UUID and PARTUUID, please use the command:`$blkid`.
  
    2. If you want to use another linux distribution, please refer above steps.
          
   b. Reboot and press any key except "enter" into enter UEFI menu.
        
   c. For USB: Select "Boot Manager"-> "EFI USB Device"-> to enter grub selection menu.
   
      For SAS: Select "Boot Manager"-> "EFI Misc Device 1" to enter grub selection menu.
   
   d. Press arrow key up or down to select grub boot option to decide which distribution should boot.
          
  **Boot via SATA**

   In this boot mode, there are two different methods for you, one is to plug SATA disk into PCIE-to-SATA convert card(model:PEC-2024) which connect to D02 board,another is to connect SATA disk into SATA interface on D02 board directly. 
 
    **The first one: to plug SATA disk into PCIE-to-SATA convert card(model:PEC-2024) which connect to D02 board**
   
    a. Build kernel(please refer to [Readme.4D02.md] (https://github.com/open-estuary/estuary/blob/master/doc/Readme.4D02.md))
    
       * Enable driver configuration of corresponding SATA model in kernel
        
         Change the value of CONFIG_SATA_MV from "m" to "y" to enable PCIE-to-SATA driver.
          
         e.g.:modify arch/arm64/configs/defconfig as follow:
           
        ```
              ...... 
           CONFIG_SATA_MV=m             ----------> CONFIG_SATA_MV=y
        ```	
	
       * Modify arch/arm64/boot/dts/hisilicon/hip05-d02.dts file as follow:
         
        ```
       　 bootargs = "rdinit=/init root=/dev/sda2 rootdelay=10 rootfstype=ext4 rw console=ttyS0,115200 earlycon=uart8250,mmio32,0x80300000 ip=dhcp"
         ```
       After build the linux kernel from source, burn Image into Nor Flash and dtb file into SPI Flash. About how to burn Image and dtb file , please refer to "Boot via NORFLASH" and "Upgrade DTB file".
       
       NOTE: according to above bootargs, it will boot ubuntu distribution in sda2, if you want to boot other different distribution, you should change "root=/dev/sdaX" item.
   
   b. Reboot and press any key into enter UEFI menu.
   
   c. Select "Boot Manager"->"FLASH Start OS" and then press Enter Key.
   
   **The second one: to connect SATA disk into SATA interface on D02 board directly**

   a. select sata mode for UEFI 
   
     After burn BIOS file(you can refer to "UEFI_Manual.4D02.md"), UEFI boot as sas mode by default.
     
     You can switch between sata and sas by adding a commandline at EBL.
     
     e.g.:
       ```
           sataenable 0      //set into sas
           sataenable 1      //set into sata
           sataenable 2      //check the current setting: sas or sata   
       ```
   b. Modify arch/arm64/boot/dts/hisilicon/hip05-d02.dts file 
  
       * Find the word "bootargs" and modify the value as follow:　
       
	 ```shell
         bootargs = "rdinit=/init root=/dev/sda2 rootdelay=10 rootfstype=ext4 rw console=ttyS0,115200 earlycon=uart8250,mmio32,0x80300000 ip=dhcp"
         ```
       * Find the word "&sas0", "&sas1" and delete as follow:
       
        ~~&sas0 {~~  
        ~~status = "okay";~~,<br>
        ~~};~~<br>
       ~~&sas1 {~~<br>
        ~~status = "okay";~~<br>
        ~~};~~    

   c. Modify arch/arm64/boot/dts/hisilicon/hip05.dtsi file
   
     Change the status' value of node "ahci0: sata@b1002800" to "disabled" as follow:
     
      ```shell
           ahci0: sata@b1002800 {
                    ......
           status = "disabled";      ---------> status = "okay";
                };
       ```
   d. Build the kernel (please refer to [Readme.4D02.md] (https://github.com/open-estuary/estuary/blob/master/doc/Readme.4D02.md))
    
   e. Burn Image, dtb file NorFlash. About how to burn, please refer to "Boot via NORFLASH".
   
   f. Reboot and press any key except "enter" to enter UEFI menu.
   
   g. Select "Boot Manager"->"FLASH Start OS" and then press Enter Key.
   	
 <h3 id="3.6">Boot via ACPI</h3>

D02 also supports booting via ACPI, you can bring up this systerm which is similar with this DT mode, you must fix some point as follow:

1. delete DTB file and don't burn DTB file

2. Set the parameters of booting via ACPI

you must add `"acpi=force"` property in `"linux=...."` line for "grub.cfg" file; while you delete DTB line
for "grub.cfg" file.

NOTE: you can get more information about setting grub.cfg from [Grub_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/Grub_Manual.4All.md).
