#!/usr/bin/env Rscript
# 20190403 - init
#  what files do we have, which are missing


# source("https://install-github.me/r-lib/rematch2")
# devtools::install_github("tidyverse/googlesheets4")
# install.packages('googledrive')
library("googlesheets4")
library("googledrive")
library(lubridate)
library(dplyr)
library(stringr)

ctime <- function(x) ifelse(file.exists(x), as.character(file.info(x)$ctime), NA)
nfiles <- function(x) sapply(x, function(g) length(Sys.glob(g)))

gs4_deauth()
# BJuvXhimotkHG8zvHMTICmGEVyM
# https://docs.google.com/spreadsheets/d/1_EdqA8ObwPaqeLd-BJuvXhimotkHG8zvHMTICmGEVyM/edit?usp=sharing
r <- gs4_get("1_EdqA8ObwPaqeLd-BJuvXhimotkHG8zvHMTICmGEVyM")


## get id for all the places it could be
# use only mrid from sheet

# current sheet
cat("Fetching previous gsheet (getting notes)\n")
d_google <- googlesheets4::read_sheet(r$spreadsheet_id)

# ids we have in raw
cat("searching all raw MR\n")
files_mrid <- data.frame(mrid=Sys.glob('/Volumes/Hera/Raw/MRprojects/7TBrainMech/2*L*/') %>% basename)

