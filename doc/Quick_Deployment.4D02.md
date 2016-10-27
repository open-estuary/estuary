* [Introduction](#1)
* [Quick Deploy System](#2)
   * [Deploy system via USB Disk](#2.1)
   * [Deploy system via DVD](#2.2)
   * [Deploy system via PXE](#2.3)


## <a name="1">Introduction</a>

Above all, prepare hardware boards with SCSI disk and download Estuary source code from GitHub.
To learn more about how to do them, please visit this web site: http://open-estuary.com/estuary-user-manual/ , and then refer to ‘Get & Build Estuary yourself’.  
**Note**: In my case, the working directory is `~/workdir`.

## <a name="2">Quick Deploy System</a>
### <a name="2.1">Deploy system via USB Disk</a>

1. Prepare usb install disk.
    * Modify estuary/estuarycfg.json. Make sure the platform, distros are all right.  
    * Change the value of "install" to "yes" in object "setup" for usb and the value "device" to your USB install disk.  
      (Notice: if the specified usb device does not exist, the first usb device will be selected by default.)  
    * Use build.sh to create the usb install disk.  
      `eg: ./estuary/build.sh -f estuary/estuarycfg.json`  
2. Connect the usb install disk to the board.  
3. Reboot the board.  
4. Boot from the usb device. (About how to boot from USB device, please refer to the UEFI related manual.)  
5. According to the prompt to deploy the system.  
6. Start the boards from "grub" menu of UEFI by default.  

### <a name="2.2">Deploy system via DVD</a>

1. Prepare ISO image and install disk.
   * Modify estuary/estuarycfg.json. Make sure the platform, distros are all right.  
   * Change the value of "install" to "yes" in object "setup" for iso and the value "name" to your target iso image file name.  
   * Use build.sh to create the target install iso image file.  
     eg: `./estuary/build.sh -f estuary/estuarycfg.json`  
   * Burn the iso image file to DVD disk if you use the physical DVD driver.  
2. Connect the physical DVD driver to the board, plug in the install DVD disk.  
3. Reboot the board.  
4. Boot from the DVD device. (About how to boot from DVD device, please refer to the UEFI related manual.)  
5. According to the prompt to deploy the system.  
6. Start the boards from "grub" menu of UEFI by default.

### <a name="2.3">Deploy system via PXE</a>

1. Connect Ubuntu PC and hardware boards into the same local area network. (Make sure the PC can connect to the internet and no other PXE servers exist.)  
2. Modify the configuration file of estuary/estuarycfg.json based on you hardware boards. Change the values of mac to physical addresses of the connected network cards on the board. Change the value of "install" to "yes" in object "setup" for PXE.  
3. Backup files under the tftp root directory if necessary. Use build.sh to build project and setup the PXE server on Ubuntu PC.  
   eg: `./estuary/build.sh -f estuary/estuarycfg.json`  
4. After that, install minicom and connect the serial ports of hardware boards to the Ubuntu PC. Connect the hardware boards by minicom using serial ports.  
5. Reboot the hardware boards and start the boards from the correct EFI Network.  
6. Install the system according to prompt. After install finished, the boards will restart automatically.  
7. Start the boards from "grub" menu of UEFI by default.
