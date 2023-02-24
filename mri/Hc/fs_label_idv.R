#!/usr/bin/env Rscript

#   count FS rois ratios in each placement
#   sum of ratios within a placment roi doesn't have to be 1.
#   some rois might be in areas not annotated by freesurfer
# expects to run in spectrum/2*/FS_warp directory
#
# 20230201WF - init
# 20230224   - add GM, and redo

file_unrotated_coord <- "hc_loc_unrotated.1d" # 12x5 coordinate unrotated from gui placmenet
# used in system2/bash call
# file_placment_nii <- "./placements.nii.gz"
# file_aseg_scout <- "FS_warp/*_aseg_scout.nii.gz"

REDO <- FALSE # TRUE if should rewrite output files

# setwd("/Volumes/Hera/Projects/7TBrainMech/scripts/mri/Hc/spectrum/20180216Luna2")
suppressPackageStartupMessages({library(dplyr);library(tidyr)});

lut_rat <- function(lut="/opt/ni_tools/freesurfer/ASegStatsLUT.txt", scout="FS_warp/*_aseg_scout.nii.gz"){
    # there are values for each rgba in aseg. will get a warning but dont care
    # but didnt' do the same for HBT subset. s
    if(class(lut) == "character")
       lut <- read.table(lut)[,1:2] %>% rename(FSroi=V1, label=V2)

    # needed for col_o and row_o which will be required to merge back to spectrum concentrations
    places <- read.table(file_unrotated_coord,
                        col.names=c("row", "col", "row_o", "col_o", "place"))

    tot_vox <- 729 # 3dUndump ... -srad 4

    # fancy bash + afni trick:
    # {1..12} makes 12 input arguments. I
    # <1> is masked only at nifti values == 1
    nzcnt <- system2("/bin/bash",
                    stdout=T,
                    args=c("-c", shQuote(paste0(
                    "3dROIstats -1DRformat -nomeanout -nzvoxels -mask ", scout,
                    " ./placements.nii.gz'<'{1..12}'>'|sed 's/^.*<\\|>_.*?\\]//g;'"))))


    roi_long <- read.table(text=nzcnt, header=T) %>%
    rename(place=name) %>%
    gather("FSroi", "rat", -place) %>%
    mutate(FSroi=gsub("NZcount_", "", FSroi) %>% as.numeric) %>%
    filter(rat != 0) %>%
    mutate(rat=rat/tot_vox)

    roi_long_unassigned <- rbind(roi_long,
                                roi_long %>% group_by(place) %>% summarise(FSroi=0, rat=1-sum(rat)))

    FS_roi <- merge(roi_long_unassigned, lut, by="FSroi", all.x=T) %>%
        merge(places, all=T) %>%
    arrange(place)
}

if(!file.exists("hc_aseg_roirat_highest.csv") || REDO){
  FS_roi <- lut_rat()
  write.csv(file="hc_aseg_roirat.csv", FS_roi, row.names=F, quote=F)
  FS_roi %>% group_by(place) %>% filter(rat==max(rat)) %>%
      write.csv(file="hc_aseg_roirat_highest.csv", row.names=F, quote=F)
}

if(!file.exists("hc_HBT_roirat_highest.csv") || REDO){
   HBT_roi <- lut_rat(lut="/Volumes/Hera/Projects/7TBrainMech/scripts/mri/Hc/txt/hc_fs_lut.txt",
                     scout="FS_warp/*_HBTlr500_scout.nii.gz")
   write.csv(file="hc_HBT_roirat.csv", HBT_roi, row.names=F, quote=F)
   HBT_roi %>% group_by(place) %>% filter(rat==max(rat)) %>%
       write.csv(file="hc_HBT_roirat_highest.csv", row.names=F, quote=F)
}


if(!file.exists("hc_gm_rat.csv") || REDO){
   gm_roi <- lut_rat(lut=data.frame(FSroi=c(0,1), label=c('not_gm','gm')),
                     scout="FS_warp/*_gm_scout.nii.gz")
   write.csv(gm_roi,file="hc_gm_rat.csv", row.names=F, quote=F)
}
