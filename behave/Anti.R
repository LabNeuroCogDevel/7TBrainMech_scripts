#!/usr/bin/env Rscript
# giant spreadsheet of all eyetracking
# also see
#  /Volumes/L/bea_res/Data/Temporary Raw Data/copy7T.bash
#  /Volumes/Hera/Projects/autoeyescore/runme.bash -t anti
library(dplyr)

# find all 7t behave scan dates
behids7t <- LNCDR::db_query("
 select id || '_' || to_char(vtimestamp,'YYYYMMDD') as ld8
 from visit natural join enroll natural join visit_study
 where etype like 'LunaID' and study like 'BrainMechR01' and vtype like '%havioral%'")

# find as many files matching the ids as we can
trial_files <- sapply(behids7t, function(p)
       gsub("_", "/", p) %>% 
       sprintf("/Volumes/L/bea_res/Data/Tasks/Anti/Basic/%s/Scored/txt/*.1.trial.txt", .) %>%
       Sys.glob())

# load all into one large dataframe
d <- lapply(trial_files, function(x) 
     read.csv(x,sep="\t") %>% 
     mutate(ld8=gsub(".*/(1[0-9.]+).1.trial.txt","\\1",x))
  ) %>% bind_rows

# write out
write.table(d, 'txt/anti_eye.tsv')
