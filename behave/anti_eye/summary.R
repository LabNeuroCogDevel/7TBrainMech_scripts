#!/usr/bin/env Rscript
suppressPackageStartupMessages({
library(dplyr)   # %>%, inner_join
library(stringr) # str_extract
library(LNCDR)   # db_query
})


cat("# query DB for all 7T visits (scan, behave, eeg)\n")
all_7T <- db_query("select lunaid,ymd,sex,age from visits_view where studies::text like '%BrainMech%'")
nrow(all_7T)


cat("# query Anti eyetracking files matching 7T id/date on network mount (bea_res)\n")
ETroot <- '/Volumes/L/bea_res/Data/Tasks/Anti/Basic'
ETscore <- 'Scored/txt/*.summary.txt'
all_combos <- file.path(ETroot, all_7T$lunaid, all_7T$ymd, ETscore)
anti_7T <- Sys.glob(all_combos)
length(anti_7T) # 20210302: 223


# 20221127 - why are there two locations!? almost exactly overlapping.
# but want the few that are missing
cat("# searching second location\n")
all_combos_alt <- file.path('/Volumes/L/bea_res/Data/Tasks/Anti7TASL/', all_7T$lunaid, all_7T$ymd, ETscore)
anti_7T_alt <- Sys.glob(all_combos_alt)
cat("# found ", length(anti_7T)) # 20221127: 322. same as above
## almost identical. 
missing_df <-
   merge(
         data.frame(f=anti_7T)    %>%mutate(b=basename(f)),
         data.frame(f=anti_7T_alt)%>%mutate(b=basename(f)),
         by="b",
         all=T,
         suffixes=c(".Anti",".7T")) %>%
   filter(is.na(f.Anti)|is.na(f.7T))

missing_df %>% mutate(across(matches("^f"),is.na)) %>% print
#                               b f.Anti  f.7T
# 1  11561.20220913.1.summary.txt   TRUE FALSE
# 2  11765.20220928.1.summary.txt   TRUE FALSE
# 3  11770.20220914.1.summary.txt   TRUE FALSE
# 4  11771.20190403.1.summary.txt  FALSE  TRUE
# 5  11772.20190408.1.summary.txt  FALSE  TRUE
# 6  11773.20190410.1.summary.txt  FALSE  TRUE
# 7  11786.20210310.1.summary.txt  FALSE  TRUE
# 8  11793.20220830.1.summary.txt   TRUE FALSE
# 9  11809.20191024.1.summary.txt  FALSE  TRUE
# 10 11810.20220907.1.summary.txt   TRUE FALSE
# 11 11898.20221027.1.summary.txt   TRUE FALSE
anti_7T <- unique(c(anti_7T,missing_df$f.7T[!is.na(missing_df$f.7T)]))


cat("# reading all ET summary files\n")
read_eye <- function(f) read.table(f, header=T) %>% select(matches('AS|Drop|total|subj|date|run'))
anti_7T_smry <- lapply(anti_7T, read_eye) %>%
   bind_rows %>%
   relocate(subj,date,run) # with these columns first (instead of last)
nrow(anti_7T_smry)

saveas <- 'anti_7t.csv'
cat("# saving", saveas, "\n")
write.csv(anti_7T_smry, saveas, row.names=F)
