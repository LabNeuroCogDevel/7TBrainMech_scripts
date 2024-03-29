#!/usr/bin/env Rscript
# combine all Hc spreadsheets
# 20200520WF - init
# 20220303WF - include VY's 2018-2019 
library(stringr)
library(dplyr)
library(tidyr)
extract_7tmrid <-function(f){
   mrid <- str_extract(f, '(?<=/)\\d{8}L[UNAuna]+[1-3]?') # dont want Luna1a or Luna1A
   mrid <- ifelse(!is.na(mrid), mrid, gsub('.*Processed103019/Luna(\\d{4})([12]).*','2019\\1Luna\\2', f))
   # LUNA to Luna
   mrid <- tolower(mrid) %>% gsub('l','L',.)
   return(mrid)
}
# extract_7tmrid("/ProcessedHc_20200520_2019-Mar2020/20191101Luna2/spectrum")
# extract_7tmrid("HPC/Processed103019/Luna07221/spe"
# extract_7tmrid("/20190405Luna1A/")
# extract_7tmrid("/20190429Luna/")

extract_set <- function(f) gsub('.*MRSI_BrainMechR01/HPC/','',f) %>% gsub('/Luna[02].*|/20.*|/spectrum.*','',.)

read_mrsisheet <- function(f)
   tryCatch(
    read.csv(f) %>%
      mutate(roi =str_extract(f, '(?<=spectrum.)([0-9LR.]+)(?=.dir)'),
             mrid=extract_7tmrid(f),
             dname=basename(dirname(f)),
             #set=str_extract(f,'Processed[^/]*') %>% gsub('Processed(Hc)?_?','',.),
             set=extract_set(f),
             # if we weren't able to extract roi then we'll have to derive it from Row/Col
             # annotate that incase we do the derivation wrong
             # as of 20220304 there are  191 files that don't match the roi filename pattern
             #                      and 1557 that do
             roinumberfrom=ifelse(is.na(roi),"derived","filename")) %>%
      rename_with(function(.) str_replace_all(., 'Cr$', 'Cre')),
    error=function(e) {cat(f,"error reading:", e$message, "\n"); NULL})



# get old. ~15 are missing [LR.1-6]. one set has different 7TID format
YV_list <- system(intern=T,'find /Volumes/Hera/Projects/7TBrainMech/raw/MRSI_BrainMechR01/HPC/ -name spreadsheet.csv')
d_YV <- lapply(YV_list, read_mrsisheet) %>% bind_rows()
d_YV_okay <- d_YV %>% filter(grepl('L|R',roi)) %>% separate(roi, c('Row', 'Col', 'Side', 'roinum')) 
d_reconstruct_side <- d_YV %>%
   filter(!grepl('L|R',roi)) %>%
   separate(roi,c('Row','Col')) %>%
   mutate_at(vars(Row,Col), as.numeric) %>%
   mutate(Side=ifelse(Col>90,"R","L")) %>%
   group_by(mrid,Side) %>%
   mutate(roinum=rank(Row))
d_YV_fixed <- rbind(d_YV_okay, d_reconstruct_side) %>% select(-dname) %>% mutate(placed='MRRC')


# lncd placed ROIs
# remote LCModel
#lncd_list <- Sys.glob('/Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/HPC/*/20*/spectrum*/spreadsheet.csv')
# local LCModel
lncd_list <- Sys.glob('/Volumes/Hera/Projects/7TBrainMech/scripts/mri/Hc/spectrum/20*/spectrum*.dir/spreadsheet.csv')
d_lncd_l <- lapply(lncd_list, read_mrsisheet) %>% bind_rows %>% select(-dname)
d_lncd <- d_lncd_l %>% separate(roi, c('Row', 'Col')) %>% mutate(placed='LNCD', set='ZLNCD')

# 20230323 - left/right and roi num in locations.txt
lncd_loc_list <- Sys.glob('/Volumes/Hera/Projects/7TBrainMech/scripts/mri/Hc/spectrum/20*/locations.txt')
read_loc <- function(f)
    read.table(f, col.names=c("Side","roinum","Row","Col")) %>%
        mutate(Side=substr(Side,1,1), mrid=basename(dirname(f)))
lncd_loc_df <- lapply(lncd_loc_list, read_loc) %>% bind_rows
# location.txt doesn't exist for 24/164. 
# when it does exist, use that to exclude old/extra spectrum.xx.yy placements
# (mutliple runs of ml placment gui)
d_lncd_rowcol <- merge(d_lncd %>% filter( !(Row==218&Col==218)) , lncd_loc_df, by=c("mrid","Row","Col"), all.x=TRUE, all.y=FALSE) %>%
    group_by(mrid) %>% mutate(nmatch=length(which(!is.na(roinum)))) %>% 
    filter(nmatch==0|!is.na(roinum)) %>% select(-nmatch) %>% ungroup

d <- rbind(d_YV_fixed, d_lncd_rowcol)
ids <- read.table('../MRSI/txt/ids.txt') %>%
`names<-`(c('ld8','mrid')) %>%
 mutate(mrid=gsub("LUNA","Luna",mrid) %>%
             gsub("_1$","",.) %>%
             gsub("20190722Luna","20190722Luna1",.)) %>%
    filter(!ld8 %in% c('11390_20180628' # 11665_20180628
                       ))
d_id <- merge(d, ids, all.x=T) %>% unique

# remove duplicates for 20190729Luna1 and 20190830Luna1
# still have dups of 20190405Luna1 in 20200520_2019-Mar2020
# (NB. fixed_ln set no longer exists?)
d_newest_set <- d_id %>% group_by(ld8,mrid) %>%
    mutate(r=rank(set)) %>%
    filter(set!='103019_fixed_ln') %>% filter(r==max(r)) %>%
    select(-r)

# 20230323 calc side and roinum for LNCD placements
d_calcside <-
   d_newest_set %>%
   ungroup() %>%
   group_by(ld8, mrid,set,placed) %>%
   mutate(across(c('Col','Row'),as.numeric),
          side_calc=ifelse(Col>mean(Col,na.rm=TRUE),'R','L')) %>% 
   group_by(ld8, mrid, placed, set, side_calc) %>%
   mutate(roinum_calc=rank(Row)) %>% ungroup

write.csv(d_calcside, "txt/all_hc.csv", row.names=F, quote=F)
