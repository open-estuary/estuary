#!/bin/bash

#set -ex

workspace=$(cd /root/$2 && pwd)

find ${workspace} -type d -iname centos |xargs rm -rf
echo "clean centos done."
