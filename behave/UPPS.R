library(dplyr)
l <- Sys.glob('/Volumes/L/bea_res/Data/Temporary Raw Data/7T/*/*_selfreport.csv')
extract_upps<-function(f) {
   d <- read.csv(f)
   # find first question
   i <- grep(pattern="I have a reserved and cautious", t(d[1,]), ignore.case=T)[1]
   # have 59 questsions
   rng <- i:(i+58)
   # extract data
   # if there are multiple rows, the last is what we want (other is maybe question metadata)
   r <- d[nrow(d),rng]
   
   # remove "INSTRUCTIONS.... - " from question names
   names(r) <- unname(gsub('.* - ','',t(d[1,rng]))) 
   return(r)
}
upps <- lapply(l,extract_upps) %>% bind_rows()

# extract luna_date
newlevels <- c("Agree Strongly","Agree Some", "Disagree Some", "Disagree Strongly")
uppsout <-
    upps %>%
    mutate_all(list(function(x) factor(x, levels=newlevels) %>% as.numeric)) %>%
    mutate(id=sapply(l,stringr::str_extract,'\\d{5}_\\d{8}'))

# uppsp_scoring expects colnames to be e.g. "1.I have a resev...." which is what we have!
upps_scored <- LNCDR::uppsp_scoring(uppsout) %>% mutate(id=uppsout$id)
write.csv(upps_scored, 'txt/upps_scored.csv',row.names=F)
