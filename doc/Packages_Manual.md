* [Introduction](#1)
* [Packages Installation](#2)
* [Application Integration and Optimization](#3)
* [Others](#4)


<h2 id="1">Introduction</h2>

According to the [EstuaryCfg.json](https://github.com/open-estuary/estuary/blob/master/estuarycfg.json) 
packages could be integrated into Estuary accordingly. 

<h2 id="2">Packages Installation</h2>

Typically packages could be installed via two ways:
- RPM/Deb Repositories:
  - As for how to install rpm/deb packages, please refer to [Open-Estuary Repository README](https://github.com/open-estuary/distro-repo/blob/master/README.md)
- Docker Images:
  - Use`docker pull openestuary/<app name>` to install the corresponding docker images. For more information, please refer to the corresponding manuals mentioned below. 

<h2 id="3">Application Integration and Optimization</h2>
For details, please refer to [Estuary Application Integration and Optimization based on ARM64 Server](https://github.com/open-estuary/packages)
       
<h2 id="4">Others</h2>

- The yum/deb repositories will be supported officially from Estuary V500 release
- If you come across any issue (such as supporting new packages on ARM64 platform, enhancing packages performance on ARM64 platforms, and so on) during using above packages, please feel free to contact with us by using any of following ways:
  - Visit www.open-estuary.com website, and submit one bug
  - Report one issue in this github issue page
  - Email to sjtuhjh@hotmail.com
