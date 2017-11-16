#!/bin/bash -xe

workspace=$(cd /root/$2 && pwd)

find ${workspace} -type d -name minifs |xargs rm -rf
echo "clean minirootfs done."
