#!/usr/bin/env Rscript

# 20190509 WF - merge fs frac GM into subj x roi csi value

dversion=20190503
# read in output of ./041_merge_pos_val.R
subj_val_pos_label <-read.csv(sprintf("txt/subj_label_val_%s.csv", dversion))

# read in output of ./051_GM_Count.bash
GM <- read.table(pipe('cat /Volumes/Hera/Projects/7TBrainMech/subjs/*/slice_PFC/MRSI_roi/spectrum/roi_percent_cnt.txt'))
names(GM) <- c("ld8", "ver", "roi_num", "FSfracGM", "nvoxel")

# combine together
subj_val_pos_label_gm <- merge(subj_val_pos_label, GM, by=c("ld8", "roi_num"))
write.csv(subj_val_pos_label_gm, sprintf("txt/subj_label_val_gm_%s.csv", dversion))
