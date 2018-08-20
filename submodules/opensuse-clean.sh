#!/bin/bash

workspace=$(cd /root/$2 && pwd)

find ${workspace} -type d -iname opensuse |xargs rm -rf
echo "clean opensuse done."
