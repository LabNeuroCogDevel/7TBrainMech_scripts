#!/usr/bin/env Rscript
# combine all Hc spreadsheets
# 20200520WF - init
library(stringr)
library(dplyr)

f_list <- Sys.glob('/Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/HPC/ProcessedHc*/20*/spectrum*/spreadsheet.csv')
d <- lapply(f_list, function(f) tryCatch(
             {read.csv(f) %>%
                 mutate(roi =str_extract(f, '(?<=spectrum.)([0-9LR.]+)(?=.dir)'),
                        mrid=str_extract(f, '(?<=/)\\d{8}L[^/]+'))},
             error=function(e){ cat(f, " is empty?!\n"); return(NULL)}
             )) %>% bind_rows

d <- d %>% tidyr::separate(roi, c('Row', 'Col', 'Side', 'roinum')) 

ids <- read.table('../MRSI/txt/ids.txt')
names(ids) <- c('ld8','mrid')
d_id <- merge(d, ids, all.x=T)

write.csv(d_id, "txt/all_hc.csv", row.names=F, quote=F)
