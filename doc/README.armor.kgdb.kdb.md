* [Readme for KGDB and KDB Tools](#1)
* [Debugging using KGDB](#2)

<h2 id="1">Readme for KGDB and KDB Tools</h2>

1. Enable following configurations in the open-estuary kernel defconfig file, if it is not already done.
   ```shell
CONFIG_HAVE_ARCH_KGDB=y
CONFIG_KGDB=y
CONFIG_KGDB_SERIAL_CONSOLE=y
CONFIG_KGDB_TESTS=y
CONFIG_KGDB_KDB=y

CONFIG_KDB_DEFAULT_ENABLE=0x1
CONFIG_KDB_KEYBOARD=y
CONFIG_KDB_CONTINUE_CATASTROPHIC=0

CONFIG_MAGIC_SYSRQ=y
  ```
2. Build kernel. 

3. Set Kernel Debugger Boot Arguments (kgdboc=ttyS0,115200) in the grub.conf file as given in the following example.  
   ```shell
menuentry "ubuntu64-nfs" --id ubuntu64-nfs {
    set root=(tftp,192.168.0.3)
    linux /ftp-X/Image rdinit=/init console=ttyS0,115200  kgdboc=ttyS0,115200 earlycon=uart8250,mmio32,0x80300000 ...
    devicetree /ftp-X/hip05-d02.dtb
}
```
4. Boot the target D02 board with the above grub.conf and kernal image built in step `2`.

5. On D02, enter the kernel debugger(kdb) manually or by waiting for an oops or fault. 
    There are several ways you can enter the kernel debugger manually; all involve using the sysrq-g. 
   
    When logged in as root or with a super user session you can run:
    `echo g > /proc/sysrq-trigger`  
    This will enter kdb terminal and then coninue with kernel debugging using kdb commands. 
    
 <h2 id="2">Debugging using KGDB</h2>

6. On D02 kdb terminal type 'kgdb' command. Then please attach debugger from host machine to remotely debug using gdb.

7. On the host machine install gdb-multiarch
   `sudo adb-get install gdb-multiarch`   

8. run command on the host machine. 'sudo gdb-multiarch ./vmlinux' 
   where vmlinux is the uncompressed kernel image built in step (2). 

9. On the gdb terminal, run following commands

  (gdb) set remote interrupt-sequence Ctrl-C BREAK BREAK-g  -> optional 
  
  (gdb) set serial baud 115200 -> set serial baud rate
  
  (gdb) set debug remote 1  -> optional for more gdb debug messages
  
  (gdb) target remote /dev/ttyUSB1 -> connect to the kgdb over serial port /dev/ttyUSB1 on host machine.

  (gdb) target remote `/dev/ttyUSB1`
  
   Remote debugging using `/dev/ttyUSB1`
   
   Sending packet: `$qSupported:multiprocess+;xmlRegisters=i386;qRelocInsn+#b5...Ack`
   
   ..........
   
   Sending packet: `$g#67...Ack`
   
   Packet received: `801b0901c0ffffff01000000000000000000000000000000881b0901c0ffffff1600000000000000ff01000000000000545d5900c0ffffffa066f200c0ffffff5b01000000000000000000000000000006000000000000000090f400c0ffffff06000000000000003000000000000000ffffffffffffff0f1100000000000000010000000000000000000000000000002f33ad44000000003035f500c0ffffff801b0901c0ffffff801b0901c0ffffff801b0901c0ffffffd0d3fc00c0ffffff000000000000000000a6e800c0ffffff70e2e200c0ffffff00e00501c0ffffffa0a5e800c0ffffff207ddcf6d1ffffff08e11500c0ffffff207ddcf6d1ffffffbccc1500c0ffffff450000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000`
   
   Sending packet: `$mffffffc00015ccbc,4#15...Ack`
   
   Packet received: `208020d4`
   
   arch_kgdb_breakpoint () at `./arch/arm64/include/asm/kgdb.h:32`
   
   `32      ./arch/arm64/include/asm/kgdb.h`: No such file or directory.
   
   Sending packet: `$qSymbol::#5b...Ack`
   
   Packet received:
    
10. Once the gdb successfully connected to the remote kgdb on D02, kernel can be debugged as user space applications using normal gdb commands.
