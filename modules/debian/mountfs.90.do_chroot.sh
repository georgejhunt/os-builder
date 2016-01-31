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

xo_type=$(read_laptop_model_number)
if [ $xo_type -eq 4 ]; then
cat << _SET_CHROOT > $fsmount/root/set_chroot
    # on the test laptop
    cp /etc/resolv.conf /mnt/etc/
    for x in dev proc sys tmp; do mount -o bind /\$x /mnt/\$x; done
    chroot /mnt /root/do_in_chroot
_SET_CHROOT
chmod 755 $fsmount/root/set_chroot

    # set the ip addr of xo in /etc/hosts on os-builder machine
    echo Copying rootfs to remote xo
    rsync --archive --delete $fsmount/ root@xo:/mnt

    # abort the os-buildeer
    exit 1
fi

# bind mount the system directories that apt-get will use
for f in proc sys dev ; do mkdir -p $fsmount/$f ; done
for f in proc sys dev ; do mount --bind /$f $fsmount/$f ; done
cp /etc/resolv.conf $fsmount/etc

chroot $fsmount /root/do_in_chroot

for f in proc sys dev ; do umount -lf $fsmount/$f ; done

