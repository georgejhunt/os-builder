#!/bin/bash -x
#
. $OOB__shlib

# communicate the desktop choice to the chroot 
mkdir -p $fsmount/root
echo xfce4 > $fsmount/root/desktop 


