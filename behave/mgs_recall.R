#!/usr/bin/env Rscript

#
# recall preformance
#

# use file name to attach id visittype and image set to recall csv
read_recall <- function(f) 
   read.csv(f) %>%
      mutate(
       ld8=stringr::str_extract(f,"\\d{5}_\\d{8}"),
       vtype=stringr::str_extract(f,"mri|eeg"),
       img_set=stringr::str_extract(f,"(?<=recall-)[A-Z]")
      )

# read in all we can find
d <- 
  "/Volumes/L/bea_res/Data/Tasks/MGSEncMem/*/1*_20*/*/*mgsenc*/*_recall-*.csv" %>%
  Sys.glob() %>%
  lapply(read_recall) %>%
  do.call(rbind,.)

# write out all recall
if (!dir.exists("txt")) dir.create("txt")
write.csv(d,"txt/all_recall.csv")

# some summary
d %>% group_by(ld8,score) %>% tally %>% tidyr::spread(score,n)

# ---- scores ----
# -- didn't see
# 1   = said saw (but didn't)
# 101 = said maybe didn't
# 201 = confidently correct
# --- did see
# 0 = said didn't
# 100 = maybe known
# 200 = confidently correct
# -- side
# +5  = correct side    (105, 205)
# +15 = exactly correct (115,215)

#
# for everyone else
d$s <- as.factor(d$score)
levels(d$s) <- c("1"="FP_MIA","101"="N_MIA","201"="TP_MIA",
               "0"="FP_saw","100"="N_saw","200"="TP_saw",
               "105"="N_saw_side", "115"="N_saw_exact",
               "205"="TP_saw_side","215"="TP_saw_exact")

sm <- 
   d %>%
   group_by(ld8,vtype,img_set) %>%
   summarize(FP=length(grep("FP", s)),
             maybe=length(grep("^N_saw", s)),
             maybe_side=length(grep("N_saw_", s)),
             maybe_exact=length(grep("N_saw_exact", s)),
             TP=length(grep("TP", s)),
             TP_side=length(grep("TP_saw_", s)),
             TP_exact=length(grep("TP_saw_exact", s)),
             n=n())
write.csv(sm,"txt/all_recall_summary.csv")
