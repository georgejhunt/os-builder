#!/bin/bash -x
#
. $OOB__shlib

ap_function=$(read_config debian ap_function)

# for temporary debugging stand alone
fsmount=/root/os-builder/build/mnt-fs

function fetch_file {
  k_basename=${$1##*/}
  if [ ! -f $cachedir/kernels/$k_basename ]; then
     cd $cachedir/kernels
      wget $1
  fi
}

# which kernel? based upon model and wifi
xo_type=$(read_laptop_model_number)
case xo_type in
0)
  kernel_url=$(read_config debian kernel0)
  ;;
1)
  if [ $ap_function = "client" ]; then
    kernel_url=$(read_config debian kernel1)
  else
    kernel_url=$(read_config debian kernel_ap)
  fi
  ;;
esac

# which firmware? based upon model and wifi
xo_type=$(read_laptop_model_number)
helper_url=
case xo_type in
0)
  firmware_url=$(read_config debia_apn firmware0)
  ;;
1)
  if [ $ap_function = "client" ]; then
    firmware_url=$(read_config debian firmware1)
  else
    firmware_url=$(read_config debian firmware_tf)
    helper_url=$(read_config debian firmware_tf_helper)
  fi
  ;;
esac

# get the kernel if it is not already in the cache
mkdir -p $cachedir/kernels
fetch_file $kernel_url
fetch_file $firmware_url
fetch_file $helper_url

# communicate to chroot by files in root
kernel=${kernel_url##*/}
echo $kernel > $fsmount/root/kernel_name 
cp -p $cachedir/kernels/$kernel $fsmount
firmware=${firmware_url##*/}
cp -p $cachedir/kernels/$firmware $fsmount/lib/firmware
echo $firmware > $fsmount/root/firmware_name
if [ ! -z $helper_url ]; then
   helper=${firmware_url##*/}
   cp -p $cachedir/kernels/$helper $fsmount/lib/firmware
   echo $helper > $fsmount/root/helper_name
fi

desktop=$(read_config debian desktop)


echo $desktop > $fsmount/root/desktop 

 
echo "fsmount is $fsmount"
if [ -z $fsmount ]; then
   echo "fsmount is null. We MUST not  modify parent machine. Aborting . . ."
   exit 1
fi

# create the script that will be executed in the chroot

cat << EOF > $fsmount/root/preimage.sh
#!/bin/bash -x

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

if [ ! -f /swapfile ]; then
  dd if=/dev/zero of=/swapfile bs=1M count=512
  mkswap /swapfile
fi

#apt-get clean

grep swappiness /etc/sysctl.conf
if [ $? -ne 0 ]; then
   echo vm.swappiness=5 >> /etc/sysctl.conf
fi

apt-get -y install sudo wget rpm2cpio cpio initramfs-tools locales wpasupplicant  olpc-kbdshim olpc-powerd olpc-xo1-hw openssl

# set root, and user passwords
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
kernel=\$(cat /root/kernel_name)
kernel_id=\${kernel#"kernel-"}
kernel_nibble=\${kernel_id%".i686.rpm"}
echo "kernel_nibble is \$kernel_nibble"
mv initrd-\$kernel_nibble.img initrd.img-\$kernel_nibble
update-initramfs -t -c -u -k \$kernel_nibble
(cd /boot ; ln -fs initrd.img-\$kernel_nibble initrd.img)
(cd /boot ; ln -fs vmlinuz-\$kernel_nibble vmlinuz )

cat << _FTH > /boot/olpc.fth
\ Debian Jessie for XO
visible
" last:\boot\initrd.img" to ramdisk
" last:\boot\vmlinuz" to boot-device
" console=tty0 fbcon=font:SUN12x22 root=/dev/mmcblk0p2" to boot-file
boot
_FTH

cd /root

# install a desktop environment
if [ -f /root/desktop ]; then
   desktop=\$(cat /root/desktop)
else
   desktop=
fi
if [ ! -z $desktop ]; then
   apt-get install -y $desktop
fi

#rm $kernel
#rm /root/kernel_name
EOF
# and make it executable
chmod 755 $fsmount/root/preimage.sh

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

