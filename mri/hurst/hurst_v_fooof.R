#!/usr/bin/env Rscript

# 20230519WF - init
#   


library(dplyr)
library(ggplot2)
library(tidyr)

# all "merged" data arranged by lunaid+visitno. includes husrt and fooof
merged <- read.csv('/Volumes/Hera/Projects/7TBrainMech/scripts/txt/merged_7t.csv')

# subset example. includes spectroscopy (siPFC) but not used
d <- merged %>%
   select(lunaid,visitno,hurst.date,eeg.date,
          matches('hurst|sipfc|Exponent')) %>%
   filter(!is.na(eeg.date), !is.na(hurst.date))

# example single column to single column correlation
cor(d$eeg.Exponent_eyesOpen_LDLPFC, d$hurst.H_all7, use="complete.obs")

## all correlations
#  correlation matrix melted (longer) into hurst-foof pairs
#    (hurst-husrt + fooof-foof discard)
#
#  corr on dataframe returns nXn matrix. forced into dataframe
#  make rownames into a column, arbitrarily assign it to be hurst
#  make all melted/gathered columns fooof columns
#  filter to make the column values match their namesake
#  eeg: separate eyes open/closed and region L/R DLPFC
cor_mat <- d %>%
   select(matches('Exponent|H_all')) %>%
   cor(use="complete.obs") %>%
   as.data.frame() %>%
   mutate(`hurst`=rownames(.))

cor_long <-
   cor_mat %>%
   gather(key="fooof", value="fh_cor", -hurst) %>%
   filter(grepl('eeg',fooof),
          grepl('H_all',hurst)) %>%
   mutate(fooof=gsub('eeg.Exponent_','',fooof),
          hurst_region=gsub('hurst.H_all','', hurst)) %>%
   separate(fooof,c("eyes","eeg_region"))


# plot as points
# might be nice to have stderr or n ... but would need to rethink how reshaping is done above
ggplot(cor_long) +
   aes(y=fh_cor, x=hurst_region, color=eeg_region, shape=eyes) +
   geom_point() +
   see::theme_modern(axis.text.angle=90)
