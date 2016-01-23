#!/bin/bash -x
#
. $OOB__shlib

# communicate the desktop choice to the chroot 
mkdir -p $fsmount/root
echo xfce > $fsmount/root/desktop 


