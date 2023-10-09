#!/usr/bin/env Rscript

# 20220918WF - init
#   extract ASR/YSR survey data from qualtrics
#   separate survey is given for age group * sex * visit year
library(dplyr)



# replace Q20_xx with actual question text
# NB. ysr/asr have different questions. and differetn qualtirs version might have typos
#     this function does not yet but should try to
#     unify question text. see pet ASR/YSR code
unify_question <- function(labs){
   gsub('.*? - ?(\\d+\\.)? *','',labs) %>% unname
   #TODO: YSR vs ASR question names
}

sr_relabel<-function(d) {
   q20_idx <- grepl('Q20_',names(d))
   new_labs <- sapply(d[1,q20_idx], attr,'label') %>% unify_question 
   names(d)[q20_idx] <- new_labs
   return(d)
}

screener_list <- function(){
   load('svys.RData') # from 000_getQualtrics.R
   names(svys) %>% grep("Sreen", ., value=T)
   screeners <- names(svys) %>% grep(pattern="Screen",value=T)
   svys[screeners]  %>% Filter(f=function(l) !is.null(l))
}

q_to_num <- function(x) gsub(' =.*','',x) %>% as.numeric

# TODO:
# this should probably be a merge instead of a function used in mutate
external_lookup_merge <- function(d) {
   # ExternalReference
   all_ids <- LNCDR::db_query("
     select q.id as qid, l.id as LunaID
     from enroll q join enroll l
       on q.pid=l.pid and q.etype like 'QualtricsID' and l.etype like 'LunaID'")
   merge(d, all_ids, all.x=T, by.x="ExternalReference", by.y="qid")
}

# go through all surveys and extract the relavant data
# "Q20_*" is asr/ysr for all.
# ExtrenalReference is 7T_{K,A,H}_### and has a lookup (somewhere?!) to lunaid
ASRYSR <-  screener_list() %>%
   mapply(., names(.),
          FUN=function(d,n) d %>%
             select(matches('External|EndDate|Q20_')) %>%
             sr_relabel %>%
             mutate(from=n)) %>%
   bind_rows %>%
   mutate(across(.fns=q_to_num, c(-ExternalReference,-EndDate,-from))) %>%
   external_lookup_merge()

write.csv(ASRYSR, 'txt/asr_ysr.csv', row.names=F)
