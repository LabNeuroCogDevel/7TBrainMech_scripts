#!/usr/bin/env bash
# 20200619WF - quick ROI coverage re. BTC during MP journal club presentation
# 20210602WF - use coverage for ones that were 'picked'
picked="$(for f in /Volumes/Hera/Projects/7TBrainMech/subjs/1*_2*/slice_PFC/MRSI_roi/LCModel/v2idxfix/13MP20200207_picked_coords.txt; do
  ls $(dirname $(readlink -f $f))/cmsphere-mni.nii.gz
done)"
# TODO: remove subjs that are excluded

# combine them all as one nifti image (bucket 4d)
ls $picked | perl -lne 'print "$& $_" if m/\d{5}_\d{8}/'|uniq -w14|cut -f2 -d' '|xargs 3dTcat -overwrite -prefix all_13MP20200207.nii.gz

# remove ROI number so sum is count
3dcalc -overwrite -a all_13MP20200207.nii.gz -expr 'step(a)' -prefix /tmp/x.nii.gz
3dTstat -overwrite -prefix all_13MP20200207_cnt.nii.gz -nzcount /tmp/x.nii.gz 
rm /tmp/x.nii.gz

# make an ROI masked version for easy viewing
3dcalc -overwrite -r ./roi_locations/ROI_mni_13MP20200207.nii.gz -c all_13MP20200207_cnt.nii.gz -expr 'step(r)*c' -prefix  all_13MP20200207_cnt_masked.nii.gz

Rscript -e "library(dplyr);library(tidyr);library(reshape2);system('3dROIstats -minmax -sigma -mask roi_locations/ROI_mni_13MP20200207.nii.gz all_13MP20200207_cnt.nii.gz', intern=T) %>% read.table(text=.) %>% melt() %>% separate(variable, c('measure','roi'))  %>% select(-File,-Sub.brick) %>% spread(measure, value) %>% mutate(roi=as.numeric(roi)) %>% inner_join(read.table('roi_locations/labels_13MP20200207.txt',sep=':') %>% mutate(roi=1:n()) %>% select(label=V1, roi)) %>% arrange(roi) %>% print.data.frame(row.names=F)"
#Using File, Sub.brick as id variables
#Joining, by = "roi"
#   roi Max     Mean Min    Sigma              label
#1    1 115 67.34625  19 24.81079  R Anterior Insula
#2    2 109 69.19023  19 20.81192  L Anterior Insula
#3    3 114 73.85347  27 20.79528 R Posterior Insula
#4    4 120 72.28021  20 24.08855 L Posterior Insula
#5    5 127 83.24679  32 23.57891          R Caudate
#6    6 128 72.36504   5 34.36625          L Caudate
#7    7 125 80.44730  39 20.15672                ACC
#8    8 117 69.51157  19 22.84142               MPFC
#9    9  77 17.43445   0 19.32509            R DLPFC
#10  10  76 16.24679   1 18.72204            L DLPFC
#11  11  83 21.52185   1 18.12929              R STS
#12  12  88 19.84319   1 17.83828              L STS
#13  13 128 84.81748  25 24.48461         R Thalamus
#
