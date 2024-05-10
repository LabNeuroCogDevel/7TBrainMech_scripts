#!/usr/bin/env Rscript
library(dplyr)
source('000_getQualtrics.R') # extract_qrange
# 20240509WF - copy of RT18.R but using extract_qrange from getQualtrics

FIRST_TEXT <- "When it's time to go to bed, I want to stay up and do other things"
LAST_TEXT  <- "I have trouble getting out of bed in the morning"
N_QUESTS <- 28
extract_asws <- function(f) extract_qrange(f, FIRST_TEXT, LAST_TEXT, N_QUESTS)
choices_as_num <- function(choices) {
   as.numeric(factor(choices, levels=c("Never","Once in awhile", "Sometimes","Quite often","Frequently, if not always", "Always")))
}
revscore <- function(s) rev(1:6)[s] #r(6) == 1; r(1) == 6
write_all_asws <- function() {
   load('svys.RData') # srvy
   all_asws <- lapply(svys, extract_asws) %>% Filter(f=\(x) !is.null(x))
   asws <- lapply(1:length(all_asws),\(i) all_asws[[i]] %>% mutate(from=names(all_asws)[i]))  %>%
      bind_rows %>%
      rename_with(\(colname) gsub('in the past[^-]*- ?|[^a-z0-9 ]','', tolower(colname) %>% gsub(' \\+',' ',.))) %>%
      mutate(visitno=stringr::str_extract(from, "(?<=7T Y)[1-3]"),
             visitno=as.numeric(ifelse(is.na(visitno),1,visitno)))

   # choices <- asws[,1:28] %>% unlist %>% unique
   # [1] "Never"                     "Once in awhile"            "Quite often"               "Sometimes"                
   # [5] "Frequently, if not always" "Always"                    NA                         
   
   # columns that need to be revrse scored
   rev_cols <- c() # TODO: which of these?
   asws_num <- asws %>% 
      mutate(across(1:28, choices_as_num),
             across(all_of(rev_cols), revscore))
      

   # TODO:
   #   find scoring. fix rev_col

   write.csv(asws_num, 'txt/asws.csv',row.names=F)
}
# when run as script
if(sys.nframe()==0) write_all_asws()
