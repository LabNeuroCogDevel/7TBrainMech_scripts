#!/usr/bin/env Rscript
library(tidyr)
library(dplyr)
library(ggplot2)
theme_set(cowplot::theme_cowplot())

setwd('H:/Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis')

# LunaID,ScanDate,Trial,Delay,PositionError,DisplacementError,vgsLatency,mgsLatency,calR2
behave <- read.csv('Behavior_20200921.csv') %>% unite('Subject', LunaID, ScanDate)

inputfiles <- c('Beta/Delay3_4/Beta_Subs_data3_4.csv',
                'Alpha/Delay3_4/Alpha_Subs_data_3_4.csv',
                'Gamma/Delay3_4/Gamma_Subs_3_4.csv',
                'Theta/Delay3_4/Theta_Subs_data3_4.csv')
# headers like
#  Subject,Trial,Gamma_Trial_Power,Gamma_Event_Number,Gamma_Event_Duration
#  Subject,Trial,Alpha_Trial_Power,Alpha_Event_Number,Alpha_Event_Duration
# now
#  Subject,Trial,Trial_Power,Event_Number,Event_Duration,band"

eeg <-
   lapply(inputfiles,
          function(f){
             d <- read.csv(f) 
             # remove column identifier so all are the same
             names(d) <- gsub('(Alpha|Beta|Gamma|Theta)_','',names(d))
             # assign band to its own column (repeated for all rows of each file)
             d$band <- gsub('/.*', '', f)
             return(d)
          }) %>%
   bind_rows

# combine behave and eeg 
bXeeg <- merge(behave, eeg, by=c('Subject','Trial'))
bXeeg$logabsPositionError <- log1p(abs(bXeeg$PositionError))

# make longer.
#  {mgs,vgs}Latency and {Position,Displacemnt}Error INTO b_measure->value
# columns now
#   Subject,Trial,Delay,calR2,Trial_Power,Event_Number,Event_Duration,band,b_measure,b_value
bXe_long <- pivot_longer(bXeeg, matches('Error|Latency'), 'b_measure', values_to="b_value")

write.csv(bXe_long, 'bXe_long.csv', row.names=F, quote=F)
# bXe_long <- read.csv('bXe_long.csv')

# ggplot(bXe_long) +
#    aes(x=Event_Number, y=b_value) +
#    geom_point() +
#    stat_smooth(method="lm") +
#    facet_grid(b_measure~band, scales="free")

# summarise and andd outliers detection
subj_smry <- bXe_long %>%
   group_by(Subject, b_measure, band) %>%
   summarise(b_mean=mean(b_value),
             p_mean=mean(Trial_Power)) %>%
   # regroup to go accross subjects
   group_by(band, b_measure) %>%
   # get outliers
   mutate(n=n(),
          zscore=abs(scale(p_mean, center=T, scale=T)))

print("outliers:")
subj_smry %>% filter(zscore>2) %>% print.data.frame

subj_smry %>%
   filter(zscore<2) %>%
   ggplot() +
    aes(x=p_mean, y=b_mean) +
    geom_point() +
    stat_smooth(method="lm") +
    facet_grid(b_measure~band, scales="free")


all_models <- subj_smry %>%
   filter(zscore<2) %>%
   # use split to create a list of dataframes: item for each band/measure pair
   split(paste(.$band,.$b_measure)) %>%
   # apply linear model to each. model y=behave, x=power(eeg)
   lapply(lm, formula=b_mean~p_mean)

# get coef from model summary and pullout 2nd Pr(>|t|) == slope pvalue
# fancy way for doing below for each split
#  coef(summary(all_models[[1]]))[2,'Pr(>|t|)']

slope_pvals <-
   all_models %>%
   sapply(function(.) summary(.) %>% coef %>% `[`(2, 'Pr(>|t|)'))

# pull out only those that are better than prob threshold
p_thres <- .01
sig_slopes <- slope_pvals %>% Filter(x=., function(x) x <= p_thres)
print(sig_slopes)
