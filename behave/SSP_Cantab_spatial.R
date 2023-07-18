library(dplyr)
library(tidyr)

# CANTAB Spatial Task
## all trials
ssp_list <- Sys.glob('/Volumes/L/bea_res/Data/Temporary Raw Data/7T/1*_2*/*SSP.csv')
ssp_trials <- lapply(ssp_list,
                     function(f) read.csv(f, na.strings="") |> mutate(file=f)) |>
   dplyr::bind_rows() |>
   mutate(ld8=LNCDR::ld8from(file)) |>
   select(-file, -X)

# first trial of block gets span.passed=yes/no
SSP_sl <- ssp_trials %>% group_by(ld8) %>%
   filter(span.passed=="yes") %>%
   summarise(maxspan=max(as.numeric(span),na.rm=T))

# number of erros should not include the first 2 practice (assessed="no")
# only first trial of a block is labeled assessed=yes/no: fill down
# otherwise count all not correct ("invalid box", "wrong order")
SSP_ne <- ssp_trials %>% group_by(ld8) %>%
   fill(assessed, .direction="down") %>%
   filter(!is.na(presentation.order), assessed=="yes") %>%
   summarise(nerrors=length(which(choice.type!="correct")),
             ntrials=n())

SSP <- merge(SSP_sl,SSP_ne, by="ld8", all=T)
write.csv(SSP,'txt/SSP.csv',row.names=F, quote=F)



######
# summary export has 24 visits (and of those 1 has NAs and 2 id=9999)
# used to check scoring from above
cantab <- read.csv('/Volumes/L/bea_res/Data/CantabArchives/7T_lunaAdult_20210304.csv')
SSP_smry <- cantab %>%
   mutate(ld8=paste0(Subject.ID,'_',
                     format(lubridate::mdy_hms(Session.start.time),
                            "%Y%m%d"))) %>%
   select(ld8,SSP.Span.length,SSP.Total.errors)

check <- merge(SSP_smry,SSP, by='ld8') %>%
   mutate(spdif=SSP.Span.length-maxspan,
          ed=SSP.Total.errors-n.errors)
