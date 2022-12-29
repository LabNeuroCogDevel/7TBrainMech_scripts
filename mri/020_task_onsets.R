#!/usr/bin/env Rscript
setwd('/Volumes/Hera/Projects/7TBrainMech/scripts/mri')
#setwd('~/scratch/7tmgs/')
source("task_onset_funcs.R") # onset_recall, write_oned_by_fname, library(dplyr)

#####
# how to organize different 1d breakdowns
# will be grouped by fname, existing 'block' column will determine line number in 1D
#####
oned_base_dir <- function(onsetOnly) ifelse(onsetOnly, '1d_onsetOnly', '1d')
lr_img_1d <- function(oned_ready, epoch="cue", onsetOnly=F){
   oned_ready %>% mutate(
            prefix      = paste(sep="_", ld8, hasimg, coarse_side),
            fname       = sprintf("%s/trial_hasimg_lr/%s_%s.1d",
                                  oned_base_dir(onsetOnly), prefix, epoch))
}

lr_img_dur_1d <- function(oned_ready, epoch="cue", onsetOnly=F){
  oned_ready %>% mutate(
            prefix      = paste(sep="_", ld8, hasimg, coarse_side, dur),
            fname       = sprintf("%s/trial_duration_hasimg_lr/%s_%s.1d",
                                  oned_base_dir(onsetOnly), prefix, epoch))
}

trial_dur_1d <- function(oned_ready, epoch="cue", onsetOnly=F){
  oned_ready %>% mutate(
            prefix      = paste(sep="_", ld8, paste0("dly-",dur)),
            fname       = sprintf("%s/trial_duration/%s_%s.1d",
                                  oned_base_dir(onsetOnly), prefix, epoch))
}

single_1d <- function(oned_ready, epoch="cue", onsetOnly=F){
  oned_ready %>% mutate(
    fname       = sprintf("%s/trial_single/%s_%s.1d",
                          oned_base_dir(onsetOnly), ld8, epoch))
}
######



write_all_oned <- function(oned_read, REDO=FALSE) {
   ## WRITE 1D files
   # original left/right + img/noimage
   # if REDO, will rewrite 1d file. otherwise skip if already exists

   # with duration as "married" paramemter: "onset:duration"
   # output file used in 021a_deconvolve_block.bash like
   # -stim_times_AM1 5 "${oned_dir_bydur}/${ld8}_img_Left_dly.1d" 'dmBLOCK' -stim_label 5 dly_img_left \
   oned_ready %>% lr_img_1d(epoch='dly', onsetOnly=F) %>%
      write_oned_by_fname(redo=REDO, col_1d='dly', dur_col='dly_dur')

   # no duration parameter
   oned_ready %>% lr_img_1d(epoch='cue', onsetOnly=T) %>%
      write_oned_by_fname(redo=REDO, col_1d='cue', dur_col = NULL)
   oned_ready %>% lr_img_1d(epoch='dly', onsetOnly=T) %>%
      write_oned_by_fname(redo=REDO, col_1d='dly', dur_col = NULL)
   oned_ready %>% lr_img_1d(epoch='mgs', onsetOnly=T) %>%
      write_oned_by_fname(redo=REDO, col_1d='mgs', dur_col = NULL)

   # break out trails by duration of wait
   oned_ready %>% trial_dur_1d(epoch='cue', onsetOnly=T) %>%
      write_oned_by_fname(redo=REDO, col_1d='cue', dur_col = NULL)
   oned_ready %>% trial_dur_1d(epoch='dly', onsetOnly=T) %>%
      write_oned_by_fname(redo=REDO, col_1d='dly', dur_col = NULL)
   oned_ready %>% trial_dur_1d(epoch='mgs', onsetOnly=T) %>%
      write_oned_by_fname(redo=REDO, col_1d='mgs', dur_col = NULL)

   # duration and lr+img
   oned_ready %>% lr_img_dur_1d(epoch='cue', onsetOnly=T) %>%
      write_oned_by_fname(redo=REDO, col_1d='cue', dur_col = NULL)
   oned_ready %>% lr_img_dur_1d(epoch='dly', onsetOnly=T)  %>%
      write_oned_by_fname(redo=REDO, col_1d='dly', dur_col = NULL)
   oned_ready %>% lr_img_dur_1d(epoch='mgs', onsetOnly=T) %>%
      write_oned_by_fname(redo=REDO, col_1d='mgs', dur_col = NULL)

   # all together
   oned_ready %>% single_1d(epoch='dly', onsetOnly=T) %>%
      write_oned_by_fname(redo=REDO, col_1d='dly', dur_col = NULL)
}

if (sys.nframe() == 0){
   ld8 <- commandArgs(trailingOnly=TRUE)
   if(length(ld8)!=1L)
      stop("
USAGE: ./020_task_onsets.R {all|redo|read|<ld8>}
 'all' regerates recall+onset merge (txt/onset_and_recall_trialinfo.csv)
      and generates 1d files for all visits (skipping those already existing)
 'redo' like 'all' but will rewrite 1d files even if they exist.
      only needed if code generating file changes
 'read' uses prev view+recall merger file from 'all'.
      faster. approprate if no new visits but have new 1d files to generage.
 <ld8>=provide a lunaid_yyyymmdd
       useful for picking up new or renamed visit")

   REDO <- ld8 == 'redo'
   ## READ IN DATA (merging recall and "view" onsets)
   if(ld8 == "read") {
      oned_ready <-read.csv(file="txt/onset_and_recall_trialinfo.csv")
   } else if(ld8 %in% c('all','redo')) {
      oned_ready <- onset_recall()
      write.csv(file="txt/onset_and_recall_trialinfo.csv", oned_ready, row.names=FALSE)
   } else {
      oned_ready <- onset_recall(ld8)
   }
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

   write_all_oned(oned_read, REDO)
}
