#!/bin/bash -x
# get the debian rootfs into the cache

# the following sources os-builder-root/lib/shlib.sh (OOB__shlib is in env)
. $OOB__shlib

if [ -z $fsmount ]; then
    . /root/os-builder/build/intermediates/env
    . /root/os-builder/lib/shlib.sh
fi

debian_release=$(read_config debian debian_release)
mirror=$(read_config debian mirror)
xo_type=$(read_laptop_model_number)

# complain if build essentials are missing which -> more instructive messages
missing=
for x in debootstrap make gcc zip; do
   which $x >/dev/null || missing="$x, $missing"
   if [ $? -ne 0 ]; then
      echo -e "\nPlease install $x and run the script again"
      exit 1
   fi
done
if [ ! -z "$missing" ]; then
    missing=${missing:: -2}
    echo -e "\nMissing packages, please install $missing." >&2
    exit 1
fi

cat <<EOF >/tmp/ms.conf
[General]
unpack=true
bootstrap=Debian
aptsources=Debian

[Debian]
packages=ntpdate apt network-manager net-tools man-db less vim openssh-client
packages=openssh-server iputils-ping git rsync wget initramfs-tools olpc-kbdshim
packages=sudo wget rpm2cpio cpio initramfs-tools locales wpasupplicant 
packages=olpc-powerd openssl
source=$mirror
#source=http://ftp.us.debian.org/debian
keyring=debian-archive-keyring
suite=jessie
EOF

echo xo_type=$xo_type
case $xo_type in
0 | 1 )
    mkdir -p $cachedir/rootfs
    if [ ! -f $cachedir/rootfs/root/debian_cache ];then
      mkdir -p $cachedir/rootfs/root
      mkdir -p $cachedir/arm_rootfs/root
#      multistrap -a i386 -d $cachedir/rootfs -f /tmp/ms.conf
      debootstrap --arch i386 $debian_release $cachedir/rootfs $mirror 
      echo "This file may be deleted. It was used during automated build" > \
                    $cachedir/rootfs/root/debian_cache
    fi
    ;;
4 )
    mkdir -p $cachedir/arm_rootfs
    if [ ! -f $cachedir/arm_rootfs/root/debian_cache ];then
      mkdir -p $cachedir/arm_rootfs/root
      multistrap -a armhf -d $cachedir/arm_rootfs -f /tmp/ms.conf
      #debootstrap --arch armhf $debian_release $cachedir/arm_rootfs $mirror
      echo "This file may be deleted. It was used during automated build" > \
                    $cachedir/arm_rootfs/root/debian_cache
    fi
    ;;
esac
