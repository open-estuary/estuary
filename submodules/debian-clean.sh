#!/bin/bash -xe

#set -ex

workspace=$(cd /root/$2 && pwd)

find ${workspace} -type d -name debian |xargs rm -rvf
echo "clean debian done."
