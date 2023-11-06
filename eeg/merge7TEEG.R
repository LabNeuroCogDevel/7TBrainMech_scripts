library(tidyr)
library(dplyr)

#load in channel info
chanLocs <- read.csv('/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Shane/resources/ChannelLocs.csv')
chanRegion <- read.csv('/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Shane/resources/channel_brainRegion_table.csv')

SNR <- read.csv('/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Shane/Results/SNR/allSubjectsSNR.csv') %>% merge(., chanLocs, by ="urchan") %>% select(-type, -urchan)

spectral<- read.csv('/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Shane/Results/Spectral_Analysis/Spectral_events_analysis/allChannels_averagedOverTrials.csv')
spectralPivot <- pivot_wider(spectral %>% select(-X, -age, -inverseAge, -visitno), values_from = matches("Gamma"), names_from="Epoch")

fooof <- read.csv('/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Shane/Results/FOOOF/allSubjectsAllChannelsFooofMeasures_20230911.csv') %>% select(-X)
names(fooof)[names(fooof) == "Channel"] <- "labels"
fooofPivot <- pivot_wider(fooof, values_from = c("Offset", "Exponent"), names_from="Condition")


merge7tEEG <- merge(SNR, spectralPivot, by = c("Subject", "labels"), all = T) %>% merge(., fooofPivot, by = c("Subject", "labels"), all = T)
