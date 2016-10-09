* [Introduction](#1)
* [Upgrade UEFI](#2)
* [Recover the UEFI when it broke](#3)

<h2 id="1">Introduction</h2>

UEFI is a kind of BIOS to boot system and provide runtime service to OS which can do some basic IO operation with the runtime service, e.g.: reboot, power off and etc.
Normally, there are some trust firmware will be produce from UEFI building, they are responsible for trust reprogram, they include:

  UEFI_D05.fd         //UEFI executable binary file.

Where to get them, please refer to [Readme.md](https://github.com/open-estuary/estuary/blob/master/doc/Readme.4D05.md).

<h2 id="2">Upgrade UEFI</h2>

Note: This is not necessary unless you want to upgrade UEFI really.

* Prepare files about UEFI on local computer

  FTP protocol is used for downloading between hardware boards and local network. Aboveall, please make sure you have a working FTP server in local network, so that board can get needed files from network by FTP.

  All files mentioned above should be ready firstly, then put them in the root directory of FTP.

* Connect the board's UART port to a host machine

  Please refer to [Deploy_Manual.4D05.md](https://github.com/open-estuary/estuary/tree/estuary-d05-3.0b/doc/Deploy_Manual.4D05.md) "Prerequisite" chapter.

  If you choose Method 1, use another console window, use `board_reboot` command to reset the board.

  If you choose Method 2, press the reset key on the board to reset the board.

  when system showing "Press Any key in 10 seconds to stop automatical booting...", press any key except "enter" key to enter UEFI main menu.

* UEFI menu introduction

  UEFI main menu option is showed as follow:
  ```bash
  continue
  select Language            <standard English>
  >Boot Manager
  >Device Manager
  >Boot Maintenance Manager
  ```
  Choose "Boot Manager" and enter into Boot option menu:
  ```bash
  EFI Misc Device
  EFI Network
  EFI Network 1
  EFI Network 2
  EFI Network 3
  EFI Internal Shell
  ESL Start OS
  Embedded Boot Loader(EBL)
  ```
  D05 board support 4 on-board network ports at maximun. To enable any one of them by connecting to network cable or optical fiber. From left to right, followed by the two 2GE ports, two 10GE ports which corresponding to UEFI startup interface are EFI Network 2, EFI Network 3, EFI Network 0, EFI Network 1.

  EFI Internal Shell mode is a standard command shell in UEFI.

  Embedded Boot Loader(EBL) mode is an embedded command shell based on boot loader specially for developers.

  You can switch between two modes by typing "exit" from one mode to UEFI main menu and then choose the another mode.

* Update UEFI files

  a. IP address config at "EFI Internal Shell" mode(Optional, you can ignore this step if DHCP works well)

  Press any key except "enter" key to enter UEFI main menu. Select "Boot Manager"->"EFI Internal Shell".

  `ifconfig -s eth0 static <IP address> <mask> <gateway>`

  e.g.:

  `ifconfig -s eth0 static 192.168.1.4 255.255.255.0 192.168.1.1`

  b. Burn BIOS file at "Embedded Boot Loader(EBL)" mode

  Enter "exit" from "EFI Internal Shell" mode to the UEFI main menu and choose "Boot Manager"-> "Embedded Boot Loader(EBL)"after setting the IP address done.
  ```bash
  # Download file from FTP server to board's RAM
  provision <server IP> -u <ftp user name> -p <ftp password> -f <UEFI binary> -a <download target address>
  # Write the data into NORFLASH
  spiwfmem <source address> <target address> <data length>
  ```
  e.g.:
  ```bash
  provision 192.168.1.107 -u sch -p aaa -f UEFI_D05.fd -a 0x100000
  spiwfmem 0x100000 0x0000000 0x300000
  ```

  c. Power off and reboot board again.

<h2 id="3">Recover the UEFI when it broke</h2>

1. Connect board's BMC port to the network port of your ubuntu host.

2. Configure board's BMC IP and your ubuntu host's IP at the same network segment.

3. Login the BMC website, The username/passwd are root/Huawei12#$. Click "system", click "Firmware upgrade", click "Browse" to choose the hpm formate uefi file(Please contact support@open-estuary.org to get the hpm formate uefi file).

   Note: Usually BMC website can be visited by (https://192.168.2.100) by default. If BMC IP have modified by somebody, please take the following steps to find modified BMC IP

 * Pull out the power cable. Find the pin named "COM_SW" at J44. Then connect it.

 * Power on the board, connect the board's serial port to your ubuntu serial port. When the screen display message "You are trying to access a restricted zone. Only Authorized Users allowed.", type "Enter" key, input username/passwd, the username/passwd are root/Huawei12#$.

 * After you login the BMC interface which start with "iBMC:/->", use command "ifconfig" to see the modified BMC IP.

 * When you get the board's BMC IP, please visit the BMC website by https:<board's BMC IP>
4. Click "Start update"(Do not power off during this period).

5. After updated UFEI file, reboot the board to enter UEFI menu.<br>
