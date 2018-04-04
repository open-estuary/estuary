#!/bin/bash -xe

#set -ex

workspace=$(cd /root/$2 && pwd)

find ${workspace} -type d -iname ubuntu |xargs rm -rf
echo "clean ubuntu done."
