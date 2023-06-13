#!/usr/bin/env Rscript

##
# read various sources of information into a too-many-columns file.
# timepoint per row (beh, eeg, and MR on one line)
#
# see Makefile for individual file source
#
# modelled after mergePet.R
# /Volumes/Phillips/mMR_PETDA/scripts/mergePet_functions.R
##
#
# 20230518WF - init
# 20230531WF - update MRS to use gamadj
#
suppressPackageStartupMessages({
library(dplyr); library(tidyr)})
library(glue)
source('merge_funcs.R') # addcolprefix, lunadatemerge, check_datecol
files <- list(
 sess="txt/sessions_db.txt",
 # symlinked of 13MP20200207_LCMv2fixidx.csv; see mri/MRSI_roi/Makefile
 mrsi="mri/MRSI_roi/gam_adjust/out/gamadj_wide.csv",
 # see mri/tat2/Makefile
 tat2="mri/tat2/maskave.csv",
 # see eeg/Shane/python/fooof/runFooof.py
 #fooof="eeg/Shane/fooof/Results/allSubjectsFooofMeasures_20230516.csv", # channel no region
 fooof="eeg/Shane/fooof/Results/allSubjectsDLPFCfooofMeasures_20230523.csv", # region no channel
 # see mri/hurst/hurst.m
 hurst="mri/hurst/stats/MRSI_pfc13_H.csv",
 mgs_eog="eeg/eog_cal/eye_scored_mgs_eog.csv" # 20230612
)

sess <- read.table(files$sess, sep="\t", header=T) %>% rename(lunaid=`id`)
mrsi <- read.csv(files$mrsi)
tat2 <- read.csv(files$tat2)
fooof <- read.csv(files$fooof)
hurst <- read.csv(files$hurst)
mgs_eog_trial <- read.csv(files$mgs_eog) %>%
   rename(lunaid=LunaID,date=ScanDate)

## tat2 - roi, subj (luan_date), event, beta
#        use to get rest date
tat2_wide <- tat2 %>%
   separate(subj,c('lunaid','rest.date')) %>%
   # is all rest. no other events
   #pivot_wider(names_from=c("roi","event"), values_from="beta")
   select(-event) %>% 
   pivot_wider(names_from=c("roi"), values_from="beta") %>%
   # add tat2 columns, but undo for ids
   addcolprefix('tat2') %>%
   rename(rest.date=tat2.rest.date) %>%
   merge(sess %>%
         filter(vtype=="Scan") %>%
         select(lunaid,visitno,vdate,rest.age=age,rest.vscore=vscore),
         all.x=T, by.x=c("lunaid","rest.date"), by.y=c("lunaid","vdate"))

## mrsi -- subset to just GABA|Glu + CR|SD 
#  and ditch anything without an roi label
# TODO: might want version with regresssion applied
mrsi_mrg <- mrsi %>%
   separate(ld8, c("lunaid","date")) %>% 
   addcolprefix('sipfc')
mrsi_mrg <-  merge(mrsi_mrg,
           sess %>% filter(vtype=="Scan") %>%
           select(lunaid, vdate, visitno, sipfc.age=age, sipfc.vscore=vscore),
         all.x=T, by.x=c("lunaid","sipfc.date"),by.y=c("lunaid","vdate"))

# fooof - Subject, Channel, Offset, Exponent, Condition (closed/open)
# 20230609 - from shane
if("Channel" %in% names(fooof)) {
   eeg_lookup <- c("F4"="RDLPFC","F6"="RDLPFC","F8"="RDLPFC",
                      "F3"="LDLPFC","F4"="LDLPFC","F7"="LDLPFC")
   fooof_dlpfc <- fooof %>% select(-X) %>%
      filter(Channel %in% names(eeg_lookup)) %>%
      mutate(Region=eeg_lookup[Channel]) %>%
      select(-Channel) %>%
   group_by(Subject, Region, Condition) %>%
   summarise_all(mean) # across(c("Offset","Exponent"), mean)
} else {
  fooof_dlpfc <- fooof %>% select(Subject,Condition,Offset,Exponent,Region)
}
   

fooof_wide <- fooof_dlpfc %>%
    pivot_wider(
        names_from=c("Condition", "Region"),
        values_from = c("Offset","Exponent"),
        names_glue = "{Condition}_{Region}_{.value}") %>%
    separate(Subject, c("lunaid","date")) %>% 
    addcolprefix('eeg')

