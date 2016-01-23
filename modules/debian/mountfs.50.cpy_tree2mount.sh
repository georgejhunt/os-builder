# Copyright (C) 2009 One Laptop Per Child
# Licensed under the terms of the GNU GPL v2 or later; see COPYING for details.
# for debian builds, we're not actually mounting an image, we're copying a tree
. $OOB__shlib

umount $fsmount &>/dev/null || :
	
echo "Copying cached Rootfs to fsmount (where osb expects) filesystem image..."
if [ ! -z $fsmount ]; then
    rm -rf $fsmount
fi
mkdir -p $fsmount
if [ ! -f $fsmount/root/debian_cache ]; then
    cp -rp $cachedir/rootfs/* $fsmount
fi

