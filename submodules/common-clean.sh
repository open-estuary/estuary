#!/bin/bash

workspace=$(cd $2 && pwd)

sudo find ${workspace} -maxdepth 2 -type d -name common |xargs rm -rf
sudo find ${workspace} -maxdepth 4 -type d -name binary|xargs rm -rf
echo "clean common rootfs done."
