#!/usr/bin/env Rscript

# 20230620WF - init
#   use pull from sheets

d.json <- LNCDR::db_query("
  select id,vid, measures from visit_task natural
  join visit
  natural join visit_study
  join enroll on visit.pid=enroll.pid and etype like 'LunaID'
  where task like 'SR' and study like 'BrainMechR01'")

d.long <- LNCDR::unnestjson(d.json)
d <- d.long |> dplyr::select(lunaid=id,
                  date.screening=ScreeningDate,
                  visitno=VisitYear,
                  dplyr::matches("_T$"))

if(any(grepl('stdout', commandArgs(trailingOnly=T)))){
   outfile <- stdout()
} else {
   outfile <- 'txt/SR.csv'
}
write.csv(d, outfile, row.names=F, quote=F)
