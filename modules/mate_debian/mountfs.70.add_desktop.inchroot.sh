#!/bin/bash -x
#

. $OOB__shlib

cat << EOF >> $intermediatesdir/do_in_chroot
# install a desktop environment
if [ -f /root/desktop ]; then
   desktop=\$(cat /root/desktop)
else
   desktop=
fi
if [ ! -z \$desktop ]; then
   apt-get install -y \$desktop iceweasel epiphany-browser
fi
EOF
