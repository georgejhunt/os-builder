# Copyright (C) 2009 One Laptop per Child
# Licensed under the terms of the GNU GPL v2 or later; see COPYING for details.

. $OOB__shlib
make_zd=$(read_config sd_card_image make_zd)

if [[ "$make_zd" == 1 ]]; then
    if [[ ! -e $bindir/zhashfs ]]; then
        (cd $bindir && make) >&2 || exit 9
    fi
fi
