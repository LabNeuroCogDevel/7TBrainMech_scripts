#!/usr/bin/env Rscript

# 20190503 WF - merge victor LC Model spreadsheet.csv outputs with roi coordinates
#               uses output of 040_fetchFiles.bash

library(dplyr)
library(stringr)
library(tidyr)

dversion=20190503

#Right Middle Occipital Gyrus: 44.5844 -54.4972 -13.3093 1
roi_names <-
   read.table("mkcoords/mni_coords_MPOR_20190425_labeled.txt", sep=":") %>% 
   `names<-`(c("roi_label", "mni_coords")) %>%
   mutate(roi_num=gsub(".* ", " ", mni_coords) %>% as.numeric)

# Row, Col, Asp, Asp %SD, Asp/Cre, Cho, Cho %SD, Cho/Cre, Cre, Cre %SD, Cre/Cre, GABA, GABA %SD, GABA/Cre, Glc, Glc %SD, Glc/Cre, Gln, Gln %SD, Gln/Cre, Glu, Glu %SD, Glu/Cre, GPC, GPC %SD, GPC/Cre, GSH, GSH %SD, GSH/Cre, mI, mI %SD, mI/Cre, NAA, NAA %SD, NAA/Cre, NAAG, NAAG %SD, NAAG/Cre, Tau, Tau %SD, Tau/Cre, -CrCH2, -CrCH2 %SD, -CrCH2/Cre, GPC+Cho, GPC+Cho %SD, GPC+Cho/Cre, NAA+NAAG, NAA+NAAG %SD, NAA+NAAG/Cre, Glu+Gln, Glu+Gln %SD, Glu+Gln/Cre, MM20, MM20 %SD, MM20/Cre, File
# File like spectrum_out_processed/11323_20180316-20180316Luna1/spectrum.64.69.dir/spreadsheet.csv
roi_subj_val <- 
   read.csv(sprintf('txt/LCModel_vals_%s.csv', dversion)) %>%
   mutate( ids=str_extract(File, "\\d{5}_\\d{8}-[^/]+"),
          coord=str_extract(File, "(?<=spectrum\\.)[0-9.]+")) %>%
   separate(ids, c("ld8", "mrid"), sep="-", extra="merge") %>%
   separate(coord, c("row", "col"), extra="drop") %>%
   mutate(row=as.numeric(row),col=as.numeric(col))

# 1	65	73	50  slice_roi_MPOR20190425_CM_10129_20180917_16_737548.447734_MP.txt
roi_subj_pos <-
   read.table(sprintf("txt/pos_%s.txt", dversion)) %>%
   `names<-`(c("roi_num", "x", "y", "z", "File")) %>%
   mutate(ld8=str_extract(File, "\\d{5}_\\d{8}"))

subj_val_pos_label <-
   inner_join(roi_subj_val, roi_subj_pos,
              by=c("col"="x", "row"="y", "ld8"="ld8"),
              suffix=c(".val",".pos")) %>%
   inner_join(.,roi_names, by="roi_num") %>%
   filter(!grepl("WF", File.pos)) %>%
   filter(!grepl("slice_roi_MPOR20190425_CM_11689_20181029_16_737545.588901_MP.txt", File.pos))

write.csv(subj_val_pos_label, sprintf("txt/subj_label_val_%s.csv", dversion))
# # still some weirdness with any subject that had more than one
# # check on any weirdo repeats
# subj_val_pos_label %>% group_by(ld8,roi_label) %>% 
#    mutate(n=n()) %>% filter(n!=1) %>%
#    select(row,col,File.pos) %>% print.data.frame()
