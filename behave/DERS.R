#!/usr/bin/env Rscript
suppressPackageStartupMessages({library(dplyr); library(tidyr);})

# 20220804WF - init
#   Difficulties in emotion regulation scale (DERS)
#   depenends on 000_getQualtrics.R writing selfreport.csv files

ders_numeric <- function(x)
   stringr::str_extract(x, '\\d+-\\d+') %>%
      factor(levels=c("0-10","11-35","36-65","66-90","91-100")) %>%
      as.numeric

read_ders <- function(f="/Volumes/L/bea_res/Data/Temporary Raw Data/7T/11822_20200415/11822_20200415_selfreport.csv") {
  # NB. only 28/343 survey files: M 10.2-17.8, dates 20180709-20200415
  # maybe column names are different in other batteries?
  col_pattern <- '^Q(570|572|574|576|578|580)'
  d <- read.csv(f) %>%
     select(matches(col_pattern))
  attr(d,'questions') <- unlist(unname(d[1,]))
  comment(d) <- glue::glue("DERS: subset of {f} using {col_pattern}")
  d[2,] %>%
     mutate(across(everything(),ders_numeric),
           ld8 = LNCDR::ld8from(f))
}

all_ders <- function(){
   l <- Sys.glob("/Volumes/L/bea_res/Data/Temporary Raw Data/7T/1*_2*[0-9]/1*_2*[0-9]_selfreport.csv")
   d_all <-lapply(l, read_ders)
   d <- bind_rows(d_all)

   # subset to just those with DERS columns. all should have ld8 column.
   has_data <- which(apply(d, 1, function(x) sum(!is.na(x))) > 1)
   d <- d[has_data,]

   # questions isn't a default R attribute. it's not carried over from bind_rows
   attr(d,'questions')  <- attr(d_all[[has_data[1]]],'questions')

   #comment(d) # inhereted from last element in list

   return(d)
}

# if running from command line
if(sys.nframe()==0){
   cat("NOTE: as of 20220804, only know how to find columns for adolesent male battery (28/343 files)\n")
   write.csv(file="txt/ders.csv", all_ders(), row.names=FALSE)
}
