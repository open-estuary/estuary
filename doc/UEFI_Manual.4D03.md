* [Introduction](#1)
* [Upgrade UEFI](#2)
* [Recover the UEFI when it broke](#3)

<h2 id="1">Introduction</h2>

UEFI is a kind of BIOS to boot system and provide runtime service to OS which can do some basic IO operation with the runtime service, e.g.: reboot, power off and etc.
Normally, there are some trust firmware will be produce from UEFI building, they are responsible for trust reprogram, they include:

  UEFI_D03.fd         //UEFI executable binary file.
  
  CH02TEVBC_V03.bin   //CPLD binary to control power supplier.

Where to get them, please refer to [Readme.md](https://github.com/open-estuary/estuary/blob/master/doc/Readme.4D03.md).

<h2 id="2">Upgrade UEFI</h2>

Note: This is not necessary unless you want to upgrade UEFI really.

* Prepare files about UEFI on local computer

  FTP protocol is used for downloading between hardware boards and local network. Aboveall, please make sure you have a working FTP server in local network, so that board can get needed files from network by FTP.
  
  All files mentioned above should be ready firstly, then put them in the root directory of FTP.

* Connect the board's UART port to a host machine

  Please refer to [Deploy_Manual.4D03.md](https://github.com/open-estuary/estuary/blob/master/doc/Deploy_Manual.4D03.md) "Prerequisite" chapter.
  
  If you choose Method 1, use another console window, input `board_reboot` command, the system will be reset, when system showing "Press Any key in 10 seconds to stop automatical booting...", press any key except "enter" key and enter UEFI main menu.
  
  If you choose Method 2, take the following steps:
  
   * Reboot the board and press any key except "enter" key to enter UEFI main menu.<br>
   * Select "Boot Manager" into Boot Option Menu and choose "EFI Internet Shell".
  
  Then the board will enter into the UEFI SHELL mode.

* UEFI menu introduction

  UEFI main menu option is showed as follow:
  ```
  continue 
  select Language            <standard English>
  >Boot Manager
  >Device Manager
  >Boot Maintenance Manager
  ```
  Choose "Boot Manager" and enter into Boot option menu:
  ```
  EFI Misc Device 
  EFI Misc Device 1
  EFI Network
  EFI Internal Shell
  Flash Start OS
  ESL Start OS
  Embedded Boot Loader(EBL)
  ```
  EFI Internal Shell mode is a standard command shell in UEFI.
 
  Embedded Boot Loader(EBL) mode is an embedded command shell based on boot loader specially for developers.
  
  You can switch between two modes by typing "exit" from one mode to UEFI main menu and then choose the another mode.

* Update UEFI files

    a. IP address config at "EFI Internal Shell" mode
    
      Press any key except "enter" key to enter UEFI main menu. Select "Boot Manager"->"EFI Internal Shell".
    
    `ifconfig -s eth0 static <IP address> <mask> <gateway>`
    
    e.g.: `ifconfig -s eth0 static 192.168.1.4 255.255.255.0 192.168.1.1`
    
    b. Burn BIOS file at "Embedded Boot Loader(EBL)" mode
    
      Enter "exit" from "EFI Internal Shell" mode to the UEFI main menu and choose "Boot Manager"-> "Embedded Boot Loader(EBL)"after setting the IP address done.   
     ```shell
    # Download file from FTP server to board's RAM
    provision <server IP> -u <ftp user name> -p <ftp password> -f <UEFI binary> -a <download target address>
    # Write the data into NORFLASH
    spiwfmem <source address> <target address> <data length>
     ```
    e.g.: 
    ```shell
    provision 192.168.1.107 -u sch -p aaa -f UEFI_D03.fd -a 0x100000
    spiwfmem 0x100000 0x0000000 0x300000
    ```
    
  c. Power off and reboot board again.

<h2 id="3">Recover the UEFI when it broke</h2>

Actually the board can restore two UEFI in case of the default one breaks, then you can restore it as following way:

  1. Power off the board and disconnect power supply.<br>
  2. Push the dial switch 's3' to 'off' with a '3' on the board, please check the Hardware Boards to find where it is: http://open-estuary.com/d03-2/.<br>
  3. Power on and enter UEFI SHELL again as above description.<br>
  4. Push the dial swift 's3' to 'on' with a '3' on the board.<br>
  5. Burn UEFI file for BIOS as above step3 "Update UEFI files".<br>
  6. Reset the system again.

Now you have already updated your failed BIOS, and the board will boot with new UEFI successfully.
