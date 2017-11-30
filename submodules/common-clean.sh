#!/bin/bash -xe

workspace=$(cd $2 && pwd)

sudo find ${workspace} -maxdepth 2 -type d -name common |xargs rm -rf
echo "clean common rootfs done."
