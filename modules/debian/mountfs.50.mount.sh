# Copyright (C) 2009 One Laptop Per Child
# Licensed under the terms of the GNU GPL v2 or later; see COPYING for details.

. $OOB__shlib
echo "fsmount is $fsmount"
cachedir=/root/os-builder/build/cache
if [ -z $fsmount -o -z $cachedir ]; then
   echo "fsmount is null. We MUST not  modify parent machine. Aborting . . ."
   exit 1
fi
echo "fsmount is $fsmount"

target_img=$intermediatesdir/rawfs.img

umount $fsmount &>/dev/null || :
	
echo "Copying cached Rootfs to fsmount (where osb expects) filesystem image..."
mkdir -p $fsmount
echo "in mount. fsmount is $fsmount"
if [ ! -f $fsmount/root/debian_cache ]; then
    cp -rp $cachedir/rootfs/* $fsmount
fi

