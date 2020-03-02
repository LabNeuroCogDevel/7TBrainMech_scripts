#!/usr/bin/env Rscript
#
# 20200302 WF -- use db to collect ids

library(LNCDR)
# visits from DB - ranked by time of day
v <- db_query("
  select id, vtimestamp, date(vtimestamp) as vdate, pid
  from visit natural join visit_study natural join enroll
  where etype like 'LunaID' and study ilike '%Brain%' and vtype ilike '%scan%'"
 ) %>%
 # remove duplicate lunaids ([1495] 11665==11467 & [1380] 11748==11515 & [1346] 11653==11467) by picking the larger id
 group_by(vdate, pid) %>% mutate(idrank=rank(id)) %>% filter(idrank==max(idrank)) %>% select(-idrank) %>%
 group_by(vdate) %>%
 mutate(vnum=rank(vtimestamp))


### 
# raw folders that look like Luna scans
rawdirs <- Sys.glob("/Volumes/Hera/Raw/MRprojects/7TBrainMech/2*Luna*") %>%
   grep(pattern="bad|Crashed|noshow", invert=T,  perl=T, value=T)

# extract info
d <-
    data.frame(d=rawdirs,stringsAsFactors=FALSE ) %>%
    mutate(b=basename(d),
           id=stringr::str_extract(b, "^(\\d{8})Luna([1-4]?)" ) %>%
        gsub("Luna","_", .) %>%
        gsub("_$","_1", .)) %>%
    tidyr::separate(id,c("vstr","vnum")) %>%
    mutate(vdate = lubridate::ymd(vstr))

h <- read.table("id_fixes.tsv")
names(h) <- c("b","hID")
d <- merge(d, h, by="b", all.x=T)
       
# stop if we cannot parse date
nbad <- length(which(is.na(d$vdate)))
if (nbad > 0L) stop("have ", nbad, " fail to date parse: ", d[is.na(d$vdate),])

# get db and filesystem together
m <- merge(d, v, by=c('vdate','vnum'), all=T) %>%
    mutate(id=ifelse(is.na(id),gsub("_.*", "", hID),id))

# concerns:
# any date that has an NA for id could be misassigned
issue_date <- unique(m$vdate[is.na(m$id)|is.na(m$d)])
warning("issue with ", length(issue_date)," dates: ", paste(collapse=",", issue_date))

i <- m %>% filter(vdate %in% issue_date) %>% select(b,hID,id,vdate,vnum)
ii <- i %>% filter(!is.na(d))
