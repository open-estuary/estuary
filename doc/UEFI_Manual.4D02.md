* [Introduction](#1)
* [Upgrade UEFI](#2)
* [Recover the UEFI when it broke](#3)

<h2 id="1">Introduction</h2>

UEFI is a kind of BIOS to boot system and provide runtime service to OS which can do some basic IO operation with the runtime service, e.g.: reboot, power off and etc.

Normally, there are some trust firmware will be produce from UEFI building, they are responsible for trust reprogram, they include:

 UEFI_D02.fd      //UEFI executable binary file.
 CH02TEVBC_V03.bin   // CPLD binary to control power supplier.

Where to get them, please refer to [Readme.txt](https://github.com/tianjiaoling/estuary/blob/mark/doc/Readme.txt.4D02).

<h2 id="2">Upgrade UEFI</h2>

<h2 id="2">Recover the UEFI when it broke</h2>
