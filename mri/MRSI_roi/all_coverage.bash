#!/usr/bin/env bash
# 20200619WF - quick ROI coverage re. BTC during MP journal club presentation
ls ../../../subjs/1*_2*/slice_PFC/MRSI_roi/13MP20200207/*/cmsphere-mni.nii.gz | perl -lne 'print "$& $_" if m/\d{5}_\d{8}/'|uniq -w14|cut -f2 -d' '|xargs 3dTcat -prefix all_13MP20200207.nii.gz
3dcalc -a all_13MP20200207.nii.gz -expr 'step(a)' -prefix /tmp/x.nii.gz
3dTstat -prefix all_13MP20200207_cnt.nii.gz -nzcount /tmp/x.nii.gz 
rm /tmp/x.nii.gz
