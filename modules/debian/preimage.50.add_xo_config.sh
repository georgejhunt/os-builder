#!/bin/bash -x
#
. $OOB__shlib
kernel_url=$(read_config debian kernel_url)
kernel=$(read_config debian kernel)
echo "fsmount is $fsmount"
fsmount=/root/os-builder/build/mnt_fs
if [ -z $fsmount ]; then
   echo "fsmount is null. We MUST not  modify parent machine. Aborting . . ."
   exit 1
fi
echo "fsmount is $fsmount"

mkdir -p $fsmount/dev
#mount -o bind /dev $fsmount/dev
mkdir -p $fsmount/proc
#mount -o bind /proc $fsmount/proc
mkdir -p $fsmount/sys
#mount -o bind /sys $fsmount/sys
mkdir -p $fsmount/tmp
#mount -o bind /tmp $fsmount/tmp
cp -f /etc/resolv.conf $fsmount/etc/resolv.conf

# set up a hostname
HOSTNAME=debian_xo1
echo $HOSTNAME > $fsmount/etc/hostname
sed -i -e "s/localhost/localhost $HOSTNAME/" $fsmount/etc/hosts

echo "Installing modules in chroot"

# suppress starting daemons during chroot install
cat << EOF > $fsmount/usr/sbin/policy-rc.d
#!/bin/bash
exit 101
EOF
chmod 755 $fsmount/usr/sbin/policy-rc.d

chroot $fsmount  apt-get -y install locales wpasupplicant rpm2cpio wget  olpc-kbdshim olpc-powerd olpc-xo1-hw initramfs-tools sudo

echo set root, and user passwords

hash=`openssl passwd olpc`
grep olpc $fsmount/etc/passwd
if [ ! $? -eq 0 ]; then
  chroot $fsmount useradd -m -p $hash olpc
  chmod 600 $fsmount/etc/sudoers
  echo "olpc   ALL=(ALL:ALL) ALL" >> $fsmount/etc/sudoers
  chmod 400 $fsmount/etc/sudoers
fi

echo write to /etc/fstab
cat << EOF > $fsmount/etc/fstab
/dev/mmcblk0p1  /         ext4    defaults,noatime,errors=remount-ro  0 0
/swapfile none  swap    sw              0       0
devpts     /dev/pts  devpts  gid=5,mode=620   0 0
tmpfs      /dev/shm  tmpfs   defaults,size=50m         0 0
proc       /proc     proc    defaults         0 0
sysfs      /sys      sysfs   defaults         0 0
/tmp            /tmp            tmpfs         rw,size=50m 0 0
vartmp          /var/tmp        tmpfs         rw,size=50m 0 0
varlog          /var/log        tmpfs         rw,size=20m 0 0
EOF

echo wifi firmware
ls $fsmount/lib/firmware/libertas|grep usb8388
if [ ! $? -eq 0 ]; then
   mkdir -p $fsmount/lib/firmware/libertas
  cd $fsmount/lib/firmware/libertas
  wget -O usb8388.bin http://dev.laptop.org/pub/firmware/libertas/usb8388-5.110.22.p23.bin
fi

ls $fsmount/swapfile|grep swapfile
if [ ! $? -eq 0 ]; then
	echo create swap
	dd if=/dev/zero of=$fsmount/swapfile bs=1M count=512
	chroot $fsmount mkswap /swapfile
fi

#chroot $fsmount "apt-get clean"

grep swappiness $fsmount/etc/sysctl.conf
if [ $? -ne 0 ]; then
   echo vm.swappiness=5 >> $fsmount/etc/sysctl.conf
fi

if [ -z $kernel -o -z $kernel_url ]; then
   echo "empty variables kernel ($kernel) or kernel_url($kernel_url)"
   exit 1
fi
echo "Go fetch the OLPC kernel"

if [ ! -f $cachedir/kernels/$kernel ]; then
   mkdir -p $cachedir/kernels
   cd $cachedir/kernels
   wget $kernel_url/$kernel
fi
cd $fsmount
cp $cachedir/kernels/$kernel .
rpm2cpio kernel*.rpm | cpio -idmv
cd $fsmount/boot
kernel_id=${kernel#"kernel-"}
kernel_nibble=${kernel_id%".i686.rpm"}
echo "kernel_nibble is $kernel_nibble"
mv initrd-$kernel_nibble.img initrd.img-$kernel_nibble
update-initramfs -t -c -u -k $kernel_nibble
(cd /boot ; ln -fs initrd.img-$kernel_nibble initrd.img)
(cd /boot ; ln -fs vmlinuz-$kernel_nibble vmlinuz )
cd $fsmount
rm $kernel
