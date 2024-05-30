#!/usr/bin/env Rscript
library(dplyr); library(tidyr)

#   calculate asymmetry and ratio between GABA and Glu 
#   using GAM adjusted MRSI metabolite concentrations (GM and date residulaized LCModel)
#   expected to be used by ../merge7T.R
#
#
# 20240530WF - init with input from FC, AP, MP

# MP: abs(resids(lm(data=merge7t, gaba~glu))) 
gaba_glu_asymmetry <- function(merged) {
   # make very long dataframe: row per metabolte+roi+visit
   #  lunaid visitno name                          value
   #  10129        1 sipfc.RAntInsula_GABA_gamadj  0.321
   #  10129        1 sipfc.LAntInsula_GABA_gamadj  0.433
   #  10129        1 sipfc.RAntInsula_Glu_gamadj   1.29 
   long_roi_met <- merged %>%
      select(lunaid,visitno,matches('sipfc.*(GABA|Glu)_gamadj')) %>%
      pivot_longer(cols=matches("gamadj"))

   # match same visit+roi so value column becomes GABA or Glu
   #  lunaid visitno roi         GABA   Glu  ...
   #  10129        1 RAntInsula 0.321  1.29  ...
   #  10129        1 LAntInsula 0.433  1.56  ...
   long_roi <- long_roi_met %>%
      separate(name, c('method','roi','met','gamadj')) %>%
      pivot_wider(names_from='met',values_from=value)

   # calculate asymmetry and ratio 
   # NB. gamadj should already be %GM residualized
   asym_ratio <- long_roi %>%
      group_by(roi) %>%
      mutate(Asym=abs(residuals(lm(Glu~GABA,na.action=na.exclude))),
             Ratio=Glu/GABA)

   # put back in ultra wide format for merging back into merge7t
   # one row for each visit. new columns are like
   #    sipfc.Thalamus_GabaGlu_Asym, sipfc.RAntInsula_GabaGlu_Ratio, ..
   wide_visit <- asym_ratio %>% ungroup %>%
      transmute(lunaid,visitno, Asym, Ratio,
                newprefix=paste0(method,".",roi,"_GluGaba")) %>%
      pivot_wider(id_cols=c("lunaid","visitno"),
                  names_from=c("newprefix"),
                  values_from=c("Asym","Ratio"),
                  names_glue="{newprefix}_{.value}")
}
