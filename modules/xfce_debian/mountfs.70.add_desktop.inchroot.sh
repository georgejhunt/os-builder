#!/bin/bash -x
#

. $OOB__shlib

echo "writing xfce instructions to $intermediatesdir/do_in_chroot"
cat << EOF >> $intermediatesdir/do_in_chroot
# install a desktop environment
if [ -f /root/desktop ]; then
   desktop=\$(cat /root/desktop)
else
   desktop=
fi
if [ ! -z \$desktop ]; then
   apt-get install -y \$desktop iceweasel epiphany-browser xfce-terminal
fi
EOF
