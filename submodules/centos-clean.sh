#!/bin/bash -xe

#set -ex

workspace=$(cd /root/$2 && pwd)

find ${workspace} -type d -name centos |xargs rm -rf
echo "clean centos done."
