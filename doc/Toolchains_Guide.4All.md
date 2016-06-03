This is the guide for toolchains

If your host machine and target machine have the different architecture, you have to prepare toolchains before you build any target binaries.

E.g. if you are building an arm-based target binary on Intel machine, you must use them in your host machine.
By default, after you do `./esutary/build.sh -i toolchain`, the toolchain will be install your host machine's `/opt` directory.

And the original toolchains files will be download into `<project root>/toolchain` directory too.
```shell
    gcc-linaro-aarch64-linux-gnu-4.9-2014.09_linux.tar.xz   # this is for aarch64 architecture.
    gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux.tar.xz # this is for arm32 architecture.
```

Of course, you can install the toolchains yourself with following commands (take the aarch64 as example):
```shell
    pushd toolchain
    sudo mkdir -p /opt 2>/dev/null
    sudo tar -xvf gcc-linaro-aarch64-linux-gnu-4.9-2014.09_linux.tar.xz -C /opt
    str='export PATH=$PATH:/opt/gcc-linaro-aarch64-linux-gnu-4.9-2014.09_linux/bin' 
    grep "$str" ~/.bashrc >/dev/null
    if [ x"$?" != x"0" ]; then echo "$str">> ~/.bashrc; fi
    source ~/.bashrc
  ```
