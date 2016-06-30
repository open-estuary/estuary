#!/bin/bash

###################################################################################
# get_all_usb_device
###################################################################################
get_all_usb_device()
{
	sudo lshw | grep "bus info: usb" -A 12 | grep "logical name: /dev/sd" | grep -Po "(/dev/sd.*)" | sort
}

###################################################################################
# get_1st_usb_storage
###################################################################################
get_1st_usb_storage()
{
	(
	root_dev=$(mount | grep " / " | grep  -Po "(/dev/sd[^ ]*)")
	if [ x"" = x"$root_dev" ]; then
		root_dev="/dev/sdx"
	fi
	
	usb_devs=($(get_all_usb_device | grep -v $root_dev))
	echo ${usb_devs[0]}
	)
}


