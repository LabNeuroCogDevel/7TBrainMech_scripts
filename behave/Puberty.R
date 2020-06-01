#!/usr/bin/env Rscript
library(dplyr)


l <- Sys.glob('/Volumes/L/bea_res/Data/Temporary Raw Data/7T/*/*_selfreport.csv')

extract_pub<-function(f, qpatt, n_qs) {
   d <- read.csv(f)
   # find first question
   i <- grep(pattern=qpatt, t(d[1,]), ignore.case=T, perl=T)
   if(length(i) <= 0L) {
      warning(sprintf("%d columns matched '%s' for '%s'",length(i),frst_qstr, f))
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
puberty <-  pubertyl %>%  bind_rows()

