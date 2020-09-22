#!/usr/bin/env Rscript
library(tidyr)
library(dplyr)
library(ggplot2)
theme_set(cowplot::theme_cowplot())

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

# make longer.
#  {mgs,vgs}Latency and {Position,Displacemnt}Error INTO b_measure->value
# columns now
#   Subject,Trial,Delay,calR2,Trial_Power,Event_Number,Event_Duration,band,b_measure,b_value
bXe_long <- pivot_longer(bXeeg, matches('Error|Latency'), 'b_measure', values_to="b_value")

ggplot(bXe_long) +
   aes(x=Event_Number, y=b_value) +
   geom_point() +
   stat_smooth(method="lm") +
   facet_grid(b_measure~band, scales="free")
