library(dplyr)
l <- Sys.glob('/Volumes/L/bea_res/Data/Temporary Raw Data/7T/*/*_selfreport.csv')
extract_upps<-function(f){
   d <- read.csv(f)
   # find first question
   i <- grep(pattern="I have a reserved and cautious", t(d[1,]), ignore.case=T)[1]
   # have 59 questsions
   rng <- i:(i+59)
   # extract data
   r <- d[nrow(d),rng]
   # remove "INSTRUCTIONS.... - " from question names
   names(r) <- unname(gsub('.* - ','',t(d[1,rng]))) 
   return(r)
}
upps <- lapply(l,extract_upps) %>% bind_rows()

# extract luna_date
upps$id <- sapply(l,stringr::str_extract,'\\d{5}_\\d{8}')

# TODO:
# respones back to numbers
# upps %>% mutate_all(as.factor( levels=("Agree Strongly","Agree Some", "Disagree Some", "Disagree Strongly"))
# add subjectid back
