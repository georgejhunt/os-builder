#!/bin/bash -x
#
. $OOB__shlib
wifi_function=$(read_config debian wifi_function)

function report {
  echo "error on line number $LINENO"
}
trap report ERR

function fetch_file {
  url=$1
  k_basename=${url##*/}
  if [ ! -f $cachedir/kernels/$k_basename ]; then
     cd $cachedir/kernels
      wget $1
  fi
}

# for temporary debugging stand alone
fsmount=/root/os-builder/build/mnt-fs

# which kernel? based upon model and wifi
xo_type=$(read_laptop_model_number)
case $xo_type in
0)
    kernel_url=$(read_config debian kernel0)
  ;;
1)
  if [ "$wifi_function" = "client" ]; then
      kernel_url=$(read_config debian kernel1)
  else
      kernel_url=$(read_config debian kernel_ap)
  fi
  ;;
esac

# which firmware? based upon model and wifi
xo_type=$(read_laptop_model_number)
helper_url=
case $xo_type in
0)
    firmware_url=$(read_config debian firmware0)
  ;;
1)
  if [ $wifi_function = "client" ]; then
      firmware_url=$(read_config debian firmware1)
      helper_url=$(read_config debian firmware1_helper)

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
if [ ! -z $helper_url ];then
  fetch_file $helper_url
fi
# communicate to chroot by files in root
kernel=${kernel_url##*/}
echo $kernel > $fsmount/root/kernel_name 
cp -p $cachedir/kernels/$kernel $fsmount
firmware=${firmware_url##*/}
mkdir -p $fsmount/lib/firmware
cp -p $cachedir/kernels/$firmware $fsmount/lib/firmware
echo $firmware > $fsmount/root/firmware_name
if [ ! -z $helper_url ]; then
   helper=${firmware_url##*/}
   cp -p $cachedir/kernels/$helper $fsmount/lib/firmware
   echo $helper > $fsmount/root/helper_name
fi

