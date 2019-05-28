#!/usr/bin/env Rscript
# collect all FD from rest preprocess (see ./010_preproc.bash)

library(stringr)
library(magrittr)

ages <- LNCDR::db_query("
  select * from visit
  natural join visit_study
  natural join enroll
  where etype like 'LunaID'
   and vtype like '%can'
   and study like 'BrainMechR01'")
ages$d8 <- format(ages$vtimestamp, "%Y%m%d")

f <- Sys.glob("/Volumes/Zeus/preproc/7TBrainMech_rest/MHRest_nost_ica/1*_2*/motion*/fd.txt")
fd <- sapply(f, function(x) mean(read.table(x)[, "V1"]))
fd <-
   data.frame(ld8=str_extract(f, "\\d{5}_\\d{8}"),
              fd=fd %>% unname) %>%
   tidyr::separate(ld8, c("id", "d8"))

write.table(fd, "/Volumes/Hera/Projects/7TBrainMech/scripts/mri/txt/rest_fd.csv", row.names=F, quote=F)
