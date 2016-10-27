* [Introduction](#1)
* [Preparation](#2)
   * [Hardware Connect](#2.1)
   * [PC Environment](#2.2)
   * [Image File](#2.3)
* [Upgrade Systerm](#3)
   * [Flash Uefi image to eMMC](#3.1)
   * [Flash Boot image to eMMC](#3.2)
   * [Update Distrubition](#3.3)
     * [SD card placing this ubuntu systerm](#3.3.1)
     * [eMMC on HiKey placing this ubuntu systerm](#3.3.2)
* [Appendix 1: Partition Information](#4) 


## <a name="1">Introduction</a>

This documentation provides a general overview for getting started with Estuary Release Distributions such as ubuntu, debian and so on to support the HiKey board, There are two primary ways to install software onto the HiKey board as thissample of ubuntu systerm.  
First and simplest, you can install uefi image, boot image into eMMC on HiKey board while installing Estuary Release Distributions such as ubuntu, debian and so on into SD card. You can download uefi image and boot image by fastboot mode while using SD card to load Estuary Release Distributions. It follows the instructions in "Update systerm" chapter.  
Second, you also can install uefi image, boot image and Estuary Release Distributions such as ubuntu, debian and soon into eMMC on HiKey board. You can download uefi image and boot image by fastboot mode while loading Estuary Release Distributions into eMMC by wifi mode. It follows the instructions in "Update systerm" chapter.

## <a name="2">Preparation</a>

The HiKey board is ready to use “out of the box” with a preinstalled version of the Debian Linux distribution from the factory. To get started you need power supply(9V~15V ,2A), a standard microUSB cable, usb to serial port(TTL 1.8V),SD card and PC.

### <a name="2.1">Hardware Connect</a>

1. Connect standard microUSB to USB connector between the HiKey microUSB port and Linux PC.  
2. Connect usb to serial port to USB connector between the HiKey (UART3 J2) and Linux PC.  
3. Link 1-2 (J601) pin causes HiKey to auto-power up when power is applied.  
4. Connect the HiKey power supply to the HiKey board (Uart3 P301).  
NOTE: please refer to the Hardware User Guide for more information on board link options. you can visit: http://open-estuary.com/hikey/

### <a name="2.2">PC Environment</a>

1. Ensure PC is Linux systerm.  
2. Config a serial com on PC such as kermit, mincom and so on.  
3. Install fastboot tool, you do it as follows:  
   ```bash
   $ sudo apt-get update
   $ sudo apt-get install android-tools-fastboot
   ```

4. Install Python, you can do it as follows:  
   ```bash
   $ sudo apt-get update
   $ sudo apt-get install python2.7 python2.7-dev
   $ alias python=python2.7
   ```

### <a name="2.3">Image File</a>
```bash
$ mkdir hikey-image
$ cd hikey-image
$ cp {pwd}/open-estuary/build/HiKey/binary/* ./  -rf
$ sudo cp {pwd}/open-estuary/build/HiKey/distro/* ./  -rf
```
NOTE: you can get more information about Image explaination from this [Readme.md](https://github.com/open-estuary/estuary/blob/master/doc/Readme.4HiKey.md) document.

## <a name="3">Upgrade Systerm</a>

When most users get HiKey board first, they want to reload the all system image by using instructions. However, this section will describes how to reinstall all system image.

### <a name="3.1">Flash Uefi image to eMMC</a>
The flashing process requires to be in "recovery mode" which will link 1-2 (J601) and link 3-4(J601) with setting board link options as follow:  
```bash
Name             Link               State
Auto Power up    Link 1-2           closed
Boot Select      Link 3-4           closed
GPIO3-1          Link 5-6           open
 ```
Link 1-2 causes HiKey to auto-power up when power is installed. Link 3-4 causes the HiKey SoC internal ROM to start up in at a special "install bootloader" mode which will install a supplied bootloader from the microUSB OTG port into RAM, and will present itself to a connect PC as a ttyUSB device.  
Note: USB does NOT power the HiKey board because the power supply requirements in certain use cases can exceed the power supply available on a USB port. You must use an external power supply.  
If you can understand above information, you will start to flash this image according to this instruction:  

1. Turn off HiKey board  
2. Connect debug UART3 on HiKey to PC (used to monitor debug status)  
3. Make sure pin1-pin2 and pin3-pin4 on J601 are linked (recovery mode)  
4. Connect HiKey MicroUSB to PC with USB cable  
5. Turn on HiKey board and flash this image  
   On serial console, you should see some debug message (NULL packet) run HiKey recovery tool to flash l-loader.bin  

   Note: if the serial port recorded in hisi-idt.py isn't available, adjust the command line below by manually setting the serial port with "-d /dev/ttyUSBx" where x is usually the last serial port reported by "dmesg" command
   ```bash
   $ cd hikey-image
   $ sudo python hisi-idt.py -d /dev/ttyUSBx --img1=l-loader.bin
   ```
   Do not reboot yet. Run fastboot commands to flash the images (order must be respected)
   ```bash
   $ sudo fastboot flash ptable ptable-linux.img
   $ sudo fastboot flash fastboot UEFI_HiKey.fd
   $ sudo fastboot flash nvme nvme.img
   ```
6. Turn off HiKey board
7. Remove the jumper of pin3-pin4 on J601
8. Connected the jumper of pin5-pin6 on J601(fastboot mode)

### <a name="3.2">Flash Boot image to eMMC</a> 

The boot partition is a 64MB FAT partition and contains kernel/dtb, grub files and so on. You should make the boot-fat.uefi.img image and flash this image according to follow this instruction:  
```bash
$ cd hikey-image
$ mkdir boot-fat
$ dd if=/dev/zero of=boot-fat.uefi.img bs=512 count=131072
$ sudo mkfs.fat -n "BOOT IMG" boot-fat.uefi.img
$ sudo mount -o loop,rw,sync boot-fat.uefi.img boot-fat
$ sudo cp Image_HiKey hi6220-hikey.dtb boot-fat/ || true
$ sudo cp grubaa64.efi grub.cfg boot-fat/ || true
$ sudo cp mini-rootfs-arm64.cpio.gz boot-fat/mini-rootfs.cpio.gz || true
$ sudo cp AndroidFastbootApp.efi boot-fat/fastboot.efi
$ sudo umount boot-fat
$ rm -rf boot-fat
```
NOTE: More detail information about how to write this grub.cfg, please refer to [GRUB_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/Grub_Manual.4All.md) document.

If you finish making boot-fat.uefi.img image, you start to flash this image according to this instruction:  
1. Turn off HiKey board  
2. Connect debug UART3 on HiKey to PC (used to monitor debug status)  
3. Make sure pin1-pin2 and pin5-pin6 on J601 are linked (recovery mode)  
4. Connect HiKey Micro-USB to PC with USB cable  
5. Turn on HiKey board and flash this image  
   `$ sudo fastboot flash boot boot-fat.uefi.img`  
6. Turn off HiKey board
### <a name="3.3"> Update Distrubition</a> 

You can select SD card or eMMC on HiKey board to place the Estuary release distrubition such as ubuntu. This part will explain how to use SD card and eMMC on HiKey board to boot ubuntu.

#### <a name="3.3.1">SD card placing this ubuntu systerm</a> 

You should partion SD card (8G) and tar this Ubuntu_ARM64.tar.gz into your SD card according to this instruction:

1. Insert SD card into your linux PC by card reader  
2. Grep SD card node and fdisk or partion SD card in your linux PC
   ``` bash
   $ sudo parted /dev/sdx
   (parted) mklabel gpt
   (parted) mkpart primary ext4 1MB 7086MB
   (parted) q
   $ sudo mkfs.ext4 -L "ubuntu" /dev/sdx1
   ```
3. Remove and insert SD card in your PC  
4. Tar Ubuntu_ARM64.tar.gz into your SD card  
   ```bash
   $ cd hikey-image	
   $ tar -xvzf Ubuntu_ARM64.tar.gz -C /media/{admin}/ubuntu
   ```
5. Insert SD card into HiKey board  
6. Turn on HiKey board  
7. Select "grub on eMMC" from uefi options  
8. Select "Hikey Ubuntu SD card" from grub options  
9. Success to boot ubunt system  
NOTE: WIFI config about mini-rootfs systerm please refer to [Setup_HiKey_Wifi_Env.md](https://github.com/open-estuary/estuary/blob/master/doc/Setup_HiKey_WiFi_Env.4HiKey.md) document

#### <a name="3.3.2">eMMC on HiKey placing this ubuntu systerm</a> 

If you purchase HiKey board which eMMC is 8G, We recommend you to use eMMC HiKey placing this ubuntu systerm. Estuary provides ptable image which will suport 8G eMMC HiKey board.In return you purchase HiKey board which eMMC is 4G, We recommend you to use SD card placing this ubuntu syterm because Estuary release distribution volume is 4G~5G or so. However, you also may use HiKey board which eMMC is 4G to place this clipping ubuntu systerm.  
You can place this ubuntu systerm into eMMC on HiKey according to this following instruction:  

1. Turn on HiKey board  
2. Select "grub on eMMC" from uefi options  
3. Select "Hikey minilinux eMMC" from grub options (boot min rootfs)  
4. Refer to [Setup_HiKey_Wifi_Env.md](https://github.com/open-estuary/estuary/blob/master/doc/Setup_HiKey_WiFi_Env.4HiKey.md) document to config WIFI link  
5. Download this ubuntu systerm into eMMC on HiKey board  
   ```bash
   $ mount /dev/mmcblk0p9 /tmp
   $ cd /tmp
   $ false; while [ $? -ne 0 ]; do wget -c http://7xjz0v.com1.z0.glb.clouddn.com/dist_<version>/Ubuntu_ARM64.tar.gz; done
   $ tar -xvzf Ubuntu_ARM64.tar.gz
   $ cd /
   $ mount /tmp
   ```

6. Reboot HiKey board  
7. Select "grub on eMMC" from uefi options.  
8. Select "Hikey Ubuntu eMMC" from grub options  
9. Success to boot ubunt systerm  

NOTE: WIFI config about ubuntu systerm please refer to [Setup_HiKey_Wifi_Env.md](https://github.com/open-estuary/estuary/blob/master/doc/Setup_HiKey_WiFi_Env.4HiKey.md) document

### <a name="4">Appendix 1: Partition Information</a>

Table 1 describes the partition layout on the HiKey eMMC.
```bash
Device            Start   End   Sectors  name
/dev/mmcblk0p1    2048    4095    2048    vrl
/dev/mmcblk0p2    4096    6143    2048    vrl_backup
/dev/mmcblk0p3    6144    8191    2048    mcuimage
/dev/mmcblk0p4    8192   24575   16384    fastboot
/dev/mmcblk0p5   24576   28671    4096    nvme
/dev/mmcblk0p6   28672  159743  131072    boot
/dev/mmcblk0p7  159744  684031  524288    reserved
/dev/mmcblk0p8  684032 1208319  524288    cache
/dev/mmcblk0p9 1208320 7818182656         system
```
