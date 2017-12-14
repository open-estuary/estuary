* [Introduction](#1)
* [Preparation](#2)
   * [Prerequisite](#2.1)
   * [Check the hardware board](#2.2)
   * [Upgrade UEFI and trust firmware](#2.3)
* [Bring up System](#3)
   * [Boot via PXE](#3.1)
   * [Boot via NFS](#3.2)
   * [Boot via ISO](#3.3)

<h2 id="1">Introduction</h2>

This documentation describes how to get, build, deploy and bring up target system based Estuary Project, it will help you to make your Estuary Environment setup from ZERO.

All following sections will take the D05 board as example, other boards have the similar steps to do, for more detail difference between them, please refer to Hardware Boards sections in http://open-estuary.org/hardware-boards/.

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

For more details, please refer to [UEFI_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/UEFI_Manual.4D05.md)
"Upgrade UEFI" chapter.

<h3 id="2.2">Check the hardware board</h3>

Hardware board should be ready and checked carefully to make sure it is available, more detail information about different hardware board, please refer to http://open-estuary.org/d05/.

<h3 id="2.3">Upgrade UEFI and trust firmware</h3>

You can upgrade UEFI and trust firmware yourself based on FTP service, but this is not necessary. If you really want to do it, please refer to [UEFI_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/UEFI_Manual.4D05.md).

<h3 id="3">Booting The Installer</h3>

<h3 id="3.1">Boot via PXE</h3>

If you are booting the installer from the network, simply select PXE boot when presented by UEFI.
For the PXE,please refer to [Setup_PXE_Env_on_Host.md](https://github.com/open-estuary/estuary/blob/master/doc/Setup_PXE_Env_on_Host.4All.md).

Modify grub config file(please refer to [Grub_Manual.4All.md](https://github.com/open-estuary/estuary/blob/master/doc/Grub_Manual.4All.md))

      e.g. grub.cfg file for official versions is modified as follow:
      ```
      # Sample GRUB configuration file
      # For booting GNU/Linux
        menuentry 'D05 Install' {
           set background_color=black
           linux    /debian-installer/arm64/linux --- quiet
           initrd   /debian-installer/arm64/initrd.gz
        }
      ```

<h3 id="3.2">Boot via NFS</h3>

In this boot mode, the root parameter in grub.cfg menuentry will set to /dev/nfs and nfsroot will be set to the path of rootfs on NFS server. You can use `"showmount -e <server ip address>" `to list the exported NFS directories on the NFS server.

D05 supports booting via NFS, you can try it as following steps:

1. Enable DHCP, TFTP and NFS service according to [Setup_PXE_Env_on_Host.md](https://github.com/open-estuary/estuary/blob/master/doc/Setup_PXE_Env_on_Host.4All.md).

2. Get and config grub file to support NFS boot according to [Grub_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/Grub_Manual.4All.md).

   Note: D05 only supports booting via ACPI mode with Centos distribution, so please refer to Grub_Manual.md to get correct configuration.

3. Reboot D05 and press "F2" or "Esc" to enter UEFI Boot Menu

4. Select boot option "Boot Manager"->"UEFI PXEv4 `<No>`" boot option to enter.

  Note:
If you are connecting the D05 board of openlab, please select "UEFI PXEv4 (MAC:000108001540)". The value of `<No>` is depended on which D05 GE port is connected.

<h3 id="3.3">Boot via ISO</h3>
In case you are booting with the minimal ISO via SATA / SAS / SSD, simply select the right boot option in UEFI.

At this stage you should be able to see the grub menu, Debian's installer like:

      ```
      Install
      Advanced options ...
      Install with speech synthesis
      .

      Use the down and up keys to change the selection.
      Press 'e' to edit the selected item, or 'c' for a command prompt.
      ```
Now just hit enter and wait for the kernel and initrd to load, which automatically loads the installer and provides you the installer console menu, so you can finally install.

After finished the installation:
a. Reboot and press "F2" or "Esc" to enter UEFI main menu.
b. Select "Boot Manager"-> "UEFI Misc Device 1"-> to enter grub selection menu.
c. Press arrow key up or down to select grub boot option to decide which distribution should boot.