cat("querying pgsql database\n")
# ids in database
ids <- LNCDR::db_query("
 with 
   ld as (select pid, id as luna from enroll where etype like 'LunaID'),
   mr as (select pid, id as mrid from enroll where etype like '7TMRID')
   select mrid, luna, dob from ld
     join mr on ld.pid=mr.pid
     join person on ld.pid=person.pid;");

# make dob age
ids <-
   ids %>%
   mutate(age = floor(as.numeric(ymd(str_extract(mrid,'\\d{8}')) - ymd(dob))/365.25) ) %>%
   select(-dob)

# ld8 -- people we migth be missing b/c we don't have a MRID
ld8 <- LNCDR::db_query("
   select id || '_' || to_char(vtimestamp,'YYYYmmdd') as ld8, vscore
   from visit
   natural join visit_study
   natural join enroll 
   where vtype ilike 'scan%'
     and study ilike 'Brain%'
     and etype like 'LunaID'")

# ids from BIDS rawlink
cat("search all rawlinks in 'BIDS' on Hera\n")
links <-
 Sys.glob('/Volumes/Hera/Raw/BIDS/7TBrainMech/rawlinks/1*_*/') %>%
 sapply(function(x)
         sprintf("find %s -type l -print0 -print -quit |xargs -0 readlink",x) %>%
         system(intern=T) %>%
         str_extract('(?<=7TBrainMech/)[^/]+'))
links_df <-
   data.frame(ld8=names(links) %>% basename, mrid=links %>% unname) %>%
   mutate(luna=gsub("_.*", "", ld8)) 

# behavioral scan files
cat("search for all task .csv files on bea_res\n")
#task_files <- paste0('/Volumes/L/bea_res/Data/Tasks/MGSEncMem/7T/1*_2*/',c('*','*/*'),'/*/*.csv') %>% Sys.glob()
task_files <- system('find /Volumes/L/bea_res/Data/Tasks/MGSEncMem/7T/ -iname "*csv"', intern=T)
d_task <-
   data.frame(ld8=str_extract(task_files, "\\d{5}_\\d{8}"),
           set=str_extract(task_files, "(?<=mgsenc-)[A-Z]")) %>%
   group_by(ld8,set) %>% summarise(`# task csv`=n())

# combine all
d <- 
   merge(links_df, ids, all=T, by=c('mrid','luna')) %>%
   merge(files_mrid,all=T, by='mrid') %>%
   merge(ld8, all=T, by='ld8') %>%
   merge(d_task, all=T, by='ld8') %>%
   merge(d_google %>% select(mrid, notes), by='mrid',all=T) %>%
   filter(! mrid %in% c('20170929Luna', '20171009Luna'), !duplicated(mrid))

# add timepoint. visists that are more than 200 days apart count as a new visit
# N.B. should get this from DB. but easier here
d <- d %>%
   tidyr::separate(ld8, c('luna','vdate'), remove=F) %>%
   mutate(vdate=lubridate::ymd(vdate)) %>%
   group_by(luna) %>%
   mutate(tp=cumsum(c(0,diff(vdate)>200))+1)

## find all the files (count and/or creation time)

d$`MR dir` <- ctime(file.path('/Volumes/Hera/Raw/MRprojects/7TBrainMech/', d$mrid))
d$`# MR`   <- nfiles(file.path('/Volumes/Hera/Raw/MRprojects/7TBrainMech', d$mrid, '*/'))

d$csipfc_raw <- ctime(file.path('/Volumes/Hera/Raw/MRprojects/7TBrainMech', d$mrid, 'CSIPFC'))
# raw csi lives in box too
mi <- is.na(d$csipfc_raw)
d$csipfc_raw[mi] <- ctime(file.path('/Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/PFC_siarray/', d$mrid[mi], 'siarray.1.1'))
# also check anything we linked in raw
#mi <- is.na(d$csipfc_raw)
#d$csipfc_raw[mi] <- ctime(file.path('/Volumes/Hera/Projects/7TBrainMech/subjs/', d$ld8[mi], '/slice_PFC/MRSI_roi/raw/siarray.1.1'))

bidspath <- paste0('sub-',gsub('_','/', d$ld8))
d$`# BIDS`  <- nfiles(file.path('/Volumes/Hera/Raw/BIDS/7TBrainMech', bidspath, '*/*.nii.gz'))
d$rest_brnaswdkm <- ctime(file.path('/Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_ica/', d$ld8, '/brnaswdkm_func_4.nii.gz')) 
d$task_preproc <- ctime(file.path('/Volumes/Hera/preproc/7TBrainMech_mgsencmem/MHTask_nost/', d$ld8, '/alltasks_preproc_complete')) 
d$rawt1 <- ctime(file.path('/Volumes/Hera/Raw/BIDS/7TBrainMech', bidspath, sprintf('anat/sub-%s_T1w.nii.gz',d$luna))) 
d$ppt1 <- ctime(file.path('/Volumes/Hera/preproc/7TBrainMech_rest/MHT1_2mm/', d$ld8, 'mprage_warpcoef.nii.gz')) 
d$FS     <- ctime(file.path('/Volumes/Hera/preproc/7TBrainMech_rest/FS', d$ld8, 'mri/aseg.mgz')) 
d$pfc_coordroi <- ctime(file.path('/Volumes/Hera/Projects/7TBrainMech/subjs/', d$ld8, 'slice_PFC/MRSI/all_csi.nii.gz')) 


# get csi slice number by looking for apodized
d$pfc_scout <- ctime(file.path('/Volumes/Hera/Projects/7TBrainMech/subjs/', d$ld8, 'slice_PFC/slice_pfc.nii.gz'))
d$pfc_slice <- file.path('/Volumes/Hera/Projects/7TBrainMech/subjs/', d$ld8, 'slice_PFC/MRSI/2d_csi_ROI/*SumProb_FlipLR') %>%
             lapply(function(x) Sys.glob(x) %>% first %>% basename) %>% unlist %>% str_extract('^\\d+')

# 20200313 - slice pfc processing
d$`pfc_picked`  <- nfiles(file.path('/Volumes/Hera/Projects/7TBrainMech/subjs/', d$ld8, '/slice_PFC/MRSI_roi/13MP20200207/*/picked_coords.txt'))
d$`pfc_recieved`  <- nfiles(file.path('/Volumes/Hera/Projects/7TBrainMech/subjs/', d$ld8, '/slice_PFC/MRSI_roi/LCModel/v2idxfix/*.dir'))


# find all spreadsheet files and merge back into d
pfcfiles <- 
   system("find /Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/ -not -ipath '*/BAD_rowcol/*' -iname spreadsheet.csv",
          intern=T) %>% 
   data.frame(fname=., stringsAsFactors=F) %>% 
   mutate(mrid=str_extract(fname, '(?<=/)20\\d{6}[^/]+'),
          pfc_csv=ctime(fname)) %>%
   filter(!duplicated(mrid), !is.na(mrid))

d.order <- names(d)
d <- 
   pfcfiles %>% select(-fname) %>%
   merge(d, ., by='mrid', all.x=T, all.y=F, suffixes=c('.x',''))
d <- d[,unique(c(d.order,'pfc_csv'))]

# blank out NA notes
names(d)
d$notes[is.na(d$notes)|d$notes=="NA"] <- ""

# add missing mr
lastmrid <- max(as.numeric(substr(d$mrid,1,8)),na.rm=T)
missingMR <- ld8 %>% tidyr::separate(ld8,c('luna','vdate'),remove=F) %>%
   filter(as.numeric(vdate) > lastmrid)
d <- merge(d,missingMR %>% select(luna,ld8,vscore),all=T)

# 20200520 - hc from csv output
hc <- read.csv('Hc/txt/all_hc.csv') %>% group_by(ld8) %>% tally() %>% rename(nHc=n)
d <- merge(d, hc, by="ld8", all.x=T)


outstatus <- "/Volumes/Hera/Projects/7TBrainMech/scripts/mri/txt/status.csv"
write.csv(as.data.frame(d), file=outstatus, row.names=F)
cat("uploading to goolge drive\n")
drive_deauth()
up <- drive_update(as_id(r$spreadsheet_id), outstatus)
cat("see https://docs.google.com/spreadsheets/d/1_EdqA8ObwPaqeLd-BJuvXhimotkHG8zvHMTICmGEVyM\n")
# set header using lncdtool's gsheets - freeze and bold first row
system("gsheets -w 1_EdqA8ObwPaqeLd-BJuvXhimotkHG8zvHMTICmGEVyM -a header")

# print missing
cat("missing csi\n")
d %>%
   filter(is.na(pfc_csv)|is.na(mrid),
          is.na(notes)|notes==""|grepl('no rawdcm',notes)) %>%
   select(mrid, ld8,`# MR`, pfc_csv, notes) %>%
   arrange(mrid) %>%
   print.data.frame(row.names=F) 

cat("missing task\n")
missing_task <-
   d %>%
   filter(is.na(task_preproc),
          `# BIDS` > 2,
          is.na(notes)|notes==""|grepl('no rawdcm',notes)) %>%
   select(ld8, mrid, `# BIDS`, task_preproc, rest_brnaswdkm, notes) %>%
   arrange(ld8)
print.data.frame(missing_task, row.names=F) 

# save missing to txtfile
sink('txt/missing_task.ld8.txt')
cat(paste(collapse="\n", missing_task$ld8),"\n")
sink()

