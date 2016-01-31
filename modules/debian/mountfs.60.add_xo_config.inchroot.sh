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
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
export LC_ALL=C LANGUAGE=C LANG=C

xo_type=\$(cat /root/xo_type)
# on a cross architecture install dpkg configure phase is delayed. do it now
if [ \$xo_type -eq 4 -o \$xo_type -eq 2 ];then
    /var/lib/dpkg/info/dash.preinst install
    dpkg --configure -a
fi

echo "write to /etc/fstab"
mkdir -p /etc
cat << _FSTAB > /etc/fstab
/dev/mmcblk1p1  /         ext4    defaults,noatime,errors=remount-ro  0 0
/swapfile none  swap    sw              0       0
devpts     /dev/pts  devpts  gid=5,mode=620   0 0
tmpfs      /dev/shm  tmpfs   defaults,size=50m         0 0
proc       /proc     proc    defaults         0 0
sysfs      /sys      sysfs   defaults         0 0
/tmp            /tmp            tmpfs         rw,size=50m 0 0
vartmp          /var/tmp        tmpfs         rw,size=50m 0 0
_FSTAB

cat << _FTH > /boot/olpc.fth
\ Debian Jessie for XO
visible
" last:\boot\initrd.img" to ramdisk
" last:\boot\vmlinuz" to boot-device
" console=tty0 fbcon=font:SUN12x22 root=/dev/mmcblk1p1 selinux=0" to boot-file
boot
_FTH

grep swappiness \$fsmount/etc/sysctl.conf
if [ \$? -ne 0 ]; then
   echo vm.swappiness=5 >> \$fsmount/etc/sysctl.conf
fi

if [ ! -f /swapfile ]; then
  dd if=/dev/zero of=/swapfile bs=1M count=512
  mkswap /swapfile
fi

xo_type=\$(cat /root/xo_type)
# set up a hostname
case \$xo_type in
0)
    HOSTNAME=debian_xo1
    ;;
1)
    HOSTNAME=debian_xo1.5
    ;;
2)
    HOSTNAME=debian_xo1.75
    ;;
4)
    HOSTNAME=debian_xo4
    ;;
esac


echo \$HOSTNAME > /etc/hostname
grep \$HOSTNAME /etc/hosts
if [ \$? -ne 0 ]; then
  sed -i -e "s/localhost/localhost \$HOSTNAME/" /etc/hosts
fi

# suppress starting daemons during chroot install
#cat << _SUPPRESS > \$fsmount/usr/sbin/policy-rc.d
#!/bin/bash
#exit 101
#_SUPPRESS
#chmod 755 /usr/sbin/policy-rc.d

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

# install the kernel
rpm2cpio kernel*.rpm |cpio -idv
sync
cd /boot
kernel=\$(cat /root/kernel_name)
kernel_id=\${kernel#"kernel-"}

case \$xo_type in
0 | 1 )
  kernel_nibble=\${kernel_id%".i686.rpm"}
  ;;
2 | 4)
  kernel_nibble=\${kernel_id%".armv7hl.rpm"}
  ;;
esac

echo "kernel_nibble is \$kernel_nibble"
mv initrd-\$kernel_nibble.img initrd.img-\$kernel_nibble
update-initramfs -t -c -u -k \$kernel_nibble
(cd /boot ; ln -fs initrd.img-\$kernel_nibble initrd.img)
(cd /boot ; ln -fs vmlinuz-\$kernel_nibble vmlinuz )
EOF
