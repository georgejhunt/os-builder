#!/bin/bash -x
# get the debian rootfs into the cache

# the following sources os-builder-root/lib/shlib.sh (OOB__shlib is in env)
. $OOB__shlib

for x in debootstrap chroot make gcc zip; do
   which $x >/dev/null
   if [ $? -ne 0 ]; then
      echo -e "\nPlease install $x and run the script again"
      exit 1
   fi
done

echo "fsmount is $fsmount"
if [ -z $fsmount ]; then
   echo "fsmount is null. We MUST not  modify parent machine. Aborting . . ."
   exit 1
fi

debian_release=$(read_config debian debian_release)
mkdir -p $cachedir/rootfs
if [ ! -f $cachedir/rootfs/root/debian_cache ];then
  mkdir -p $cachedir/rootfs
  debootstrap --arch i386 $debian_release $cachedir/rootfs ftp://ftp.us.debian.org/debian 
  echo "This file may be deleted. It was used during automated build" > \
		$cachedir/rootfs/root/debian_cache
fi

# now it's cached, make a fresh copy to modify
# rm -rf is really dangerous, particulary if $variable/* is used
if [ ! -z $fsmount ];then
   rm -rf $fsmount
fi
mkdir -p $fsmount
cp -ar $cachedir/rootfs/* $fsmount
