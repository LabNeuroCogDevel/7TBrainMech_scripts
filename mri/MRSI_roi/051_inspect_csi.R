#!/usr/bin/env Rscript
suppressPackageStartupMessages({
 library(dplyr)
 library(tidyr)
 library(stringr)
 library(ggplot2)
 library(cowplot)})
theme_set(theme_cowplot())

d <- read.csv('txt/13MP20200207_LCMv2fixidx.csv')

CrSD <- d %>% select(age, ld8, label,matches('\\.Cr|\\.SD')) %>% tidyr::gather(metabolite,ratio, -age,-ld8, -label) %>% separate(metabolite,c('metabolite','measure'),extra='merge') %>% filter(measure %in% c('SD','Cr'),!is.na(label)) %>% spread(measure,ratio)  %>% mutate(year=str_extract(ld8,'(?<=_)\\d{4}'))


plot_data <- CrSD %>% filter(Cr<5, SD<20, !metabolite %in% c('Cr')) %>% 
   group_by(metabolite) %>%
   mutate(zscore=scale(Cr,center=T)) %>%
   ungroup;

n_year <- plot_data%>% group_by(year)%>% summarise(n=length(unique(ld8)))%>%with(paste(n,year,sep="_"))
plot_data$nMRSI_year <- factor(plot_data$year,labels=n_year)

p_bymet <- plot_data %>%
  filter(abs(zscore)<2) %>%
  ggplot() +
  aes(x=nMRSI_year,y=Cr) +
  geom_boxplot() +
  facet_wrap(~metabolite, scales="free_y") +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)) +
  ylab('Cr ratio') +
  ggtitle('metabolites collapsed across ROI')

p_byroi <- plot_data %>% filter(abs(zscore)<2, metabolite=='Glu') %>%
  ggplot()+
  aes(y=Cr, x=nMRSI_year) +
  geom_boxplot() +
  facet_wrap(~label) +
  ylab('Glu/Cr') +
  ggtitle('Glu over years by ROI')+
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))

p <- plot_grid(p_byroi, p_bymet, ncol=2)
ggsave(p, file="txt/CSI_over_years.png")
cat("see: feh txt/CSI_over_years.png\n")
