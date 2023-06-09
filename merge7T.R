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
source('merge_funcs.R') # addcolprefix, lunadatemerge, check_datecol
files <- list(
 sess="txt/sessions_db.txt",
 # symlinked of 13MP20200207_LCMv2fixidx.csv; see mri/MRSI_roi/Makefile
 mrsi="mri/MRSI_roi/gam_adjust/out/gamadj_wide.csv",
 # see mri/tat2/Makefile
 tat2="mri/tat2/maskave.csv",
 # see eeg/Shane/python/fooof/runFooof.py
 fooof="eeg/Shane/fooof/Results/allSubjectsFooofMeasures_20230516.csv",
 # see mri/hurst/hurst.m
 hurst="mri/hurst/stats/MRSI_pfc13_H.csv"
)

sess <- read.table(files$sess, sep="\t", header=T) %>% rename(lunaid=`id`)
mrsi <- read.csv(files$mrsi)
tat2 <- read.csv(files$tat2)
fooof <- read.csv(files$fooof) %>% select(-X)
hurst <- read.csv(files$hurst)

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
eeg_lookup <- c("F4"="RDLPFC","F6"="RDLPFC","F8"="RDLPFC",
                   "F3"="LDLPFC","F4"="LDLPFC","F7"="LDLPFC")
fooof_dlpfc <- fooof %>%
   filter(Channel %in% names(eeg_lookup)) %>%
   mutate(Region=eeg_lookup[Channel]) %>%
   select(-Channel) %>%
   group_by(Subject, Region, Condition) %>%
   summarise_all(mean) # across(c("Offset","Exponent"), mean)
   

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

cat("fooof with missing visit number\n")
fooof_mrg %>% filter(is.na(visitno)) %>% select(lunaid,eeg.date) %>% print

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

#####

cat("mergeing all, writing merge file\n")
merged <- tat2_wide %>%
   merge(mrsi_mrg, by=c("lunaid","visitno"), all=T) %>%
   merge(fooof_mrg, by=c("lunaid","visitno"), all=T) %>%
   merge(hurst_ses, by=c("lunaid","visitno","rest.date","rest.age","rest.vscore"), all=T) %>%
  unique # 11832 is repeated 2 twice?

write.csv(merged, 'txt/merged_7t.csv', quote=F, row.names=F)


cat("merged with missing visit number\n")
merged %>% filter(is.na(visitno)) %>% select(lunaid,matches('\\.date$')) %>% print

####### QC and plots
# 11823 visit 1 is duplicated
# merged %>% select(lunaid, visitno) %>% filter(duplicated(paste(lunaid,visitno)))
library(ggplot2)
dates <- merged %>%
    select(lunaid,visitno,matches("\\.date")) %>%
    pivot_longer(matches("date"), values_to="vdate", names_to="vtype") %>%
    mutate(vtype=gsub('.date','',vtype), vdate=lubridate::ymd(vdate))

p_visits <- ggplot(dates) +
    aes(x=vdate,
        y=rank(lunaid),
        shape=as.factor(visitno))+
    geom_point(aes(color=vtype))+
    geom_line(aes(group=paste(lunaid,visitno))) +
    see::theme_modern()

ggsave(p_visits, file='imgs/visit_date_waterfall.png', width=8.05,height=8.59)

cnts <- dates %>% ungroup() %>% 
    filter(!is.na(vdate)) %>%
    unique() %>%
    group_by(lunaid, visitno) %>%
    summarise(n_per_visit=n(),
              visits=paste(collapse=",", sort(vtype))) %>% group_by(visitno, visits) %>%
    tally()


p_cnts <- ggplot(cnts) +
    aes(x=visitno, y=n, fill=visits) +
    geom_bar(stat='identity',position='dodge') + 
    see::theme_modern() +
    labs(title=glue::glue("7T from {min(dates$vdate,na.rm=T)} - {max(dates$vdate,na.rm=T)}"))

ggsave(p_cnts, file='imgs/visit_type_counts.png', width=8.05,height=8.59)
