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
# TODO: dont hardcode indexes
adults <- covids[[1]]
kids <- covids[[2]]

names(adults) <- LNCDR::qualtrics_labels(adults)
names(kids)   <- LNCDR::qualtrics_labels(kids)

# INTERACTIVE: match questions between the two
matches_csv <- 'txt/covid_battery_name_matches.csv'
if(file.exists(matches_csv)){
    matches <- read.csv(matches_csv)
} else {
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
write.csv(all_covid_battery, 'txt/covid_battery.csv', row.names=F)
