#!/bin/bash -x
# mount an SD card and generate a tar file
umount /dev/sdb1
umount /dev/sdb3
umount /dev/sdb2
umount /media/usb*
mount /dev/sdb2 /mnt
mount /dev/sdb1 /mnt/bootpart
mount /dev/sdb3 /mnt/library
pushd /mnt/opt/schoolserver/xsce
vers=$(git describe | sed 's/^v//' | sed 's/-/./g')
popd
echo $vers
fn="xo15_SD_$vers.tgz"
#exit
pushd /mnt
tar czf /root/xo15/$fn *
popd
umount /dev/sdb1
umount /dev/sdb3
umount /dev/sdb2

