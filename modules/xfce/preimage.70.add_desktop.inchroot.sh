#!/bin/bash -x
#
cd /root

# install a desktop environment
if [ -f /root/desktop ]; then
   desktop=$(cat /root/desktop)
else
   desktop=
fi
if [ ! -z $desktop ]; then
   apt-get install -y $desktop iceweasel epiphany-browser
fi