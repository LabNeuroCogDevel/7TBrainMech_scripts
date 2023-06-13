suppressPackageStartupMessages({
library(dplyr); library(tidyr)})
library(glue)

merged <- read.csv('txt/merged_7t.csv')
####### QC and plots
# 11823 visit 1 is duplicated
# merged %>% select(lunaid, visitno) %>% filter(duplicated(paste(lunaid,visitno)))
library(ggplot2)
dates <- merged %>%
    select(lunaid,visitno,matches("\\.date")) %>%
    pivot_longer(matches("date"), values_to="vdate", names_to="vtype") %>%
    mutate(vtype=gsub('.date','',vtype), vdate=lubridate::ymd(vdate))

p_visits <- ggplot(dates) +
    aes(x=vdate,
        y=rank(lunaid),
        shape=as.factor(visitno))+
    geom_point(aes(color=vtype))+
    geom_line(aes(group=paste(lunaid,visitno))) +
    see::theme_modern()

ggsave(p_visits, file='imgs/visit_date_waterfall.png', width=8.05,height=8.59)

cnts <- dates %>% ungroup() %>% 
    filter(!is.na(vdate)) %>%
    unique() %>%
    group_by(lunaid, visitno) %>%
    summarise(n_per_visit=n(),
              visits=paste(collapse=",", sort(vtype))) %>% group_by(visitno, visits) %>%
    tally()


p_cnts <- ggplot(cnts) +
    aes(x=visitno, y=n, fill=visits) +
    geom_bar(stat='identity',position='dodge') + 
    see::theme_modern() +
    labs(title=glue("7T from {min(dates$vdate,na.rm=T)} - {max(dates$vdate,na.rm=T)}"))

ggsave(p_cnts, file='imgs/visit_type_counts.png', width=8.05,height=8.59)
