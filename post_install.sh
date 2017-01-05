#!/bin/bash
#author: Justin Zhao
#date: 31/10/2015
#description: automatically call all post install scripts in post_dir

lastupdate="2015-10-15"
post_dir="/usr/bin/estuary/postinstall"

###################################################################################
############################# Check initilization status ##########################
###################################################################################
check_init()
{
    tmpfile=$1
    tmpdate=$2

    if [ -f "$tmpfile" ]; then
	    inittime=`stat -c %Y $tmpfile`
	    checktime=`date +%s -d $tmpdate`

	    if [ $inittime -gt $checktime ]; then
	          return 1
	    fi
	fi

	return 0
}

netstatus=${post_dir}/.network
if [ ! -f ${netstatus} ]; then
	netrst=`ping www.baidu.com -c 4`
	rcv=`echo "$netrst" | grep -E "..received" -o`
	if [ x"0" != x"$?" ]; then
		exit 1
	fi
	rcv=`echo "$rcv" | cut -d " " -f1`
	if [ x"0" = x"$rcv" ]; then
		exit 1
	fi
fi

# preprocess...
if [ ! -f $netstatus ]; then
	echo "$netrst" > $netstatus
fi

for fullfile in $post_dir/*
do
	file=${fullfile##*/}
	if [ -f $fullfile ]; then
		check_init "$post_dir/.$file" $lastupdate
		if [ x"0" = x"$?" ]; then
			$fullfile
			if [ x"0" = x"$?" ]; then
				touch "$post_dir/.$file"
			fi
		fi
	fi
done
#enable function_graph as default tracer
#echo function_graph > /sys/kernel/debug/tracing/current_tracer

# Workaround for the tools modules which are not getting installed on rootfs automatically.
depmod -a
modprobe lttng-clock
modprobe lttng-kprobes
modprobe lttng-probe-kvm
modprobe lttng-probe-sock
modprobe lttng-ring-buffer-metadata-client
modprobe lttng-probe-printk
modprobe lttng-probe-napi
modprobe lttng-probe-v4l2
modprobe lttng-statedump
modprobe lttng-probe-btrfs
modprobe lttng-ring-buffer-client-mmap-discard
modprobe lttng-probe-kmem
modprobe lttng-probe-compaction
modprobe lttng-ring-buffer-client-overwrite
modprobe lttng-ring-buffer-client-mmap-overwrite
modprobe lttng-probe-sunrpc
modprobe lttng-ftrace
modprobe lttng-probe-signal
modprobe lttng-probe-module
modprobe lttng-ring-buffer-client-discard
modprobe lttng-probe-timer
modprobe lttng-probe-net
modprobe lttng-probe-writeback
modprobe lttng-probe-gpio
modprobe lttng-probe-i2c
modprobe lttng-probe-udp
modprobe lttng-ring-buffer-metadata-mmap-client
modprobe lttng-lib-ring-buffer
modprobe lttng-probe-jbd2
modprobe lttng-probe-statedump
modprobe lttng-probe-ext4
modprobe lttng-probe-rcu
modprobe lttng-tracer
modprobe lttng-probe-power
modprobe lttng-probe-sched
modprobe lttng-probe-block
modprobe lttng-probe-vmscan
modprobe lttng-probe-scsi
modprobe lttng-probe-regmap
modprobe lttng-probe-skb
modprobe lttng-probe-regulator
modprobe lttng-probe-random
modprobe lttng-probe-workqueue
modprobe lttng-probe-irq
