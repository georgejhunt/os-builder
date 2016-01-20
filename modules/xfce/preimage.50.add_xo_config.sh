#!/bin/bash -x
#
. $OOB__shlib


#rm $kernel
#rm /root/kernel_name
EOF
# and make it executable
chmod 755 $fsmount/root/preimage.sh

# communicate the desktop choice to the chroot 
desktop=$(read_config debian desktop)
if [ ! -z $desktop ];then
   echo $desktop > $fsmount/root/desktop 
fi

# set up the chroot
mkdir -p $fsmount/dev
mount -o bind /dev $fsmount/dev
mkdir -p $fsmount/proc
mount -o bind /proc $fsmount/proc
mkdir -p $fsmount/sys
mount -o bind /sys $fsmount/sys
mkdir -p $fsmount/tmp
mount -o bind /tmp $fsmount/tmp
cp -f /etc/resolv.conf $fsmount/etc/resolv.conf

# now execute the script 
chroot $fsmount /root/preimage.sh

# unmount bind mounted dirs
umount $fsmount/dev
umount $fsmount/proc
umount $fsmount/sys
umount $fsmount/tmp

