library(readxl)
library(dplyr)
library(lubridate)
system("curl -L 'https://docs.google.com/spreadsheets/d/e/2PACX-1vTBsSDjJ27hO6nOFyyyHPlLnDCms3dLWgw92dVkeue7UB4o1wZ9tMMe1Z-EA1ZM1g16pQW4HiCb62gu/pub?output=xlsx' > /tmp/7T_demog.xlsx")
snames <- excel_sheets('/tmp/7T_demog.xlsx')

# get all the HVLT sheets
HVLT <- snames %>%
    grep('HVLT',., value=T) %>%
    lapply(function(s) read_xlsx('/tmp/7T_demog.xlsx',sheet=s) %>%
                       mutate(from_sheet=s, ID=as.numeric(ID))) %>%
    Filter(function(d) nrow(d) > 0, .)

# find age and sex for all IDs in spreadsheets. 
idlist <- sapply(HVLT, '[', 'ID', simplify=T) %>% unlist %>% na.omit %>% unique %>% paste(collapse=",")
q <- sprintf("select id, sex, dob from enroll join person where id in (%s)", idlist)
demo <- LNCDR::db_query(q) %>% rename(ID=id)

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
