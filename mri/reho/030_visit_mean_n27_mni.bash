#!/usr/bin/env bash
# 20230906DL - get non-zero mean of each file. save to txt file
# runs on only mni n27 files
# expect merge with txt/age_sex.tsv and subset in R
time {
   echo subj, overall_mean
   for f in images/1*_2*/reho-gmmask_epimasked_n27_space-mni.nii.gz; do 
      echo "$(ld8 "$f"),$(3dBrickStat -non-zero -mean "$f")"
   done
} > txt/overall_mean_n27_mni.csv
