#!/usr/bin/env Rscript
suppressPackageStartupMessages({
library(dplyr)   # %>%, inner_join
library(stringr) # str_extract
library(LNCDR)   # db_query
})


cat("# query DB for all 7T visits (scan, behave, eeg)\n")
all_7T <- db_query("select lunaid,ymd,sex,age from visits_view where studies::text like '%BrainMech%'")
nrow(all_7T)


cat("# query Anti eyetracking files matching 7T id/date on network mount (bea_res)\n")
ETroot <- '/Volumes/L/bea_res/Data/Tasks/Anti/Basic'
ETscore <- 'Scored/txt/*.summary.txt'
all_combos <- file.path(ETroot, all_7T$lunaid, all_7T$ymd, ETscore)
anti_7T <- Sys.glob(all_combos)
length(anti_7T) # 20210302: 223


cat("# reading all ET summary files\n")
read_eye <- function(f) read.table(f, header=T) %>% select(matches('AS|Drop|total|subj|date|run'))
anti_7T_smry <- lapply(anti_7T, read_eye) %>%
   bind_rows %>%
   relocate(subj,date,run) # with these columns first (instead of last)
nrow(anti_7T_smry)

saveas <- 'anti_7t.csv'
cat("# saving", saveas, "\n")
write.csv(anti_7T_smry, saveas, row.names=F)