fooof_mrg <-  merge(fooof_wide,
           sess %>% filter(grepl("EEG", vtype,ignore.case=T)) %>%
           select(lunaid, vdate, visitno, eeg.age=age, eeg.vscore=vscore),
         all.x=T, by.x=c("lunaid","eeg.date"),by.y=c("lunaid","vdate"))

# 11668_20170710 first visit no in DB? only one missing currently. quick fix
fooof_mrg$visitno[is.na(fooof_mrg$visitno) & fooof_mrg$lunaid == "11668"] <- 1

cat("have",nrow(fooof_mrg),"eeg rows\n")
fooof_mia <- fooof_mrg %>% filter(is.na(visitno))
if(nrow(fooof_mia) >0L) {
 cat("fooof with missing visit number\n")
 fooof_mia %>% select(lunaid,eeg.date) %>% print
}

## Hurst will use tat2's rest.date to merge
#  dont need session info -- should already have. but just incase
hurst_ses <- hurst %>% separate(ld8,c('lunaid','date')) %>%
   addcolprefix('hurst') %>% rename(rest.date=hurst.date) %>%
   # TODO: maybe a function for all rest like inputs
   merge(sess %>%
         filter(vtype=="Scan") %>%
         select(lunaid,visitno,vdate,rest.age=age,rest.vscore=vscore),
         all.x=T, by.x=c("lunaid","rest.date"), by.y=c("lunaid","vdate"))

#hurst_ses %>% filter(is.na(visitno))


## MGS task eye tracking results from EOG
# initially have trial level data.
# collapse over delays to get row per visit. get mean and sd of every measure
mgs_eog_visit_dly <- mgs_eog_trial %>%
   group_by(lunaid,date,Delay) %>%
   summarise(across(-Trial, list(mean=function(x) mean(x,na.rm=T),
                                 sd=function(x) sd(x,na.rm=T))),
             nTrial=n()) %>%
   pivot_wider(id_cols=c("lunaid","date"),
               names_from=c("Delay"),
               values_from=matches("_mean|_sd|nTrial")) %>%
   addcolprefix('eeg')

mgs_eog_visit_nodly <- mgs_eog_trial %>%
   group_by(lunaid,date) %>%
   summarise(across(-Trial, list(mean=function(x) mean(x,na.rm=T),
                                 sd=function(x) sd(x,na.rm=T))),
             nTrial=n()) %>%
   mutate(Delay="all") %>%
   pivot_wider(id_cols=c("lunaid","date"),
               names_from=c("Delay"),
               values_from=matches("_mean|_sd|nTrial")) %>%
   addcolprefix('eeg')

# combine delay columns: _all and _6 _8 _10
mgs_eog_visit <- merge(mgs_eog_visit_dly,
                       mgs_eog_visit_nodly,
                       by=c("lunaid","eeg.date")) %>%
   select(!matches('calR2.*sd'))


mgs_eog <- mgs_eog_visit %>%
   merge(sess %>%
         filter(vtype=="eeg") %>%
         select(lunaid,visitno,eeg.date=vdate,eeg.age=age,eeg.vscore=vscore),
         all.x=T, by.x=c("lunaid","eeg.date"), by.y=c("lunaid","eeg.date"))

missing_eog <- filter(mgs_eog,is.na(eeg.age))
if(nrow(missing_eog)>0L){
   cat("#",nrow(missing_eog),"MISSING EEG (EOG) visit in DB\n")
   missing_eog %>% select(lunaid,eeg.date) %>% print
}
#####

cat("mergeing all, writing merge file\n")
merged <- tat2_wide %>%
   merge(mrsi_mrg, by=c("lunaid","visitno"), all=T) %>%
   merge(fooof_mrg, by=c("lunaid","visitno"), all=T) %>%
   merge(hurst_ses, by=c("lunaid","visitno","rest.date","rest.age","rest.vscore"), all=T) %>%
   merge(mgs_eog, by=c("lunaid","visitno","eeg.date","eeg.age","eeg.vscore"), all=T) %>%
  unique # 11832 is repeated 2 twice?


cat(glue("# merged: {nrow(merged)} rows with {ncol(merged)} columns"),"\n")
write.csv(merged, 'txt/merged_7t.csv', quote=F, row.names=F)


cat("merged with missing visit number\n")
merged %>% filter(is.na(visitno)) %>% select(lunaid,matches('\\.date$')) %>% print

