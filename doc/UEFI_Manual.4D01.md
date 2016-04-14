* [Introduction](#1)
* [Upgrade UEFI](#2)
* [Recover the UEFI when it broke](#3)
* [BootWrapper Hacking](#4)
   * [Compile BootWrapper](#4.1)
   * [Upgrade Bootwrapper](#4.1)


<h2 id="1">Introduction</h2>

UEFI is a kind of BIOS to boot system and provide runtime service to OS which can do some basic IO operation with the runtime service, e.g.: reboot, power off and etc.

UEFI_D01.fd         //UEFI executable binary file for D01 board.

Where to get them, please refer to [Readme.txt](https://github.com/tianjiaoling/estuary/blob/mark/doc/Readme.4D01.md).

<h2 id="2">Upgrade UEFI</h2>

Note: This is not necessary unless you want to upgrade UEFI really.

FTP protocol is used for downloading between hardware boards and local network. Aboveall, please make sure you have a working FTP server in local network, so that board can get needed files from network by FTP.

1. Prepare files about UEFI on local computer

All files mentioned above should be ready firstly, then put them in the root directory of FTP.

2. Boot board into UEFI Boot Menu and EBL

Follow below steps to enter UEFI "Boot Menu" and "EBL":

  a. Make sure Jumper J39 is in position 1 and 2.
     This means to use custom UEFI, If position 2 and 3 are connected, it will boot with the default UEFI, which could never be flashed.
  b. Connect the board's UART port to a host machine with a serial cable.
  c. Install a serial port application in host machine, e.g.: kermit or minicom.
  d. Config serial port setting:115200/8/N/1 on host machine.
  e. Keep pressing ‘s’ in minicom or other serial port application to start UEFI "Boot Menu".
  f. Select "EBL" boot option and press "Enter".
    Type "help" to see all commands supported in EBL.
      
Then the board will enter the UEFI SHELL mode.

3. Update UEFI files

   a. Boot to enter UEFI "EBL" as above description
     
   b. IP address config:
        ```shell
        # Config IP address
        ifconfig -s eth0 <IP address> <mask> <gateway>
        ```
        eg. 
        `ifconfig -s eth0 192.168.1.155 255.255.255.0 192.168.1.1`
    
   c. Burn BIOS file
       ```shell
       # Download file from FTP server to board's RAM
       provision <server IP> -u <ftp user name> -p <ftp password> -f <UEFI binary>
       # Write the data into NORFLASH
       spiwfmem <source address> <target address> <data length>
       ```
       e.g.: 
       
       provision 192.168.1.107 -u sch -p aaa -f UEFI_D01.fd
       updateL1 UEFI_D01.fd

   d. Power off and reboot board again

<h2 id="3">Recover the UEFI when it broke</h2>

Actually the board can restore two UEFI in case of the default one breaks, then you can restore it as following way:

 1. Power off the board, disconnect power supplier.<br>
 2. Connect Pin 2 and Pin 3 of J39 (Leave Pin 1 unconnected)<br>
 3. Power on and enter UEFI "EBL" again as above description.<br>
 4. Burn UEFI file for BIOS as above step3 "Update UEFI files".<br>
 5. Power off the board, disconnect power supplier again.<br>
 6. Connect Pin 1 and Pin 2 of J39 (Leave Pin 3 unconnected)<br>
 7. Power on board again.

<h2 id="4">BootWrapper Hacking</h2>

<h3 id="4.1">Compile BootWrapper</h3>

 Download BootWrapper source code and build according [Readme.txt](https://github.com/tianjiaoling/estuary/blob/mark/doc/Readme.4D01.md) to produce .text and .monitor

<h3 id="4.1">Upgrade Bootwrapper</h3>
1. Boot D01 to enter UEFI "EBL" as above description.

2. IP address config:
    `ifconfig -s eth0 <IP address> <mask> <gateway>`

    eg. ifconfig -s eth0 192.168.1.155 255.255.255.0 192.168.1.1
    
3. Download BootWrapper binary from FTP server
        
    Note: filenames must not be changed.
    ```shell
    provision <server IP> -u <user name> -p <password> -f .text
    provision <server IP> -u <user name> -p <password> -f .monitor
    ```
    e.g.: provision 192.168.1.107 -u dj -p dj -f .text
    
    e.g.: provision 192.168.1.107 -u dj -p dj -f .monitor

4. Reboot the board again.
