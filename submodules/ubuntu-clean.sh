#!/bin/bash -xe

#set -ex

workspace=$(cd /root/$2 && pwd)

find ${workspace} -type d -name ubuntu |xargs rm -rvf
echo "clean ubuntu done."
