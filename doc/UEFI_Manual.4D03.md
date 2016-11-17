* [Introduction](#1)
* [Upgrade UEFI](#2)
* [Recover the UEFI when it broke](#3)

## <a id="1">Introduction</a>

UEFI is a kind of BIOS to boot system and provide runtime service to OS which can do some basic IO operation with the runtime service, e.g.: reboot, power off and etc.  
Normally, there are some trust firmware will be produce from UEFI building, they are responsible for trust reprogram, they include:
```
UEFI_D03.fd         //UEFI executable binary file.
```
Where to get them, please refer to [Readme.md](https://github.com/open-estuary/estuary/blob/master/doc/Readme.4D03.md).

## <a name="2">Upgrade UEFI</a>

Note: This is not necessary unless you want to upgrade UEFI really.

1. Prepare UEFI_D03.fd on computer which installed FTP service  
  FTP service is used to download files from the FTP server to hardware boards. Please prepare a computer installed FTP service with local network firstly, so that boards can get needed files frome FTP server with FTP protocol. Then put the UEFI files mentioned above into the root directory of FTP service.  
2. Connect the board's UART port to a host machine  
   Please refer to [Deploy_Manual.4D03.md](https://github.com/open-estuary/estuary/blob/master/doc/Deploy_Manual.4D03.md) "Prerequisite" chapter.

   If you choose Method 1 Deploy_Manual.4D03.md, use another console window, use `board_reboot` command to reset the board.  
   If you choose Method 2 Deploy_Manual.4D03.md, press the reset key on the board to reset the board.

   when system showing "Press Any key in 10 seconds to stop automatical booting...", press any key except "enter" key to enter UEFI main menu.

### UEFI menu introduction

UEFI main menu option is showed as follow:
```bash
continue
select Language            <standard English>
>Boot Manager
>Device Manager
>Boot Maintenance Manager
```
Choose "Boot Manager" and enter into Boot option menu:
```
EFI Misc Device
EFI Network
EFI Network 1
EFI Network 2
EFI Network 3
EFI Internal Shell
ESL Start OS
Embedded Boot Loader(EBL)
```
Please select "EFI Network 2" when booting boards via PXE with openlab environment.  
D03 board support 4 network ports including two 2GE ports, two 10GE ports which corresponding to UEFI startup interface are EFI Network 2, EFI Network 3, EFI Network 0, EFI Network 1.

*EFI Internal Shell mode* is a standard command shell in UEFI.  
*Embedded Boot Loader(EBL) mode* is an embedded command shell based on boot loader specially for developers.  
You can switch between two modes by typing "exit" from one mode to UEFI main menu and then choose the another mode.

### Update UEFI files

*  IP address config at "EFI Internal Shell" mode(Optional, you can ignore this step if DHCP works well)

   Press any key except "enter" key to enter UEFI main menu. Select "Boot Manager"->"EFI Internal Shell".
   ```bash
   ifconfig -s eth0 static <IP address> <mask> <gateway>
   ```
   e.g.:
   ```
   ifconfig -s eth0 static 192.168.1.4 255.255.255.0 192.168.1.1
   ```
*  Burn BIOS file at "Embedded Boot Loader(EBL)" mode  

   Enter "exit" from "EFI Internal Shell" mode to the UEFI main menu and choose "Boot Manager"-> "Embedded Boot Loader(EBL)"after setting the IP address done.
   ```bash
   # Download file from FTP server to board's RAM
   provision <server IP> -u <ftp user name> -p <ftp password> -f <UEFI binary> -a <download target address>
   # Write the data into NORFLASH
   spiwfmem <source address> <target address> <data length>
   ```
   e.g.:
   ```bash
   provision 192.168.1.107 -u sch -p aaa -f UEFI_D03.fd -a 0x100000
   ```
   D03 board supports 4 network ports which including 2 GE ports and 2 10GE ports. Please select "Interface 3" when downloading bios file with openlab environment.  
   ```bash
   spiwfmem 0x100000 0x0000000 0x300000
   ```
   
*  Power off and reboot board again.

## <a name="3">Recover the UEFI when it broke</a>

1. Connect board's BMC port to the network port of your ubuntu host.
2. Configure board's BMC IP and your ubuntu host's IP at the same network segment.
3. Login the BMC website, The `username/passwd` is `root/Huawei12#$`. Click "system", "Firmware upgrade","Browse" to choose the uefi file in hpm formate.(Please contact support@open-estuary.org to get the hpm file).

   Note: Usually BMC website can be visited by (https://192.168.2.100) by default. If BMC IP have modified by somebody, please take the following steps to find modified BMC IP

   * Pull out the power cable to power off tthe board. Find the pin named "`COM_SW`" at `J44`. Then connect it with jump cap.
   * Power on the board, connect the board's serial port to your ubuntu serial port. When the screen display message "You are trying to access a restricted zone. Only Authorized Users allowed.", type "Enter" key, input `username/passwd`, the `username/passwd` is `root/Huawei12#$`.
   * After you login the BMC interface which start with "`iBMC:/->`", use command "`ifconfig`" to see the modified BMC IP.
   * When you get the board's BMC IP, please visit the BMC website by `https://<board's BMC IP>`
4. Click "Start update"(Do not power off during this period).
5. After updated UFEI file, reboot the board to enter UEFI menu.
