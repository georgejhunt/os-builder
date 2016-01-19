#!/bin/bash
# put the output in a place where it will not disappear with the next run
# Copyright (C) 2009 One Laptop Per Child
# Licensed under the terms of the GNU GPL v2 or later; see COPYING for details.

. $OOB__shlib

dest=$(read_config archive dest)
osname=$(image_name)
output_name=$osname.zd
diskimg=$intermediatesdir/$output_name.disk.img
output=$outputdir/$output_name

# move the output files 
mkdir -p $dest/$osname
cp -p $outputdir/* $dest/$osname 
