#!/bin/bash -x
# This is the script that will be executed in the chroot

. $OOB__shlib

# the following snippet lets the script run by itself for debug
if [ -z $fsmount ]; then
    . /root/os-builder/build/intermediates/env
    . /root/os-builder/lib/shlib.sh
fi

# I've not discovered how to re-enter a chroot once I've return from one --so
#  we accumulate all the chroot tasks, and do them all at once
echo "writing debian instructions to $intermediatesdir/do_in_chroot"
cat << EOF > $intermediatesdir/do_in_chroot
# set up a hostname
HOSTNAME=debian_xo1
echo \$HOSTNAME > /etc/hostname
sed -i -e "s/localhost/localhost \$HOSTNAME/" /etc/hosts


# suppress starting daemons during chroot install
cat << _SUPPRESS > /usr/sbin/policy-rc.d
#!/bin/bash
exit 101
_SUPPRESS
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
if [ \$? -ne 0 ]; then
   echo vm.swappiness=5 >> /etc/sysctl.conf
fi

apt-get -y install sudo wget rpm2cpio cpio initramfs-tools locales wpasupplicant  olpc-kbdshim olpc-powerd olpc-xo1-hw openssl openssh-client lightdm wicd

# set root, and user passwords
hash=`openssl passwd olpc`
grep olpc /etc/passwd
if [ ! \$? -eq 0 ]; then
  useradd -m -p \$hash olpc
  chmod 600 /etc/sudoers
  echo "olpc   ALL=(ALL:ALL) ALL" >> /etc/sudoers
  chmod 400 /etc/sudoers
  usermod -p \$hash root
fi
cd /
rpm2cpio kernel*.rpm | cpio -idmv
sync
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
EOF
