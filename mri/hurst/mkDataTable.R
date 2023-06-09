#!/usr/bin/env Rscript

# 20230518WF - init
#  make a data table for afni's 3dMVM or 3dLME

library(dplyr)
library(tidyr)
sess <- read.table("../../txt/sessions_db.txt", sep="\t", header=T) %>% filter(vtype=="Scan")
niis <- Sys.glob('hurst_nii/1*_2*.nii.gz')

hurst <- data.frame(ld8=LNCDR::ld8from(niis), InputFile=niis) %>%
      separate(ld8,c("id","vdate")) %>%
      group_by(`id`) %>% mutate(visitno_r=rank(vdate)) %>% ungroup()

d <- merge(sess, hurst, by=c("id","vdate"), all.y=T) %>%
   rename(Subj=`id`) %>%  relocate(InputFile, .after = last_col())

d %>% filter(is.na(age)) %>% print
write.table(d%>% filter(!is.na(age)), 'datatable.tsv',sep="\t",row.names=F,quote=F)

