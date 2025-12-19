#!/usr/bin/env Rscript

# 20200724WF - init
# 20251219WF - revisit with final packet
#   
# turn 'txt/7TBrainMechR01_packet_fetched20251219WF.xlsx'
# into txt/HVLT/HVLTY{1,2}_1{A,B}_Part{A,B}.csv


library(readxl)
library(dplyr)
library(lubridate)

write_csv_files <- function() {
  #system("curl -L 'https://docs.google.com/spreadsheets/d/e/2PACX-1vTBsSDjJ27hO6nOFyyyHPlLnDCms3dLWgw92dVkeue7UB4o1wZ9tMMe1Z-EA1ZM1g16pQW4HiCb62gu/pub?output=xlsx' > /tmp/7T_demog.xlsx")
  xlsx_name <- 'txt/7TBrainMechR01_packet_fetched20251219WF.xlsx'
  snames <- excel_sheets(xlsx_name)
  
  # get all the HVLT sheets
  HVLT <- snames %>%
      grep('HVLT',., value=T) %>%
      lapply(function(s) read_xlsx(xlsx_name, sheet=s) %>%
                         mutate(from_sheet=s, ID=as.numeric(ID))) %>%
      Filter(function(d) nrow(d) > 0, .)
  
  # find age and sex for all IDs in spreadsheets. 
  idlist <- sapply(HVLT, '[', 'ID', simplify=T) %>% unlist %>% na.omit %>% unique %>% as.numeric
  #q <- sprintf("select id, sex, dob from enroll join person where id in (%s)", idlist %>% paste(collapse=","))
  q <- "select id as ID, sex, dob from enroll natural join person where etype like 'LunaID'"
  demo <- LNCDR::db_query(q) |> rename(ID=id) |> filter(ID %in% idlist)

  # everyone should be in DB
  testthat::expect_equal(nrow(demo), length(idlist))
  
  # write out individual sheets
  if(!dir.exist("txt/HVLT")) dir.create("txt/HVLT")
  lapply(HVLT,function(d) {
      out <- sprintf("txt/HVLT/%s.csv", d$from_sheet[1])
      # add demographic (sex+age)
      merge(demo, d, by="ID", all.y=T) %>%
       # use dob to calc age
       mutate(age=as.numeric(ymd(Date) - ymd(dob))/365.25) %>%
       # remove potentially identifying info
       select(-Date,-dob) %>%
       # save out
       write.csv(out, row.names=F)
  })
}

write_csv_files()
