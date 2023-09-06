#!/usr/bin/env bash
# 20230830WF - get non-zero mean of each file. save to txt file
# runs on all files (mni and native;n7 to n27). 
# expect merge with txt/age_sex.tsv and subset in R
time {
   echo subj,file,overall_mean
   for f in images/1*_2*/reho-gmmask_epimasked_*; do
      echo "$(ld8 "$f"),$(basename "$f" .nii.gz),$(3dBrickStat -non-zero -mean "$f")"
   done
} > txt/overall_mean.csv
