#!/bin/bash 
# create partitions for XO1.5 SD card
# copy the tar file to the newly formatted SD card

if [ $# -ne 1 ]; then
  echo "Pass the name of tgz file as first parameter"
  exit 1
fi

DEV=/dev/sdb
umount /media/usb*
umount ${DEV}3
umount ${DEV}1 
umount ${DEV}2 

parted --script ${DEV} print
read -p "I''m about to destroy all data. Hit <ctl>C to about" ans

parted --script ${DEV} mklabel msdos

parted --script --align optimal ${DEV} unit MB mkpart primary ext4 4MB 60MB
parted --script ${DEV} set 1 hidden on
parted --script ${DEV} set 1 boot on
parted --script --align optimal ${DEV} unit MB mkpart primary ext4 61MB 7000MB 
parted --script ${DEV} set 2 hidden on
parted --script --align optimal ${DEV} unit MB 'mkpart primary ntfs 7001MB -1s'
partprobe
parted --script ${DEV} print

# partprobe tends to automount partitions
umount /media/usb*

mkfs.ext4 ${DEV}1 -L Boot 
mkfs.ext4 ${DEV}2 -L OLPCRoot 
mkfs.ntfs --fast --label library  ${DEV}3 

mount ${DEV}2 /mnt
mkdir -p /mnt/library
mkdir -p /mnt/bootpart
mount -t ntfs -o permissions ${DEV}3 /mnt/library
mount ${DEV}1 /mnt/bootpart

echo "writing tar file to SD card"
tar xzf $1 -C /mnt 

# make mounting the partitions automatic
sed -i -e 's|^/dev/mmcblk0p3.*$|/dev/mmcblk0p3 /library ntfs defaults,permissions 0 1|'  /mnt/etc/fstab
umount /mnt/library
umount /mnt/bootpart
umount /mnt
echo "new SD card copy completed"
