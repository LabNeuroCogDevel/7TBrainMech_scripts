#!/usr/bin/env Rscript

# 20231101WF - init
#   find and join all scored anti (ASL tracker)
#   see
#     /Volumes/L/bea_res/Data/Temporary Raw Data/copy7T.bash
#     /Volumes/Hera/Projects/autoeyescore/runme.sh -t anti
# writes txt/anti_scored.csv 
# uses DB to get age, sex, and subset to only 7T visits (vs all other studies doing Anti)
# imported by ../merge7T.R 


library(dplyr)
library(tidyr)
all_visits <-
   read.table(text=system('selld8 l', intern=T),
           sep="\t",
           col.names=c('ld8','age','sex','vtype','study','','visitno')) %>%
   filter(grepl('Behav',vtype), grepl('BrainMech',study))

read_scored <- function(f) read.table(f,header=T) %>% select(matches('^AS'),Dropped,total) %>% mutate(path=f)

paths <- all_visits %>%
   mutate(ldpath=gsub('_','/',ld8),
          lddot=gsub('_','.',ld8),
          fname=paste0(lddot,'.1.summary.txt'),
          path=file.path('/Volumes/L/bea_res/Data/Tasks/Anti/Basic/',ldpath,'/Scored/txt/',fname)) %>%
  select(ld8,age,sex,visitno,path) %>%
  filter(file.exists(path))

anti_scored <- merge(paths, lapply(paths$path, read_scored) %>% bind_rows, by="path") %>% select(-path)
write.csv(anti_scored, 'txt/anti_scored.csv')
