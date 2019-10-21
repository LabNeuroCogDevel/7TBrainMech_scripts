#!/usr/bin/env Rscript

#
# update google sheet with what we've done
#

# devtools::install_github("tidyverse/googlesheets4")
# install.packages('googledrive')
library("googlesheets4")
library("googledrive")
library(dplyr)

ctime <- function(x) ifelse(file.exists(x), as.character(file.info(x)$ctime), NA)
nfiles <- function(x) sapply(x, function(g) length(Sys.glob(g)))

r <- sheets_get("1uFe21U43SX8ayFf8V0zEEmDQScfrZXLDfkTZNBzZhm0")
d <- googlesheets4::read_sheet(r$spreadsheet_id)
d.db <- LNCDR::db_query("select id as LunaID, to_char(vtimestamp,'YYYYmmdd') as ymd from visit natural join visit_study natural join enroll where study like 'Brain%' and etype like 'LunaID' and vtype like 'Scan' order by vtimestamp desc") %>% rename(LunaID=lunaid)
# provides MRID

inputdirs <-
   read.table("inputdirs.txt") %>% `names<-`(c("MRID", "lunadate", "bids")) %>%
   mutate( MRID=gsub(".*/7TBrainMech/", "", MRID) %>% gsub("/.*", "", .),
           LunaID=gsub("_.*", "", lunadate ) ) %>%
   select(MRID, LunaID)

d <- merge(d,inputdirs,by=c("MRID", "LunaID"),all=T)
d$ymd <- substr(d$MRID, 0, 8)
d <- merge(d, d.db, by=c("LunaID", "ymd"), all=T)
d$have_raw <- ctime(file.path("/Volumes/Hera/Raw/MRprojects/7TBrainMech/", d$MRID))
d$made_folder <- ctime(file.path("/Volumes/Hera/Projects/7TBrainMech/raw/", d$MRID))
d$made_bids <- ctime(paste0("/Volumes/Hera/Projects/7TBrainMech/BIDS/sub-", d$LunaID))
d$n_bids_nii <- nfiles(sprintf("/Volumes/Hera/Projects/7TBrainMech/BIDS/sub-%s/%s/*/*.nii.gz", d$LunaID,d$ymd))
d$final_rest_preproc <- ctime(sprintf("/Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_ica/%s_%s/brnaswdkm_func_4.nii.gz", d$LunaID, d$ymd ))
d <- d %>% arrange(-as.numeric(ymd))
# reupload -- clears any google sheet specificness (e.g. limited number of row, or columns, datavalidations)
write.csv(d, "status.csv", row.names=F)
up <- drive_update(as_id(r$spreadsheet_id), "status.csv")
cat('see https://docs.google.com/spreadsheets/d/1uFe21U43SX8ayFf8V0zEEmDQScfrZXLDfkTZNBzZhm0\n')
