# Copyright (C) 2009 One Laptop Per Child
# Licensed under the terms of the GNU GPL v2 or later; see COPYING for details.

. $OOB__shlib

path=$(read_config olpc_image path)
osname=$(image_name)
output_name=$osname.zd
diskimg=$intermediatesdir/$output_name.disk.img
output=$outputdir/$output_name

echo "copying image to intermediate dir $diskimg"
dd if=$path of=$diskimg bs=4M
	
echo "Making ZD image for $output_name..."
$bindir/zhashfs 0x20000 sha256 $diskimg $output.zsp $output

echo "Creating MD5sum of $output_name..."
pushd $outputdir >/dev/null
md5sum $output_name > $output_name.md5
popd >/dev/null

mv $diskimg $outputdir
