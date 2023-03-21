#!/usr/bin/env Rscript
library(dplyr)

# collapse all lcmodel outputs for putamen
#
# 20230320WF - init
# 20230320WF - copy swapcoord and colrename from 050_merge.R
swapcoord <- function(x) 216+1-as.numeric(x)
read_lcmodel <- function(f){
 # which roi was placed first should always be left/right.
 # but if merge at end is NA. likely dont want that spectrum
 # /Volumes/Hera/Projects/7TBrainMech/subjs/11875_20220630/slice_PFC/MRSI_roi/putamen2/VL/sid3_picked_coords.txt
 d.order <- read.table(file.path(dirname(dirname(f)),"sid3_picked_coords.txt"),
                       col.names=c("Row","Col")) %>%
    mutate(roinum=1:n())

 d <- read.csv(f)
 names(d) <-
    gsub("Cre", "Cr", names(d)) %>%
    gsub("\\.+", ".", .)

 d$ld8 <- LNCDR::ld8from(f)
 d$coords <- stringr::str_extract(f, "(?<=spectrum.)\\d+.\\d+")

 d %>% tidyr::separate(coords, c("y", "x")) %>%
    mutate(Row=y, Col=x, x=swapcoord(x),y=swapcoord(y)) %>%
    merge(d.order,all.x=T)
}

sheets <- Sys.glob("/Volumes/Hera/Projects/7TBrainMech/subjs/1*_2*/slice_PFC/MRSI_roi/putamen2/*/spectrum.*dir/spreadsheet.csv")
lcmodel <- bind_rows(lapply(sheets, read_lcmodel))
gm <- read.table('txt/putamen_gm.csv', col.names=c("ld8","atlas","roinum","gmrat","gmvxcnt"))

lcmodel %>%
   merge(gm, all=T, by=c("ld8","roinum")) %>%
   write.csv(file="txt/putamen_lcmodel.csv", row.names=F, quote=F)
