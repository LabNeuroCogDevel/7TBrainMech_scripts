#!/usr/bin/env Rscript

# write txt/hc_missing.txt
# mrid (YYYYMMDDLunaX) in scanlog (DB) but haven't found raw data
#
# 20221201WF - init


library(dplyr)
# 'txt/hc_missing.txt'
scanned <- read.table('txt/hc_scanlog.txt',sep="\t", col.names=c("ld8","mrid","acqnum"))
have_csv <- read.csv('txt/all_hc.csv') %>% select(mrid) %>% unique
have_spec <- data.frame(mrid=system(intern=T,"ls spectrum/|grep -Po '[0-9]{8}Luna[0-9]*'|sort -u"))
have_any <- c(have_csv$mrid, have_spec$mrid) %>% unique
want <- setdiff(scanned$mrid, have_any)
cat("# have ",nrow(scanned), "scanned.",nrow(have_csv),"already procced and",
    nrow(have_spec),"spectrums (",length(have_any), "total unique)",
    "want ", length(want), "still\n")
write.table(data.frame(mrid=want),'txt/hc_missing.txt',quote=F,row.names=F)
