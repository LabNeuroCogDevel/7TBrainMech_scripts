#!/usr/bin/env Rscript

# write txt/hc_missing.txt
# mrid (YYYYMMDDLunaX) in scanlog (DB) but haven't found raw data
#
# 20221201WF - init


library(dplyr)
library(magrittr)
# 'txt/hc_missing.txt'
scanned <- read.table("txt/hc_scanlog.txt",
                      sep="\t", col.names=c("ld8", "mrid", "acqnum")) %>%
   mutate(mrid = stringr::str_extract(mrid, "\\d{8}L[uU][Nn][Aa][0-9]*"))
have_csv <- read.csv("txt/all_hc.csv") %>% select(mrid) %>% unique
have_spec <- data.frame(mrid=system(intern=T,
                                    "ls spectrum/|grep -Pio '[0-9]{8}L[Uu][Nn][aA][0-9]*'|sort -u"))
have_any <- c(have_csv$mrid, have_spec$mrid) %>% unique
want <- setdiff(scanned$mrid, have_any)
cat("# have ",nrow(scanned), "scanned.",nrow(have_csv),"already procced and",
    nrow(have_spec),"spectrums (",length(have_any), "total unique)",
    "want ", length(want), "still\n")
#write.table(data.frame(mrid=want),'txt/hc_missing.txt',quote=F,row.names=F)
alt_lookup <- function(ld8) {
    res <- system(intern=T,
           paste0("find  /Volumes/Hera/Raw/BIDS/7TBrainMech/rawlinks/", ld8,
                  " -type l -exec readlink -f {} '+'  -quit|grep -Pio '\\d{8}Luna\\d?'|sed 1q"))
    if(length(res)==0) return(NA)
    return(as.character(res))
}

missing_df <- scanned %>% filter(mrid%in%want) %>% distinct
mia_idx <- is.na(missing_df$mrid)
newid <- unname(with(missing_df, Vectorize(alt_lookup)(ld8[mia_idx])))
missing_df$mrid[mia_idx] <- newid

# bad merge somewhere. mrid's without days visit (1 or 2) at the end are included
# but shouldn't be
luna_no_num <- c("20180510Luna", "20180511Luna", "20180524Luna", "20190722Luna")
# 11734_20220610 exists!?
write.table(missing_df %>% filter(! ld8 %in% c('11734_20220610'), ! mrid %in% luna_no_num),
            "txt/hc_missing.txt", quote=F, row.names=F)
