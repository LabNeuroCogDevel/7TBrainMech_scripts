#!/usr/bin/env Rscript

#   count FS rois ratios in each placement
#   sum of ratios within a placment roi doesn't have to be 1.
#   some rois might be in areas not annotated by freesurfer
# expects to run in spectrum/2*/FS_warp directory
#
# 20230201WF - init
# 20230224   - add GM, and redo
# 20230314   - each into function. take args. add stop
# 20250221   - add DW's matlab code
# 20250324DW   - adjusted for Freesurfer version 7.2

file_unrotated_coord <- "hc_loc_unrotated.1d" # 12x5 coordinate unrotated from gui placmenet
# used in system2/bash call
# file_placment_nii <- "./placements.nii.gz"
# file_aseg_scout <- "FS_warp/*_aseg72_scout.nii.gz"

REDO <- FALSE # TRUE if should rewrite output files
COORDFROM <- "matlab"

# setwd("/Volumes/Hera/Projects/7TBrainMech/scripts/mri/Hc/spectrum/20180216Luna2")
suppressPackageStartupMessages({library(dplyr);library(tidyr)});

#' lut_rat 
#' @param lut lookup table: roi number -> string label
#' @param scout FS aseg roi nifti
#' @param coordfrom 'julia' or 'matlab'
#'        original view_placements.jl=hc_loc_unrotated.1d, hc_loc_unrotated_matlab.m=coordintates.txt
lut_rat <- function(lut="/opt/ni_tools/freesurfer/ASegStatsLUT.txt",
                    scout="FS_warp/*_aseg72_scout.nii.gz",
                    coordfrom="julia",
                    saveas=NULL){

    # input files from matlab coordinates file (20250324 -DW)
    if(grepl("matlab", coordfrom)) {
      coords_txt <- "coordinates_m.txt"
      coord_nii <- "./placements_ml.nii.gz"
    } else if(grepl('julia', coordfrom)) {
      coords_txt <- file_unrotated_coord # "hc_loc_unrotated.1d"
      coord_nii <- "./placements_ml.nii.gz"
    } else {
       stop("unknown input type '", coordfrom,"' not matlab or julia")
    }
    print(paste0("from: ", coordfrom, " using: ", coords_txt, ", ", coord_nii))

    # skip if already have
    if(!is.null(saveas) && file.exists(saveas) && ! REDO){
       print(paste0("# have '", saveas, "' skipping"))
       return(read.csv(saveas))
    }

    if(length(Sys.glob(scout)) != 1L){
       stop("No scout: ",file.path(getwd(), scout))
    }
    # there are values for each rgba in aseg. will get a warning but dont care
    # but didnt' do the same for HBT subset. s
    if(class(lut) == "character")
       lut <- read.table(lut)[,1:2] %>% rename(FSroi=V1, label=V2)

    # needed for col_o and row_o which will be required to merge back to spectrum concentrations
    places <- read.table(coords_txt,
                        col.names=c("place", "row_o", "col_o", "row", "col"))

    tot_vox <- 729 # 3dUndump ... -srad 4

    # fancy bash + afni trick:
    # {1..12} makes 12 input arguments. I
    # <1> is masked only at nifti values == 1
    nzcnt <- system2("/bin/bash",
                    stdout=T,
                    args=c("-c", shQuote(paste0(
                    "3dROIstats -1DRformat -nomeanout -nzvoxels -mask ", scout,
                    " ",coord_nii,"'<'{1..12}'>'|sed 's/^.*<\\|>_.*?\\]//g;'"))))


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

   if(!is.null(saveas)) write.csv(FS_roi, file=saveas, row.names=F, quote=F)

   return(FS_roi)
}

##
outputname <- function(outname, coordfrom) {
   if(grepl('matlab', coordfrom)){
      outname <- gsub('.csv$','_ml.csv', outname)
   }
   print(paste0("# new name '", outname, "' b/c ", coordfrom))
   return(outname)
}
save_maxrat <- function(fname_long) {
  FS_roi <- read.csv(fname_long)
  fname_high <- gsub('.csv$','_highest.csv', fname_long)
  if(file.exists(fname_high) && !REDO){
     print(paste0("# already have '", fname_high, "'; skipping"))
     return(read.csv(fname_high))
  }

  maxrat <- FS_roi %>% group_by(place) %>% filter(rat==max(rat))
  write.csv(maxrat, file=fname_high, row.names=F, quote=F)
  return(maxrat)
}
###

aseg <- function(COORDFROM) {
   print(paste0("aseg:", COORDFROM))
  fname_long <- outputname("hc_FSaseg72_roirat.csv", COORDFROM)
  FS_roi <- lut_rat(coordfrom=COORDFROM, saveas=fname_long)
  ratmax <- save_maxrat(fname_long)
}
hbt <- function(COORDFROM){
  fname_long <- outputname("hc_HBT_roirat.csv", COORDFROM)
  HBT_roi <- lut_rat(lut="/Volumes/Hera/Projects/7TBrainMech/scripts/mri/Hc/txt/hc_fs_lut.txt",
                     scout="FS_warp/*_HBTlr500_scout.nii.gz",
                     coordfrom=COORDFROM,
                     saveas=fname_long)

  ratmax <- save_maxrat(fname_long)
}
gm <- function(COORDFROM){
  fname_long <- outputname("hc_FS72_gm_rat.csv", COORDFROM)
  gm_roi <- lut_rat(lut=data.frame(FSroi=c(0,1), label=c('not_gm','gm')),
                    scout="FS_warp/*_gm_scout.nii.gz",
                    # *matches lunaid date; FS7.2
                    coordfrom=COORDFROM, 
                    saveas=fname_long)
}

fs_all <- function(args) {
 if(any(grepl('matlab',args)))  COORDFROM <- 'matlab'
 if(any(grepl('hbt|all',args)))  hbt(COORDFROM)
 if(any(grepl('gm|all',args)))   gm(COORDFROM)
 if(any(grepl('aseg|all',args))) aseg(COORDFROM)
}

if (!interactive()) { fs_all(commandArgs(trailingOnly = FALSE)) }
