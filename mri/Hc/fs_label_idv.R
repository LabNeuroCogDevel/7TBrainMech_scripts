#!/usr/bin/env Rscript

# 20230201WF - init
#   count FS rois ratios in each placement
#   sum of ratios within a placment roi doesn't have to be 1.
#   some rois might be in areas not annotated by freesurfer
file_unrotated_coord <- "hc_loc_unrotated.1d" # 12x5 coordinate unrotated from gui placmenet
# used in system2/bash call
# file_placment_nii <- "./placements.nii.gz"
# file_aseg_scout <- "FS_warp/*_aseg_scout.nii.gz"


# setwd("/Volumes/Hera/Projects/7TBrainMech/scripts/mri/Hc/spectrum/20220707Luna1")
suppressPackageStartupMessages({library(dplyr);library(tidyr)});
lut <- read.table("/opt/ni_tools/freesurfer/ASegStatsLUT.txt",
                  col.names=c("FSroi","label", "r", "g", "b", "a")) %>%
    select(FSroi, label)

places <- read.table(file_unrotated_coord,
                     col.names=c("row", "col", "row_o", "col_o", "place"))

tot_vox <- 729 # 3dUndump ... -srad 4
nzcnt <- system2("/bin/bash",
                 stdout=T,
                 args=c("-c",
                        shQuote("3dROIstats -1DRformat -nomeanout -nzvoxels -mask FS_warp/*_aseg_scout.nii.gz ./placements.nii.gz'<'{1..12}'>'|sed 's/^.*<\\|>_.*?\\]//g;'")))


roi_long <- read.table(text=nzcnt,header=T) %>%
   rename(place=name) %>%
   gather("FSroi","rat",-place) %>%
   mutate(FSroi=gsub("NZcount_","",FSroi) %>% as.numeric) %>%
   filter(rat!=0)%>%
   mutate(rat=rat/tot_vox)

roi_long_unassigned <- rbind(roi_long,
                             roi_long %>% group_by(place) %>% summarise(FSroi=0, rat=1-sum(rat)))

FS_roi <- merge(roi_long_unassigned, lut, by="FSroi", all.x=T) %>%
    merge(places, all=T) %>%
   arrange(place)

write.csv(file="hc_aseg_roirat.csv", FS_roi, row.names=F, quote=F)

FS_roi %>% group_by(place) %>% filter(rat==max(rat)) %>%
    write.csv(file="hc_aseg_roirat_highest.csv", row.names=F, quote=F)
