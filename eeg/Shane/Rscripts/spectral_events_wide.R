#!/usr/bin/env Rscript
suppressPackageStartupMessages({library(dplyr); library(tidyr)})
#  L/R dlPFC Delay period gamma spectraum events (power analysis)
#  
# 20230622SM - init
# 20230622WF - tidyverse-ize. undo complete.case aggregate constraint. make wide for merge7T

# Define Functions ----
# quick shortcut for mean and sd that ignores missing values
# here so we dont have to keep passing lambda functions to mutate/summarise
na_mean <- function(x, ...) mean(x, na.rm=T, ...)
na_sd   <- function(x, ...) sd(x, na.rm=T, ...)
# outlier detection and replace with NA
# hard coding 2 sd above mean as outlier
outliers    <- function(x) abs(x - na_mean(x)) > 2*na_sd(x)
na_outliers <- function(x) ifelse(!outliers(x), x, NA)
  
  
# Load in Data Frames ----
## Channel locations ----
# POz already removed as channel from Gamma files.
# remove here too before enumarating channels (channel number used for merge)
chans_all <- read.csv('/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Shane/Results/AuditorySS/ChannelLocs.csv') %>%
   filter(labels!='POz') %>%
   mutate(urchan=1:n(),
          # only care about L and R DLFC. will filter later
          Region = case_when(
               labels %in% c("F3","F5","F7") ~ "LDLPFC",
               labels %in% c("F4","F6","F8") ~ "RDLPFC",
               .default = NA))

# subset to only the ones we care about.
# and we can ditch position columns X:Z, sph_theta:sph_radius
# will use this subset with merge to exclude now missing channels we dont care about
chans_dlpfc <- chans_all %>% filter(!is.na(Region)) %>% select(urchan, labels, Region)


## Gamma Trial Delay ----
# intial trial level analysis run in batches
gamma_dir <- "/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/"
gamma_files <- c('Gamma_allChannels_TrialLevel_Delay_3_4.csv',
                 'Gamma_allChannels_TrialLevel_Delay_additionalSubjects_20230530.csv')
gamma_all <-
    lapply(file.path(gamma_dir,gamma_files), read.csv) %>%
    bind_rows() %>%
    # chans column is urchan
    rename(urchan=Channel) %>%
    mutate(Epoch="Delay",  # files are for delay epoch only. record this in dataframe
           logGammaPower=log1p(Gamma_Trial_Power)) # 1p b/c values could be very small
# these are large files: row per trial per channel 
# dim(gamma_all)          # 3538647       8
# object.size(gamma_all)  #184030496 bytes


# filter to DLPFC Channels ----
# subset channels to just one's we care about (DLPFC)
# b/c other regions are already removed, merge will only keep DLPFC
gamma_DLPFCs <-  merge(gamma_all, chans_dlpfc, by="urchan")
# dim(gamma_DLPFCs)          # 337014     10
# object.size(gamma_DLPFCs)  # 22938576 bytes

# Outlier Detection ----
# remove outlier trial meaures within each measure for each channel
long_rmout <- gamma_DLPFCs  %>%
  pivot_longer(matches("Gamma"), names_to="measure", values_to="value") %>% 
  group_by(Subject, labels, Epoch, measure) %>%
  mutate(value=na_outliers(value)) %>%
  filter(Trial<97) %>% ungroup()

# get mean and sd, collapsing trial
long_smry <- long_rmout %>%
    group_by(Subject, Region, Epoch, measure) %>%
    summarise(mean=na_mean(value), sd=na_sd(value),
              n=length(which(!is.na(value)))) %>%
    ungroup()

# remove summary outliers (rm visits, per measure)
smry_rmout_long <- long_smry %>%
    mutate(across(c(mean,sd), na_outliers))
    # 20230623 -- separate measures. dont mean one b/c the other is an outlier
    #mutate(mean=ifelse(is.na(sd), NA, mean))

# long -> wide: column for each measure
# names like "Delay_RDLPFC_logGammaPower_mean" "Delay_LDLPFC_GammaEventDuration_sd"
smry_rmout_wide <- smry_rmout_long %>%
    select(-n) %>%
    # using _ to separate columns, so measure shouldn't have them
    mutate(measure=gsub("_","",measure)) %>%
    pivot_wider(id_cols=c("Subject"),
    names_from=c("Epoch","Region","measure"),
    values_from=c("mean","sd"),
    names_glue="{Epoch}_{Region}_{measure}_{.value}") %>%
    separate(Subject, c("lunaid","date"))

outfile <- '/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Gamma_DLPFCs_spectralEvents_wide.csv'
write.csv(smry_rmout_wide, outfile, row.names=FALSE,quote=FALSE)
