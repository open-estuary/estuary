* [LTTNG](#1)
* [Ubuntu](#2)
* [Fedora](#3)
* [OpenSuse](#4)

<h2 id="1">LTTNG</h2>

Installtion and building of lttng kernel modules (lttng-modules-dkms) using apt-get does not work on estuary Ubuntu platform.

Thus lttng module build from source code and installed into rootfs.

The source code of lttng kernel module worked is lttng-modules-2.6.4.tar.bz2 (ubuntu version)

downloaded from https://lttng.org/download/#build-from-source

<h2 id="2">Ubuntu</h2>

- LTTNG user space packages are available to install in Ubuntu distribution.

  ```apt-get install -y lttng-tools
apt-get install -y liblttng-ust-dev```

- The armor-postinstall.sh script does the lttng user space packages installations on first bootup.


<h2 id="3">Fedora</h2>

- LTTNG user space packages are available to install in Fedora distribution.
 ```
dnf install -y lttng-tools.aarch64
dnf install -y lttng-ust.aarch64
dnf install -y babeltrace.aarch64
 ```

- The armor-postinstall.sh script does the lttng user space package installations on first bootup.


<h2 id="4">OpenSuse</h2>

LTTNG packages are not available to install in OpenSuse distribution.

Thus lttng-tools and lttng-ust to be natively built on target board from source code and

install using the build script present in the `/usr/local/armor/build_scripts/build_lttng_tools_opensuse.sh`
in the rootfs.  

