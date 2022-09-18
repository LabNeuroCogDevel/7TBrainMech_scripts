#!/usr/bin/env Rscript

# 20220918WF - init
#   extract ASR/YSR survey data from qualtrics
#   separate survey is given for age group * sex * visit year


library(dplyr)

load('svys.RData') # from 000_getQualtrics.R

names(svys) %>% grep("Sreen", ., value=T)
screeners <- names(svys) %>% grep(pattern="Screen",value=T)

# replace Q20_xx with actual question text
# NB. ysr/asr have different questions. and differetn qualtirs version might have typos
#     this function does not yet but should try to
#     unify question text. see pet ASR/YSR code
sr_relabel<-function(d) {
   q20_idx <- grepl('Q20_',names(d))
   new_labs <- sapply(d[1,q20_idx], attr,'label') %>% gsub('.*? - ?(\\d+\\.)? *','',.) %>% unname
   names(d)[q20_idx] <- new_labs
   return(d)
}

# go through all surveys and extract the relavant data
# "Q20_*" is asr/ysr for all.
# ExtrenalReference is 7T_{K,A,H}_### and has a lookup (somewhere?!) to lunaid
ASRYSR <- svys[screeners] %>%
   Filter(f=function(l) !is.null(l)) %>%
   mapply(., names(.),
          FUN=function(d,n) d %>%
             select(matches('External|EndDate|Q20_')) %>%
             sr_relabel %>%
             mutate(from=n)) %>%
   bind_rows

write.csv(ASRYSR, 'txt/asr_ysr.csv', row.names=F)
