**Readme for Ubuntu ARM64**

Install the latest perf binary*

`$# sudo apt-get  install linux-tools-3.19.0-23`

*- The latest version availabe can be installed.

Now use the perf tool installed in `/usr/lib/linux-tools-3.19.0-23/perf`

`$# /usr/lib/linux-tools-3.19.0-23/perf stat -e L1-dcache-stores ls -l`

The LLC, MN and DDR are added as RAW events.

The RAW event encoding format is as below

`<die ID(4 bit)><Module ID(4 bit)><Bank(4 bit)><event code(12 bit)>`

Ex: For LLC_READ_ALLOCATE event for TotemC will be 0x24f300, where

0x2 is DieID for TotemC, 0x4 is the ModuleID of LLC, 0xf is for all

LLC banks, 0x300 is the event code for LLC_READ_ALLOCATE

The Module ID's are as below
 ```
LLC	= 0x4
MN	= 0xb
DDRC0	= 0x8
DDRC1	= 0xd
```

The DieID for the CPU Die are as below

```
SOC0_TOTEMA = 0x1 /* TOTEM A in Socket 0 */
SOC0_TOTEMC = 0x2
SOC0_TOTEMB = 0x3
SOC1_TOTEMA = 0x4
SOC1_TOTEMC = 0x5
SOC1_TOTEMB = 0x6
```

The 22 LLC events are added as RAW events starting from 0x300 to 0x315

The 9 MN event codes and also the DDRC read, write and latecy counters 

event codes are listed below

```
LLC_READ_ALLOCATE 		= 0x300
LLC_WRITE_ALLOCATE 		= 0x301
LLC_READ_NOALLOCATE		= 0x302
LLC_WRITE_NOALLOCATE		= 0x303
LLC_READ_HIT			= 0x304
LLC_WRITE_HIT			= 0x305
LLC_CMO_REQUEST			= 0x306
LLC_COPYBACK_REQ		= 0x307
LLC_HCCS_SNOOP_REQ		= 0x308
LLC_SMMU_REQ			= 0x309
LLC_EXCL_SUCCESS		= 0x30A
LLC_EXCL_FAIL			= 0x30B
LLC_CACHELINE_OFLOW		= 0x30C
LLC_RECV_ERR			= 0x30D
LLC_RECV_PREFETCH		= 0x30E
LLC_RETRY_REQ			= 0x30F
LLC_DGRAM_2B_ECC		= 0x310
LLC_TGRAM_2B_ECC		= 0x311
LLC_SPECULATE_SNOOP		= 0x312
LLC_SPECULATE_SNOOP_SUCCESS	= 0x313
LLC_TGRAM_1B_ECC		= 0x314
LLC_DGRAM_1B_ECC		= 0x315

MN_EO_BARR_REQ			= 0x316
MN_EC_BARR_REQ			= 0x317
MN_DVM_OP_REQ			= 0x318
MN_DVM_SYNC_REQ			= 0x319
MN_READ_REQ			= 0x31A
MN_WRITE_REQ			= 0x31B
MN_COPYBK_REQ			= 0x31C
MN_OTHER_REQ			= 0x31D
MN_RETRY_REQ			= 0x31E

DDRC0_FLUX_READ_BW		= 0x31F
DDRC0_FLUX_WRITE_BW		= 0x320
DDRC0_FLUX_READ_LAT		= 0x321
DDRC0_FLUX_WRITE_LAT		= 0x322
DDRC1_FLUX_READ_BW		= 0x323
DDRC1_FLUX_WRITE_BW		= 0x324
DDRC1_FLUX_READ_LAT		= 0x325
DDRC1_FLUX_WRITE_LAT		= 0x326
```
```shell
# To count LLC_WRITE_NOALLOCATE and LLC_READ_ALLOCATE for TotemC

$# /usr/lib/linux-tols-3.19.0-23/perf stat -e r24f303 -e r24f300 ls -l
```

```shell
# To count MN_EO_BARR_REQ and LLC_READ_ALLOCATE for TotemA

$# /usr/lib/linux-tols-3.19.0-23/perf stat -e r1bf316 -e r14f300 ls -l
```
```
# To count LLC_READ_HIT and LLC_WRITE_HIT for a process with pid
$# /usr/lib/linux-tools-3.19.0-23/perf stat -e r24f304,r24f305 -p <pid>
```

Known Issues:

1. As Hisilicon hardware counters are not CPU core specific, the counter

   values maynot be accurate. To get more accurate count. please append the

   option "-C 0 -A" in perf stat command.
 
  `$# perf stat -C 0 -A -e r24f303 -e r24f300 ls -l`

2. As the counter registers in Hisiilicon are config and accessed via

  Djtag interface, it can affect the event counter readings as the access

  is not atomic.
