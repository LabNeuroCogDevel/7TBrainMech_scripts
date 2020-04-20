#!/usr/bin/Rscript
library(dplyr)

setwd("/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI_roi/")
source('rest_fd.R')
# merge

# 20200311 - init
gr <- "/Volumes/Hera/Projects/7TBrainMech/subjs/1*_2*/slice_PFC/MRSI_roi/LCModel/v2idxfix"
xyroi <- Sys.glob(sprintf("%s/13MP20200207_picked_coords.txt", gr))
yxcsi <- Sys.glob(sprintf("%s/spectrum*.dir/*csv", gr))
gmcnt <- paste0(dirname(Sys.readlink(xyroi)), "/roi_percent_cnt_13MP20200207.txt")

L <- read.table("roi_locations/labels_13MP20200207.txt", sep=":") %>%
    mutate(roi=1:n()) %>%
    select(roi, label=V1)

G <- gmcnt[file.exists(gmcnt)] %>% lapply(read.table, as.is=T) %>% bind_rows
names(G) <- c("ld8", "gm.atlas", "roi", "GMrat", "GMcnt")

readcsi <- function(f) {
      d <- read.csv(f) %>% mutate(f=f)
      names(d) <-
          gsub("Cre", "Cr", names(d)) %>%
          gsub("\\.+", ".", .)
      return(d)
}
csi <-
   Filter(function(f) file.size(f) > 0, yxcsi) %>%
   lapply(readcsi) %>%
   bind_rows %>%
   mutate(ld8=LNCDR::ld8from(f),
          coord=stringr::str_extract(f, "(?<=spectrum.)\\d+.\\d+")) %>%
   tidyr::separate(coord, c("y", "x")) %>%
   # 20200414 - spectrum are oriented differently
   mutate(x=216+1-as.numeric(x), y=216+1-as.numeric(y)) %>%
   select(-f, -Row, -Col)

roi <- xyroi %>%
    lapply(function(f) read.table(f)[, 1:3] %>%
                       mutate(LNCDR::ld8from(f))) %>%
    bind_rows %>%
    `names<-`(c("roi", "x", "y", "ld8"))

d <-
    merge(roi, csi, by=c("ld8", "x", "y"), all=T) %>%
    merge(L, by="roi", all=T) %>%
    merge(G, by=c("ld8", "roi"), all=T) %>%
    merge(all7trestdf(), by=c"ld8", all.x=T)

## get age and sex from DB
query <-
   gsub("_.*", "", d$ld8) %>%
   gsub("^", "'", .) %>%           # add begin quote
   gsub("$", "'", .) %>%           # add ending quote
   paste(collapse=",") %>%         # put commas between
   sprintf("
          select id, sex, dob
          from person
          natural join enroll
          where id in (%s)", .)

r <- LNCDR::db_query(query)

da <-
   d %>% tidyr::separate(ld8, c("id", "vdate"), remove=F) %>%
   mutate(vdate=lubridate::ymd(vdate)) %>%
   merge(r, ., by="id", all=T) %>%
   mutate(age=round(as.numeric(vdate-dob)/365.25, 2)) %>%
   select(-id, -dob, -vdate)

write.csv(da, "txt/13MP20200207_LCMv2fixidx.csv", row.names=F)
