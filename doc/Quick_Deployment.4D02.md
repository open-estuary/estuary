
* [Introduction](#1)
* [Quick Deploy System](#2)
   * [Deploy system via USB Disk](#2.1)
   * [Deploy system via DVD](#2.2)
   * [Deploy system via PXE](#2.3)

<h2 id="1">Introduction</h2>

<h2 id="2">Quick Deploy System</h2>
<h3 id="2.1">Deploy system via USB Disk</h3>

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

<h3 id="2.2">Deploy system via DVD</h3>

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

<h3 id="2.3">Deploy system via PXE</h3>

1. Prepare hardware and software environment 
    * Firstly, connect Ubuntu PC and hardware boards with SCSI Disk to the network router, this router should be connected to the internet. Secondly, connect the serial port of target boards to Ubuntu PC, install and configure minicom, do following commands:
    `$sudo minicom`

    * Add the mac address of hardware boards to the estuarycfg.json file.
    Switch on hardware boards and press anykey to enter UEFI Boot Menu. Get the MAC address of boards according to 'PXE on MAC Address:', refer to "boards" format of estuarycfg.json and add one element to "boards":
    `{"mac":"01-xx-xx-xx-xx-xx-xx"}`

    xx-xx-xx-xx-xx-xx means the MAC address of hardware board.

2. Automatically setup PXE deployment environment
    Do as following steps:
    You must disabled the DHCP server of the router.
    ```shell
    $cd ~/workdir/estuary
    $sudo ./setup_pxe.sh
    ```
    Afterwards, make selection according to prompt information.
    
    After all these, PXE deployment environment may be setuped successfully.

3. Power on the target boards 
    In UEFI shell, select PXE bootup selection. Afterwards, make selection according to prompt information. After this, the Linux system selected is deployed into the SCSI Disk of the target boards.

4. Reboot the target boards
    Now, you should enable the DHCP server of the router.
    Power on again, then select SCSI Disk startup selection in UEFI shell, and Linux system will boot up from SCSI disk.
