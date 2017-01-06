* [Introduction](#1)
* [Preparation](#2)
   * [Prerequisite](#2.1)
   * [Check the hardware board](#2.2)
   * [Upgrade UEFI and trust firmware](#2.3)
* [Bring up System via ACPI mode](#3)
   * [Boot via PXE(ACPI)](#3.1)
   * [Boot via NFS(ACPI)](#3.2)
   * [Boot via DISK(SAS/SATA)(ACPI)](#3.3)

<h2 id="1">Introduction</h2>

This documentation describes how to get, build, deploy and bring up target system based Estuary Project, it will help you to make your Estuary Environment setup from ZERO.

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

<h3 id="2.2">Check the hardware board</h3>

<h3 id="2.3">Upgrade UEFI and trust firmware</h3>

Please contact support@open-estuary.org to get uefi files of overdrive.

<h2 id="3">Bring up System via ACPI mode</h2>

There are several methods to bring up system, you can select following anyone fitting you to boot up.

<h3 id="3.1">Boot via PXE(ACPI)</h3>

In this boot mode, the UEFI will get grub from PXE server.The grub will get the configuration file from TFTP service configured by PXE server.

1. Setup PXE environment on host

   Enable both DHCP and TFTP services on one of your host machines according to [Setup_PXE_Env_on_Host.md](https://github.com/open-estuary/estuary/blob/master/doc/Setup_PXE_Env_on_Host.4All.md).

2. Reboot and press "Del" to enter UEFI Boot Menu

3. Move mouse to "Save&Exit" and select "UEFI: Network Port00" boot option.

4. After several seconds, overdrive will boot by PXE automatically.

To config the grub.cfg to support PXE boot, please refer to  [Grub_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/Grub_Manual.4All.md).

<h3 id="3.2">Boot via NFS(ACPI)</h3>

In this boot mode, the root parameter in grub.cfg menuentry will set to /dev/nfs and nfsroot will be set to the path of rootfs on NFS server. You can use `"showmount -e <server ip address>" `to list the exported NFS directories on the NFS server.

overdrive supports booting via NFS, you can try it as following steps:

1. Enable DHCP, TFTP and NFS service according to [Setup_PXE_Env_on_Host.md](https://github.com/open-estuary/estuary/blob/master/doc/Setup_PXE_Env_on_Host.4All.md).

2. Get and config grub file to support NFS boot according to [Grub_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/Grub_Manual.4All.md).

3. Reboot and press "Del" to enter UEFI Boot Menu

4. Move mouse to "Save&Exit" and select "UEFI: Network Port00" boot option.

5. After several seconds, overdrive will boot by nfs automatically.

<h3 id="3.3">Boot via DISK(SAS/SATA)(ACPI)</h3>

overdrive board supports booting via SAS, USB and SATA by default. The UEFI will directly get the grub from the EFI system partition on the hard disk. The grub will load the grub configuration file from the EFI system partition. So grubaa64.efi, grub.cfg, Image and different estuary release distributions are stored on disk.

1. Boot by PXE (please refer to "Boot via PXE") to part and format hardware disk before booting overdrive board

   Format hardware disk

   e.g.:
   ```bash
   sudo mkfs.vfat /dev/sda1
   sudo mkfs.ext4 /dev/sda2
   ```
   **For the disk capacity is less than 2T**, part hardware disk with `sudo fdisk /dev/sda` as follow, EFI partition is set to 200M, distribution partition is set to 100G by default.

 
   add a gpt to this disk :

   `fdisk /dev/sda`

   `g`-------add a gpt partition

   add some EFI partition :

   `n`-------add a partition

   `1`-------the number of partition

   type "Enter" key ------ First sector

   `+200M`---------Last sector, size of partition

   `t`-------change the type of partition

   add the second partition for distribution `mkpart`  

   `n`-------add a partition  
   `2`-------the number of partition

   type "Enter" key ------ First sector  
   `+100G`---------Last sector, size of partition 

   add some another partition  `...`<br>
   save the change           : `w`<br>

   **For the disk capacity is more than 2T**, part hardware disk with `sudo parted /dev/sda` as follow , EFI partition is set to 200M, distribution partition is set to 100G by default.  
   add a gpt to this disk:

   (parted):--------`mklabel`  
   New disk label type:-------`gpt`  

   add EFI partition:  

   (parted):------------`mkpart`  
   Partition name?------`p1`  
   File system type?----`fat32`  
   Start?----------------`1`  
   End?------------------`201`  

   add the second partition for distribution `mkpart`  

   (parted):------------`mkpart`  
   Partition name?------`p2`  
   File system type?----`ext4`  
   Start?----------------`202`  
   End?------------------`100000`  

   add some another partition `mkpart`  
   `...`  

   remove the partition by `rm <NO>`  
   check out how many partitions by `p`  
   exit the partition by `q`  

   check the partitions with details by `parted -s /dev/sda print`

   **format EFI partition:** `sudo mkfs.vfat /dev/sda1`<br>
   **format ext4 partition:** `sudo mkfs.ext4 /dev/sda2`<br>

   ```bash
   +---------+------------+--------------+------------------+
   | Name    |   Size     |    Type      |   USB/SAS/SATA   |
   +---------+------------+--------------+------------------+
   | sda1    |   200M     |  EFI system  |   EFI            |
   +---------+------------+--------------+------------------+
   | sda2    |   100G     |    ext4      | linux filesystem |
   +---------+------------+--------------+------------------+
   | sda3    |   100G     |    ext4      | linux filesystem |
   +---------+------------+--------------+------------------+
   | sda4    |   100G     |    ext4      | linux filesystem |
   +---------+------------+--------------+------------------+
    ```

   Note: EFI partition must be a fat filesystem, so you should format sda1 with `“sudo mkfs.vfat /dev/sda1″`.

2. Download files and store them into hardware disk as below.

   (SAS/SATA)Related files are placed as follow:
   ```bash
   sda1: -------EFI
          |       |
          |       BOOT------bootaa64.efi, grub.cfg  //rename grubaa64.efi to bootaa64.efi
          |
          |
          |-------------mini-rootfs-arm64.cpio.gz
          |
          |-------------startup.nsh    //cat startup.nshi, the result is "bootaa64"
          |
          |-------------Image          //kernel binary Image
    sda2: Centos distribution or other distribution
   ```

   Note: overdrive only supports booting system with Centos, so Centos distribution should be uncompressed in sda2. The grubaa64.efi file must be put in /EFI/GRUB2 directory of dev/sda1(gpt partition)

   To get and config grub and grub.cfg, please refer to Grub_Manual.md.<br>
   To get Centos distribution, please refer to [Distributions_Guider](https://github.com/open-estuary/estuary/blob/master/doc/Distributions_Guide.4All.md).<br>

3. Boot the board via SAS/SATA

   a. Modify grub config file, please refer to Grub_Manual.4All.md.<br>
   e.g.: <br>
   ```bash
    # Sample GRUB configuration file
    #
    # Boot automatically after 5 secs.
    set timeout=5
    # By default, boot the Estuary with Centos filesystem
    set default=overdrive_centos_sata
    # For booting GNU/Linux

    menuentry "overdrive Centos SATA" --id overdrive_centos_sata {
    search --no-floppy --fs-uuid --set=root <UUID>
    linux /Image root=PARTUUID=<PARTUUID> rootfstype=ext4 rw  rdinit=/init raid=noautodetect plymouth.enable=0 console=ttyAMA0,115200n8
    }
   ```

   Note:<br>
   `<UUID> `means the UUID of that partition which your EFI System is located in.<br>
   `<PARTUUID>` means the PARTUUID of that partition which your linux distribution is located in. <br>
    To see the values of UUID and PARTUUID, please use the command: `$blkid`.<br>

   b. Reboot and press "Del" to enter UEFI Boot Menu. Move mouse to "Save&Exit".

   c. For SAS and sata: select "HardDisk" to enter grub selection menu.

   d. Press arrow key up or down to select grub boot option to decide which distribution should boot.


