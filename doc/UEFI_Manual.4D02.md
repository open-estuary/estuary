* [Introduction](#1)
* [Upgrade UEFI](#2)
* [Recover the UEFI when it broke](#3)

<h2 id="1">Introduction</h2>

UEFI is a kind of BIOS to boot system and provide runtime service to OS which can do some basic IO operation with the runtime service, e.g.: reboot, power off and etc.

Normally, there are some trust firmware will be produce from UEFI building, they are responsible for trust reprogram, they include:

 UEFI_D02.fd      //UEFI executable binary file.
 CH02TEVBC_V03.bin   // CPLD binary to control power supplier.

Where to get them, please refer to [Readme.md](https://github.com/tianjiaoling/estuary/blob/mark/doc/Readme.4D02.md).

<h2 id="2">Upgrade UEFI</h2>

Note: This is not necessary unless you want to upgrade UEFI really.

FTP protocol is used for downloading between hardware boards and local network. Aboveall, please make sure you have a working FTP server in local network, so that board can get needed files from network by FTP.

1. Prepare files about UEFI on local computer

    All files mentioned above should be ready firstly, then put them in the root directory of FTP.

2. Boot board into UEFI SHELL

  Follow below steps to UEFI SHELL:
    
    a. Connect the board's UART port to a host machine with a serial cable.<br>
    b. Install a serial port application in host machine, e.g.: kermit or minicom.<br>
    c. Config serial port setting:115200/8/N/1 on host machine.<br>
    d. Reboot the board and press any key except "enter" to enter Boot Option Menu.
    
    Then the board will enter the UEFI SHELL mode.

3. Update UEFI files

    a. IP address config
       the newest edk2 base code does not support the ifconfig command in "ebl", if we must set the IP address, we have to switch to "shell" (EFI Internal Shell)
    `ifconfig -s eth0 static <IP address> <mask> <gateway>`
    
    e.g.: `ifconfig -s eth0 static 192.168.1.4 255.255.255.0 192.168.1.1`
    
    b. Burn BIOS file
       After setting the IP address done, switch back to "EBL" again.(enter "exit" to the select menu)    
      ```shell
    # Download file from FTP server to board's RAM
    provision <server IP> -u <ftp user name> -p <ftp password> -f <UEFI binary> -a <download target address>
    # Write the data into NORFLASH
    spiwfmem <source address> <target address> <data length>
    ```
    e.g.: 
    ```shell
    provision 192.168.1.107 -u sch -p aaa -f UEFI_D02.fd -a 100000
    spiwfmem 100000 0000000 300000
    ```
    c. Burn CPLD file
    
     	Notes: This is a very dangerous operation, please don't do it when not necessary.
     	
     	If you really want to do it, please make sure the power can *NOT* be shut off suddenly during updating CPLD.
     	```shell
     # Download file from FTP server to board's RAM
      provision <server IP> -u <ftp user name> -p <ftp password> -f <cpld bin> -a <target address>
     # Write the data into NORFLASH
     updatecpld <target address>
     ```
     e.g.: 
     ```
      provision 192.168.1.107 -u sch -p aaa -f CH02TEVBC_V03.bin -a 100000
      updatecpld 100000
    ```
 d. Power off and reboot board again

<h2 id="2">Recover the UEFI when it broke</h2>

Actually the board can restore two UEFI in case of the default one breaks, then you can restore it as following way:

   1. Power off the board and disconnect power supply.<br>
   2. Push the dial switch 's3' to 'off' with a '3' on the board, please check the Hardware Boards to find where it is: http://open-estuary.com/d02-2/.<br>
   3. Power on and enter UEFI SHELL again as above description.<br>
   4. Push the dial swift 's3' to 'on' with a 's' on the board.<br>
   5. Burn UEFI file for BIOS as above step3 "Update UEFI files".<br>
   6. Reset the system again.

Now you have already updated your failed BIOS, and the board will boot with new UEFI successfully.
