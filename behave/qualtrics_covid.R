#!/usr/bin/env Rscript

# 20210121WF - combine Kid and Adult covid qualtrics surveys
#  creates  'txt/covid_battery.csv' and 'txt/covid_battery_name_matches.csv'
#
# INTERACTIVE NOTE:
#  the first time this is run, it is necessary to interactively pair the two suvey questions
#  once this is done, it can be reloaded

# TODO:  currently assumes
#  * only 2 surveys match "Bat.*Covid" and
#  * adult is first, kid is second

suppressPackageStartupMessages({
   library(LNCDR) # 1.4.3 -- 20210121 for qualtRics
   library(jsonlite)
})

# get questionnaires
covids <- LNCDR::qualtrics_surveys('Batt.*Covid')
# surveys may come in any order. (ingially adults was first)
snames <- names(covids)
adults <- covids[[grep('Adult',snames)]]
kids <- covids[[grep('Parent',snames)]]

names(adults) <- LNCDR::qualtrics_labels(adults)
names(kids)   <- LNCDR::qualtrics_labels(kids)

# INTERACTIVE: match questions between the two
# but only if we haven't already.
# if match file already exists, reuse it instead of interactive matching
matches_csv <- 'txt/covid_battery_name_matches.csv'
if(file.exists(matches_csv)){
    matches <- read.csv(matches_csv)
} else {
    if (!exists('txt')) dir.create('txt')
    na <- names(adults)
    nk <- names(kids)
    matches <- LNCDR::interactive_label_match(na, nk, accept_single=T, diffprint=F)
    write.csv(matches, matches_csv, row.names=F)
}

# select just the overlapping columns
# and make the names the same
# so we can combine
a <- adults[matches[,1]]
k <- kids[matches[,2]]
names(k) <- names(a)
all_covid_battery <- rbind(a, k)

# save
write.csv(all_covid_battery, 'txt/covid_battery_sharedonly.csv', row.names=F)
# all_covid_battery <- read.csv('txt/covid_battery_sharedonly.csv') %>%
#  rename(`External Data Reference`=External.Data.Reference)

# add adult only questions
missing_cols <- ! names(adults) %in% matches[,1]
id_col <- grepl("External.Data.Reference", names(adults))
adult_only <- adults[, missing_cols | id_col ]
all_covid_battery_and_adult <-
    merge(all_covid_battery,
          adult_only,
          by="External Data Reference", all.x=TRUE)
write.csv(all_covid_battery, 'txt/covid_battery.csv', row.names=F)
