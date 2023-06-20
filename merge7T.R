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
 # see mri/MRSI_roi/gam_adjust/Makefile
 mrsi="mri/MRSI_roi/gam_adjust/out/gamadj_wide.csv",
 # see mri/tat2/Makefile
 tat2="mri/tat2/maskave.csv",
 # see eeg/Shane/python/fooof/runFooof.py
 #fooof="eeg/Shane/fooof/Results/allSubjectsFooofMeasures_20230516.csv", # channel no region
 fooof="eeg/Shane/fooof/Results/allSubjectsDLPFCfooofMeasures_20230523.csv", # region no channel
 # see mri/hurst/hurst.m
 hurst="mri/hurst/stats/MRSI_pfc13_H.csv",
 #mgs_eog="eeg/eog_cal/eye_scored_mgs_eog.csv" # 20230612
 mgs_eog="eeg/eog_cal/eye_scored_mgs_eog_cleanvisit.csv", # 20230616. new cleaned version
 sr="behave/txt/SR.csv" # 20230620. pulled from db from RA matained sheets
)

sess <- read.table(files$sess, sep="\t", header=T) %>% rename(lunaid=`id`)
mrsi <- read.csv(files$mrsi)
tat2 <- read.csv(files$tat2)
fooof <- read.csv(files$fooof)
hurst <- read.csv(files$hurst)
mgs_eog_visit <- read.csv(files$mgs_eog)
sr <- read.csv(files$sr) %>% addcolprefix('sr') %>%
      rename(screen.date=sr.date.screening, visitno=sr.visitno)

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


mgs_eog <- mgs_eog_visit %>%
   rename(lunaid=LunaID,date=ScanDate) %>%
   addcolprefix('eeg') %>%
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
sessid <- function(d)
   apply(d,1,function(x)
         paste0(collapse="_",x[c("lunaid","visitno")])) %>%
   gsub(' ','',.)

merge_and_check <- function(big, d, ...) {
   big.new <- merge(big, d, ...) %>% unique # 11832 is repeated 2 twice?

   bs <- sessid(big)
   ds <- sessid(d)
   mia_big <- setdiff(bs,ds)
   mia_d   <- setdiff(ds,bs)
   cat("#",
       glue::glue(
                  "{substitute(d)}({nrow(d)}x{ncol(d)}) adding ",
                  "to {nrow(big)}x{ncol(big)}; ",
                  "{length(mia_big)} new visits / ",
                  "{length(mia_d)} not in {substitute(d)}"),
       "\n")

   cat("  missing: ", paste(collapse=", ",head(mia_big)), "\n")
   cat("      new: ", paste(collapse=", ",head(mia_d))  , "\n")
   cat("   total rows now",nrow(big.new),"\n")
   return(big.new)
}

cat("mergeing all, writing merge file\n")
merged <- tat2_wide %>%
   merge_and_check(mrsi_mrg, by=c("lunaid","visitno"), all=T) %>%
   merge_and_check(fooof_mrg, by=c("lunaid","visitno"), all=T) %>%
   merge_and_check(hurst_ses, by=c("lunaid","visitno","rest.date","rest.age","rest.vscore"), all=T) %>%
   merge_and_check(mgs_eog, by=c("lunaid","visitno","eeg.date","eeg.age","eeg.vscore"), all=T) %>%
   merge_and_check(sr, by=c("lunaid","visitno"), all.x=T, all.y=F) %>%
  unique # 11832 is repeated 2 twice?


cat(glue("# merged: {nrow(merged)} rows with {ncol(merged)} columns"),"\n")
write.csv(merged, 'txt/merged_7t.csv', quote=F, row.names=F)


cat("merged with missing visit number\n")
merged %>% filter(is.na(visitno)) %>% select(lunaid,matches('\\.date$')) %>% print
