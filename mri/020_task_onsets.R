#!/usr/bin/env Rscript
library(dplyr)
setwd('/Volumes/Hera/Projects/7TBrainMech/scripts/mri/')
source("task_onset_funcs.R") # onset_recall, write_oned_by_fname

REDO <- FALSE  # rewrite 1d files if they already exist?

#####
# how to organize different 1d breakdowns
# will be grouped by fname, existing 'block' column will determine line number in 1D
#####
lr_img_1d <- function(oned_ready){
   OUTDIR <- "1d/trial_hasimg_lr/"
   oned_ready %>% mutate(
            prefix      = paste(sep="_", ld8, hasimg, coarse_side),
            fname       = sprintf("%s/%s.1d", OUTDIR, prefix))
}

lr_img_dur_1d <- function(oned_ready){
   oned_ready %>% mutate(
            prefix      = paste(sep="_", ld8, hasimg, coarse_side, dur),
            fname       = sprintf("1d/trial_duration_hasimg_lr/%s.1d", prefix))
}

trial_dur_1d <- function(oned_ready){
   oned_ready %>% mutate(
            prefix      = paste(sep="_", ld8, paste0("dly-",dur)),
            fname       = sprintf("1d/trial_duration/%s.1d", prefix))
}
######


## READ IN DATA (merging recall and "view" onsets)
oned_ready <- onset_recall()
write.csv(file="txt/onset_and_recall_trialinfo.csv", oned_ready, row.names=FALSE)
# or read in instead of regenerating
# oned_ready <- read.csv("txt/onset_and_recall_trialinfo.csv")

# 20221213: 248 visits with 17880 trials
#  wc -l < txt/onset_and_recall_trialinfo.csv 
#    17881 
#  grep -oP '\d{5}_\d{8}' txt/onset_and_recall_trialinfo.csv |sort -u | wc -l
#    248

# debug missing subj
# oned_single <- onset_recall("11735_20190719") # no recall
# oned_single <- onset_recall("11802_20210618") # good trial


## WRITE 1D files
# original left/right + img/noimage
oned_ready %>% lr_img_1d %>% write_oned_by_fname(redo=REDO)

# break out trails by duration of wait
oned_ready %>% trial_dur_1d %>% write_oned_by_fname(redo=REDO)

# duration and lr+img
oned_ready %>% lr_img_dur_1d  %>% write_oned_by_fname(redo=REDO)

