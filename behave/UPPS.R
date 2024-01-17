#!/usr/bin/env Rscript
library(dplyr)
# 20240117WF - add stops, trycatch, keep_files, and change write to match Makefile
l <- Sys.glob('/Volumes/L/bea_res/Data/Temporary Raw Data/7T/*/*_selfreport.csv')
extract_upps<-function(f)	{
   d <- read.csv(f)
   # find first question
   i <- grep(pattern="I have a reserved and cautious", t(d[1,]), ignore.case=T)[1]
   if(is.na(i)) stop("missing starting UPPS question in ",f)

   # have 59 questsions
   # confirm last question is expected
   last_i <- i+58
   if(!grepl("I am surprised at the things I do while in a great mood.", d[1,last_i]))
      stop("bad last question on ", last_i," column of",f)
   rng <- i:last_i
   # extract data
   # if there are multiple rows, the last is what we want (other is maybe question metadata)
   r <- d[nrow(d),rng]
   
   # remove "INSTRUCTIONS.... - " from question names
   names(r) <- unname(gsub('.* - ','',t(d[1,rng]))) 
   return(r)
}
upps_all <- lapply(l,\(f) tryCatch(extract_upps(f),error=function(e) {print(e); NULL}))
keep_files <- !sapply(upps_all,is.null)
upps <- bind_rows(upps_all)

# extract luna_date
newlevels <- c("Agree Strongly","Agree Some", "Disagree Some", "Disagree Strongly")
uppsout <-
    upps %>%
    mutate_all(list(function(x) factor(x, levels=newlevels) %>% as.numeric)) %>%
    mutate(id=sapply(l[keep_files],stringr::str_extract,'\\d{5}_\\d{8}'))

# uppsp_scoring expects colnames to be e.g. "1.I have a resev...." which is what we have!
###BTC edit 2020/02/26
names(uppsout)[names(uppsout)!="id"]<-paste(seq(1:59),names(uppsout[names(uppsout)!="id"]),sep=".") ###scoring algorithm expects actual numbers (consider changing later?
########
 
upps_scored <- LNCDR::uppsp_scoring(uppsout) %>% mutate(id=uppsout$id)
#write.csv(upps_scored, '/Volumes/Phillips/mMR_PETDA/scripts_BTC_diss/data/7Tupps_scored.csv',row.names=F)
write.csv(upps_scored, 'txt/upps_scored.csv',row.names=F)
