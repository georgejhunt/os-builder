# Copyright (C) 2009 One Laptop Per Child
# Licensed under the terms of the GNU GPL v2 or later; see COPYING for details.
# for debian builds, we're not actually mounting an image, we're copying a tree
. $OOB__shlib

xo_type=$(read_laptop_model_number)
umount $fsmount &>/dev/null || :
	
echo "Copying cached Rootfs to fsmount (where osb expects) filesystem image..."
if [ ! -z $fsmount ]; then
    rm -rf $fsmount
fi
mkdir -p $fsmount
case $xo_type in
0 | 1 )
    cp -rp $cachedir/rootfs/* $fsmount
    ;;
4 )
    cp -rp $cachedir/arm_rootfs/* $fsmount
    ;;
esac

