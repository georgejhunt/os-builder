#!/bin/bash
# get the debian rootfs into the cache

# the following sources os-builder-root/lib/shlib.sh (OOB__shlib is in env)
. $OOB__shlib

debian_release=$(read_config debian debian_release)
mkdir -p $cachedir/rootfs
if [ ! -f $cachedir/rootfs/etc ];then
   
