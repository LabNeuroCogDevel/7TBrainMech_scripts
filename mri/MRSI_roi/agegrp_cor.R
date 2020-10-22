#!/usr/bin/env Rscript
library(dplyr)
library(tidyr)
#library(corrr) # correlate, stretch. need R>3.6

rois <- c('L.DLPFC', 'R.DLPFC')
age_breaks <- c(0,15,19,23,Inf)

long<- read.csv('/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI_roi/txt/13MP20200207_LCMv2fixidx.csv') %>%
    select(ld8, age, label, Glu.Cr, GABA.Cr) %>%
    mutate(label=gsub(' +','.',label)) %>%
    filter(label %in% rois) %>%
    mutate(agegrp=cut(age, breaks=age_breaks)) %>%
    pivot_longer(Glu.Cr:GABA.Cr, names_to='metabolite') %>%
    unite('met_lab', metabolite, label)
    
all_cors <- long %>%
    split(.$agegrp) %>% lapply(function(d){
    cormat <- d %>%
        select(ld8,met_lab,value) %>%
        pivot_wider(id_cols=ld8,names_from=met_lab) %>%
        select(-ld8) %>% cor(use="complete.obs") %>%
        # correlate %>% stretch
        #correlate(use="complete.obs") %>% stretch
        data.frame(.,rownames=rownames(.)) %>%
        reshape2::melt() %>%
        mutate_at(c('rownames','variable'),as.character) %>%
        mutate(x=pmax(rownames,variable),
               y=pmax(rownames,variable)) %>%
        select(-rownames, -variable) %>%
        filter(value!=1) %>%
        unique %>%
        # break apart labels again
        separate(x, c('metabolite_x', 'label_x'), sep="_") %>%
        separate(y, c('metabolite_y', 'label_y'), sep="_")

    cormat$agegrp <- first(d$agegrp)
    return(cormat)}) %>%
    bind_rows
