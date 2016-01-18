#!/bin/bash -x
#
. $OOB__shlib

# for temporary debugging stand alone
fsmount=/root/os-builder/build/mnt-fs

kernel_url=$(read_config debian kernel$(read_laptop_model_number))
kernel=${kernel_url##*/}
echo "kernel_url ($kernel_url) kernel is $kernel"
if [ -z $kernel -o -z $kernel_url ]; then
   echo "empty variables kernel ($kernel) or kernel_url($kernel_url)"
   exit 1
fi

echo "Go fetch the OLPC kernel"
if [ ! -f $cachedir/kernels/$kernel ]; then
   mkdir -p $cachedir/kernels
   cd $cachedir/kernels
   wget $kernel_url
fi
cp -p $cachedir/kernels/$kernel $fsmount
echo $kernel > $fsmount/root/kernel_name 

 
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
cp $cachedir/kernels/$kernel $fsmount
cp -f /etc/resolv.conf $fsmount/etc/resolv.conf

echo "fsmount is $fsmount"
if [ -z $fsmount ]; then
   echo "fsmount is null. We MUST not  modify parent machine. Aborting . . ."
   exit 1
fi

# create the script that will be executed in the chroot

cat << EOF > $fsmount/root/preimage.sh
#!/bin/bash -x

# trap errors and report their line number
function _debug{
  echo error trapped at line number $LINENO
}
trap _debug ERR
trap - EXIT

# set up a hostname
HOSTNAME=debian_xo1
echo $HOSTNAME > /etc/hostname
sed -i -e "s/localhost/localhost $HOSTNAME/" /etc/hosts


# suppress starting daemons during chroot install
cat << SUPPRESS > /usr/sbin/policy-rc.d
#!/bin/bash
exit 101
SUPPRESS
chmod 755 /usr/sbin/policy-rc.d

echo "write to /etc/fstab"
cat << _FSTAB > /etc/fstab
/dev/mmcblk0p1  /         ext4    defaults,noatime,errors=remount-ro  0 0
/swapfile none  swap    sw              0       0
devpts     /dev/pts  devpts  gid=5,mode=620   0 0
tmpfs      /dev/shm  tmpfs   defaults,size=50m         0 0
proc       /proc     proc    defaults         0 0
sysfs      /sys      sysfs   defaults         0 0
/tmp            /tmp            tmpfs         rw,size=50m 0 0
vartmp          /var/tmp        tmpfs         rw,size=50m 0 0
varlog          /var/log        tmpfs         rw,size=20m 0 0
_FSTAB

# get wifi firmware
mkdir -p /lib/firmware/libertas
ls /lib/firmware/libertas|grep usb8388
if [ ! -f /lib/firmware/libertas/usb8388.bin ]; then
  cd /lib/firmware/libertas
  wget -O usb8388.bin http://dev.laptop.org/pub/firmware/libertas/usb8388-5.110.22.p23.bin
fi

if [ ! -f /swapfile ]; then
  dd if=/dev/zero of=/swapfile bs=1M count=512
  mkswap /swapfile
fi

apt-get clean

grep swappiness /etc/sysctl.conf
if [ $? -ne 0 ]; then
   echo vm.swappiness=5 >> /etc/sysctl.conf
fi

apt-get -y install sudo wget rpm2cpio cpio initramfs-tools locales wpasupplicant  olpc-kbdshim olpc-powerd olpc-xo1-hw openssl

echo set root, and user passwords
hash=`openssl passwd olpc`
grep olpc /etc/passwd
if [ ! $? -eq 0 ]; then
  useradd -m -p $hash olpc
  chmod 600 /etc/sudoers
  echo "olpc   ALL=(ALL:ALL) ALL" >> /etc/sudoers
  chmod 400 /etc/sudoers
fi

cd /
rpm2cpio kernel*.rpm | cpio -idmv
cd /boot
kernel=`cat /root/kernel_name`
kernel_id=${kernel#"kernel-"}
kernel_nibble=${kernel_id%".i686.rpm"}
echo "kernel_nibble is $kernel_nibble"
mv initrd-$kernel_nibble.img initrd.img-$kernel_nibble
update-initramfs -t -c -u -k $kernel_nibble
(cd /boot ; ln -fs initrd.img-$kernel_nibble initrd.img)
(cd /boot ; ln -fs vmlinuz-$kernel_nibble vmlinuz )

cd / 
rm $kernel
rm /root/kernel_name
EOF

# now execute the script 
chroot $fsmount /root/preimage.sh
