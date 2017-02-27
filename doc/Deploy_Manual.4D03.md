* [Introduction](#1)
* [Preparation](#2)
   * [Prerequisite](#2.1)
   * [Check the hardware board](#2.2)
   * [Upgrade UEFI and trust firmware](#2.3)
* [Bring up System via ACPI mode](#3)
   * [Boot via PXE(ACPI)](#3.1)
   * [Boot via NFS(ACPI)](#3.2)
   * [Boot via DISK(SAS/USB/SATA)(ACPI)](#3.3)

## <a name="1">Introduction</a>

This documentation describes how to get, build, deploy and bring up target system based Estuary Project, it will help you to make your Estuary Environment setup from ZERO.  
All following sections will take the D03 board as example, other boards have the similar steps to do, for more detail difference between them, please refer to Hardware Boards sections in http://open-estuary.com/hardware-boards/.

## <a name="2">Preparation</a>

### <a name="2.1">Prerequisite</a>

*Local network*: To connect hardware boards and host machine, so that they can communicate each other.  
*Serial cable*: To connect hardware board’s serial port to host machine, so that you can access the target board’s UART in host machine.

Two methods are provided to **connect the board's UART port to a host machine**:  
**Method 1**: connect the board's UART in openlab environment  
Use `board_connect` command.(Details please refer to `board_connect --help`)  
**Method 2**: directly connect the board by UART cable  
a. Connect the board's UART port to a host machine with a serial cable.  
b. Install a serial port application in host machine, e.g.: kermit or minicom.  
c. Config serial port setting:115200/8/N/1 on host machine.  
For more details, please refer to [UEFI_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/UEFI_Manual.4D03.md) "Upgrade UEFI" chapter.

### <a name="2.2">Check the hardware board</a>

Hardware board should be ready and checked carefully to make sure it is available, more detail information about different hardware board, please refer to <http://open-estuary.org/d03/>.

### <a name="2.3">Upgrade UEFI and trust firmware</a>

You can upgrade UEFI and trust firmare yourself based on FTP service, but this is not necessary. If you really want to do it, please refer to [UEFI_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/UEFI_Manual.4D03.md).

## <a name="3">Bring up System via ACPI mode</a>

There are several methods to bring up system, you can select following anyone fitting you to boot up.

### <a name="3.1">Boot via PXE</a>

In this boot mode, the UEFI will get grub from PXE server.The grub will get the configuration file from TFTP service configured by PXE server.

1. Setup PXE environment on host  
   Enable both DHCP and TFTP services on one of your host machines according to [Setup_PXE_Env_on_Host.md](https://github.com/open-estuary/estuary/blob/master/doc/Setup_PXE_Env_on_Host.4All.md).
2. Reboot and press anykey except "enter" to enter UEFI Boot Menu
3. Select boot option "Boot Manager"->"EFI Network `<No>`" boot option and press "Enter".  
   **Note**:  
   If you are connecting the D03 board of openlab, please select "EFI Network 2".  
   The value of `<No>` is depended on which D03 GE port is connected. D03 board support 4 on-board network ports at maximun.To enable any one of them by connecting to network cable or optical fiber. From left to right, followed by two GE ports, two 10GE ports which corresponding to UEFI startup interface are EFI Network 2, EFI Network 3, EFI Network 0, EFI Network 1.
4. After several seconds, D03 will boot by PXE automatically.

To config the `grub.cfg` to support PXE boot, please refer to  [Grub_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/Grub_Manual.4All.md).

<h3 id="3.2">Boot via NFS</h3>

In this boot mode, the root parameter in grub.cfg menuentry will set to /dev/nfs and nfsroot will be set to the path of rootfs on NFS server. You can use `showmount -e <server ip address>` to list the exported NFS directories on the NFS server.

D03 supports booting via NFS, you can try it as following steps:

1. Enable DHCP, TFTP and NFS service according to [Setup_PXE_Env_on_Host.md](https://github.com/open-estuary/estuary/blob/master/doc/Setup_PXE_Env_on_Host.4All.md).
2. Get and config grub file to support NFS boot according to [Grub_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/Grub_Manual.4All.md).
3. Reboot D03 and press anykey except "enter" to enter UEFI Boot Menu
4. Select boot option "Boot Manager"->"EFI Network `<No>`" boot option to enter.  
  **Note**: If you are connecting the D03 board of openlab, please select "EFI Network 2". The value of `<No>` is depended on which D03 GE port is connected.

### <a name="3.3">Boot via DISK(SAS/USB/SATA)</a>

D03 board supports booting via SAS, USB and SATA by default. The UEFI will directly get the grub from the EFI system partition on the hard disk. The grub will load the grub configuration file from the EFI system partition. So `grubaa64.efi`, `grub.cfg`, `Image` and different estuary release distributions are stored on disk.

1. Boot by PXE (please refer to "Boot via PXE") to part and format hardware disk before booting D03 board  
   Format hardware disk, e.g.
   ```bash
   sudo mkfs.vfat /dev/sda1
   sudo mkfs.ext4 /dev/sda2
   ```
   **For the disk capacity is less than 2T**, part hardware disk with `sudo fdisk /dev/sda` as follow, EFI partition is set to 200M, distribution partition is set to 100G by default.  
   add a gpt to this disk:
   ```bash
   fdisk /dev/sda
   ```
   `g`-------add a gpt partition

   add some EFI partition:  
   `n`-------add a partition  
   `1`-------the number of partition

   type "Enter" key ------ First sector  
   `+200M`---------Last sector, size of partition  
   `t`-------change the type of partition to EFI system

   add the second partition for distribution `mkpart`  

   `n`-------add a partition  
   `2`-------the number of partition

   type "Enter" key ------ First sector  
   `+100G`---------Last sector, size of partition  

   add some another partition `...`  
   save the change: `w`  

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

   add other partition for distribution `mkpart`  
   `...`  

   remove the partition by `rm <NO>`  
   check out how many partitions by `p`  
   exit the partition by `q`  

   check the partitions with details by `parted -s /dev/sda print`

   **format EFI partition:** `sudo mkfs.vfat /dev/sda1`  
   **format ext4 partition:** `sudo mkfs.ext4 /dev/sda2`  
   ```
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
   Note: EFI partition must be a fat filesystem, so you should format sda1 with `sudo mkfs.vfat /dev/sda1`.
2. Download files and store them into hardware disk as below.  
   (SAS/USB/SATA) Related files are placed as follow:
   ```
   sda1: -------EFI
          |       |
          |       GRUB2------grubaa64.efi  // grub binary file
          |
          |-------------grub.cfg           // grub config file
          |
          |-------------Image              // kernel binary Image
   sda2: Ubuntu distribution
   sda3: Fedora distribution
   ```
   NOTE: The `grubaa64.efi` file must be put in `/EFI/GRUB2` directory of `/dev/sda1`(gpt partition), the distributions could be uncompressed in `/dev/sdaX`(X can be 2,3,4,etc. exclude 1).

    To get kernel image and dtb file, please refer to [Readme.md](https://github.com/open-estuary/estuary/blob/master/doc/Readme.4D03.md).  
    To get and config grub and grub.cfg, please refer to [Grub_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/Grub_Manual.4All.md).  
    To get different distributions, please refer to [Distributions_Guider](https://github.com/open-estuary/estuary/blob/master/doc/Distributions_Guide.4All.md).
3. Boot the board via SAS/USB/SATA  
   a. Modify grub config file(please refer to [Grub_Manual.4All.md](https://github.com/open-estuary/estuary/blob/master/doc/Grub_Manual.4All.md))  
      e.g. grub.cfg file for official versions after V2.2 is modified as follow:
      ```bash
      # Sample GRUB configuration file
      #
      # Boot automatically after 5 secs.
      set timeout=5
      # By default, boot the Estuary with Ubuntu filesystem
      set default=ubuntu
      # For booting GNU/Linux

      menuentry "D03 Ubuntu SATA(CONSOLE)" --id d03_ubuntu_sata_console {
        search --no-floppy --fs-uuid --set=root <UUID>
        linux /Image pci=pcie_bus_perf rootwait root=PARTUUID=<PARTUUID> rw console=ttyS0,115200 earlycon=hisilpcuart,mmio,0xa01b0000,0,0x2f8
      }
      ```
      *  The value of console is `ttyS0` for official versions after V2.2. If you use official V2.2 and previous versions, the value of console is `ttyS1`
      *  `<UUID>` means the UUID of that partition which your EFI System is located in.  
         `<PARTUUID>` means the PARTUUID of that partition which your linux distribution is located in.  
         To see the values of UUID and PARTUUID, please use the command:`blkid`.
      *  If you want to use another linux distribution, please refer above steps.
   b. Reboot and press anykey except "enter" to enter UEFI main menu.
   c. For USB: Select "Boot Manager"-> "EFI USB Device"-> to enter grub selection menu.
      *  For SAS: Select "Boot Manager"-> "EFI Misc Device 1" to enter grub selection menu.
      *  For SATA: Select "Boot Manager"-> "EFI Hard Drive" to enter grub selection menu.
   d. Press arrow key up or down to select grub boot option to decide which distribution should boot.

