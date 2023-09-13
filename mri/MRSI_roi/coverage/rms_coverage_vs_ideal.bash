#!/usr/bin/env bash
# 20230913WF - looking at distance of centers of coveraged centered rois vs ideal
# all_13MP20200207_centered.nii.gz created by ../Makefile
#
cd ..
3dCM -all_rois ./all_13MP20200207_centered.nii.gz |&
 sed 1,2d|paste - -|sed 1d|
 paste - roi_locations/labels_13MP20200207.txt|
 sed 's/[^-.0-9 \t]//g;s/[ \t]\+/\t/g'  |
 /opt/ni_tools/lncdtools/r 'data.frame(r=d$V1,rms=sqrt(apply((d[,2:4] - d[,5:7])^2,1,sum)))'

