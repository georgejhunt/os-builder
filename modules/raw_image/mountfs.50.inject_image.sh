# Copyright (C) 2009 One Laptop Per Child
# Licensed under the terms of the GNU GPL v2 or later; see COPYING for details.

. $OOB__shlib

target_img=$intermediatesdir/rawfs.img
path=$(read_config raw_image path)
echo "fsmount is $fsmount"
if [ -z $fsmount -o -z $cachedir ]; then
   echo "fsmount is null. We MUST not  modify parent machine. Aborting . . ."
   exit 1
fi
echo "fsmount is $fsmount"

umount $fsmount &>/dev/null || :
rm -rf $fsmount/*

echo "copying image to intermediate dir $target_img"
dd if=$path of=$target_img bs=4M
	
echo "mounting image at $path to $fsmount"
mkdir -p $fsmount
mount -l loop $path $fsmount

