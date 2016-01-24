#!/bin/bash -x
#
. $OOB__shlib
if [ -z $fsmount ]; then
    . /root/os-builder/build/intermediates/env
    . /root/os-builder/lib/shlib.sh
fi

# copy the accumuilated bash code to chroot
cp $intermediatesdir/do_in_chroot $fsmount/root
chmod 755 $fsmount/root/do_in_chroot

# bind mount the system directories that apt-get will use
for f in proc sys dev ; do mkdir -p $fsmount/$f ; done
for f in proc sys dev ; do mount --bind /$f $fsmount/$f ; done
cp /etc/resolv.conf $fsmount/etc

chroot $fsmount /root/do_in_chroot

for f in proc sys dev ; do umount -lf $fsmount/$f ; done

