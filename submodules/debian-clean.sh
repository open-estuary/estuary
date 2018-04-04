#!/bin/bash -xe

#set -ex

workspace=$(cd /root/$2 && pwd)

find ${workspace} -type d -iname debian |xargs rm -rf
echo "clean debian done."
