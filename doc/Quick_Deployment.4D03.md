* [Introduction](#1)
* [Quick Deploy System](#2)
   * [Deploy system via USB install Disk](#2.1)
   * [Deploy system via DVD/BMC-website](#2.2)
   * [Deploy system via PXE](#2.3)

## <a name="1">Introduction</a>

Above all, prepare hardware boards with SCSI disk and download Estuary source code from GitHub.  
To learn more about how to do them, please visit this web site: <http://open-estuary.org/getting-started/>.  
If you just want to quickly try it the binary files, please refer to our binary Download Page to get the latest binaries and documentations for each corresponding boards.

Accessing from China: <ftp://117.78.41.188>

Accessing from outside-China: <http://download.open-estuary.org/>
## <a name="2">Quick Deploy System</a>

### <a name="2.1">Deploy system via USB install Disk</a>

1. Connect usb disk to your pc to prepare usb install disk. We provide two methods to make USB install disk  
   **Method 1:**  
    * Modify `estuary/estuarycfg.json`. Make sure the platform, distros are all right.
    * Change the value of "install" to "yes" in object "setup" for usb and the value "device" to your USB install disk.  
    (Notice: if the specified usb device does not exist, the first usb device will be selected by default.)
    * Use `build.sh` to create the usb install disk.  
      eg: `./estuary/build.sh -f estuary/estuarycfg.json`

   **Method 2:**  
    * Download mkdeploydisk.sh from website:<ftp://117.78.41.188/releases/\<version\>> or <http://download.open-estuary.org/releases/\<version\>>
    * Execute the following command with sudo permission to make usb installing disk `sudo ./mkdeploydisk.sh`. Please specify your disk with `--target=/dev/sdx` if more than one USB disk connected to your computer. If not specified, the first detected usb device will be used. 
    * According the prompt to make usb install disk.
2. After you have made usb install disk, please connect the usb to target board.
3. Reboot the board.
4. Select "EFI USB Device" at UEFI menu.
5. According to the prompt to deploy the system.
6. Reboot board to enter the system you deployed by default.

### <a name="2.2">Deploy system via DVD/BMC-website</a>

Download ISO file from website:<ftp://117.78.41.188/releases/\<version\>> or <http://download.open-estuary.org/releases/\<version\>>  
**Deploy system via DVD**
   * Burn the iso image file to DVD disk if you use the physical DVD driver.
   * Connect the physical DVD driver to the board, plug in the DVD install disk.
   * Reboot the board.
   * Select the uefi menu to boot from the DVD device.
   * According to the prompt to deploy the system.
   * Reboot the boards to enter the system you deployed by default.

**Deploy the system via BMC-website**
   * Login the website of boards' BMC IP(e.g:https://192.168.2.100) with browser(IE browser is suggested to use), The `username` & `password` is `root` & `Huawei12#$`.
   * Click "Remote" on the top of BMC webiste. Select "Remote Virtual Console (Shared Mode)" to enter into KVM interface. Click "Image File" and choose the iso image, then click "Connect" button.
   * Click "Config" on the top of BMC website, click "Boot Option" to select "DVD-ROM drive", then click "Save" button.
   * Reboot the board
   * According to the prompt to deploy the system.
   * Reboot the boards to enter the system you deployed by default.

### <a name="2.3">Deploy system via PXE</a>

1. Connect Ubuntu PC and hardware boards into the same local area network. (Make sure the PC can connect to the internet and no other PXE servers exist.)
2. Modify the configuration file of `estuary/estuarycfg.json` based on your hardware boards. Change the values of mac to physical addresses of the connected network cards on the board. Change the value of "install" to "yes" in object "setup" for PXE.
3. Backup files under the tftp root directory if necessary. Use `build.sh` to build project and setup the PXE server on Ubuntu PC.  
   eg: `./estuary/build.sh -f estuary/estuarycfg.json`
4. After that, connect the hardware boards by using BMC ports.
5. Reboot the hardware boards and start the boards from the correct EFI Network.
6. Install the system according to prompt. After install finished, the boards will restart automatically.
7. Start the boards from "grub" menu of UEFI by default.

