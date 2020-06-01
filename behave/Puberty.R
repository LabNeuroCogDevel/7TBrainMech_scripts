#!/usr/bin/env Rscript
# pull puberty data from selfreport.csv sheets gernerated by RAs from qualtrics
# 20200601WF (OR) - init
library(dplyr)


l <- Sys.glob('/Volumes/L/bea_res/Data/Temporary Raw Data/7T/*/*_selfreport.csv')

extract_pub<-function(f, qpatt, n_qs) {
   d <- read.csv(f)
   # find first question
   i <- grep(pattern=qpatt, t(d[1,]), ignore.case=T, perl=T)
   if(length(i) <= 0L) {
      warning(sprintf("%d columns matched '%s' for '%s'",length(i),qpatt, f))
      return(NULL)
   }
   i<-i[1]
   rng <- i:(i+n_qs)
   # extract data
   # if there are multiple rows, the last is what we want (other is maybe question metadata)
   r <- d[nrow(d),rng]
   names(r) <- as.character(unlist(d[1,rng]))
   r$ld8 <- LNCDR::ld8from(f)
   
   return(r)
}

frst_qstr <- "How old were you when you started having periods?" 
n_qs <- 5
pubertyl <- lapply(l,extract_pub, qpatt=frst_qstr,n_qs=n_qs)
puberty_female <-  pubertyl %>%  bind_rows()
write.csv(puberty_female,"txt/Puberty.csv")


# TODO: males do not have data!?

extract_pub(l[[3]], qpatt='your growth in height',n_qs=20)
pubertyl_m <- lapply(l,extract_pub, qpatt='your growth in height',n_qs=n_qs)

