#!/usr/bin/env Rscript
library(dplyr); library(tidyr)

# 20230616WF - init, from SM
#  - add n and ndrop
#  

z_thresh <- 2
deg_thresh <- 23
lat_thresh <- 0.1 # 100ms. is 60ms elsewhere
in_file <- 'eye_scored_mgs_eog.csv'
out_file <- 'eye_scored_mgs_eog_cleanvisit.csv'

znathres <- function(x) ifelse(abs(scale(x))[,1]>=z_thresh,NA,x)
test_thres <- function(){
   x <- c(10000,1,1,0,0,0,0)
   testthat::expect_equal(c(NA,x[2:7]), znathres(x))
}

# LunaID,ScanDate,Trial,Delay,DelaySaccades,PositionError,DisplacementError,BestError,vgsLatency,mgsLatency,calR2
eog <- read.csv(in_file)
eog_clean <- eog %>%
   mutate(
          # NB maybe dont abs the Error? wont be able to see bias for left or right?
          across(c("PositionError","BestError"), abs), # keep side information
          across(matches("Error"),         function(x) ifelse(abs(x)>deg_thresh,NA,x)),
          across(matches("Latency"),       function(x) ifelse(x     <lat_thresh,NA,x)),
          across(matches("Latency|Error"), znathres))

# collapse across all trial 
err_lat_collapse <- function(eog_clean)
   eog_clean %>%
   group_by(LunaID,ScanDate,Delay) %>%
   summarise(across(matches("Error|Latency"),
                    list(mean=function(x) mean(x,na.rm=T),
                         sd=function(x) sd(x,na.rm=T),
                         ndrop=function(x) length(which(is.na(x))))),
             n=n()) %>%
   ungroup() %>%
   mutate(across(matches("(Error|Latency)_(mean|sd)"), znathres)) %>%
   # make columns like 'BestError_Delay6'
   pivot_wider(id_cols=c("LunaID","ScanDate"), names_from="Delay", values_from=matches("Error|Latency|^n$")) %>%
   rename_all(function(x) gsub('_mean','',x))

# want a collapsed across delay ('*_DelayAll' columns) and each delay enumerated version ('*Delay6',...'*Delay10')
eog_visit_nodly <- eog_clean %>% mutate(Delay='DelayAll') %>% err_lat_collapse
eog_visit_dly <- eog_clean %>% mutate(Delay=paste0('Delay',Delay)) %>% err_lat_collapse
eog_visit <- merge(eog_visit_nodly, eog_visit_dly, by=c("LunaID","ScanDate"),all=TRUE)

write.csv(eog_visit, file=out_file, row.names=F, quote=F)
