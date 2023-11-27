#!/usr/bin/env Rscript

# 20231127WF - init
#   get SES?

source('000_getQualtrics.R') # get_demog, rename_questions
load('svys.RData') # provides: svys

demog_batteries <- get_demog(svys, 'TODO: SES QUESTION')

q_to_column = list(
  "External Data Reference"="id",
  "Recorded Date"="vdate",
  "Welcome to the LNCD Survey Battery! - Your gender:"="sex",
  "Would you say that your growth in height:"="peta"
) 
demog_subset <- lapply(demog_batteries, function(d) {
  names(d) <- rename_questions(names(d), q_to_column)
  keep <- names(d) %in% unique(unname((q_to_column)))
  d[,keep] %>% mutate(across(!vdate,as.character))
})

all_demog <- demog_subset %>%
   bind_rows() %>% 
   mutate(
          vdate=format(vdate,"%Y%m%d")
          #sex=toupper(substr(sex,1,1)),
          #across(matches('tanner'), \(x) gsub('Stage ','',x) %>% as.numeric)
   )
write.csv(all_pub, 'txt/demog.csv')
