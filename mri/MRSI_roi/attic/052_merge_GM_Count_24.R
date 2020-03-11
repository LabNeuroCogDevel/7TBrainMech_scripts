#!/usr/bin/env Rscript

# 20191202 WF - copy 040_fetchFiles.bash  and 052_merge_GM_Count.R 
#               format of pos_* file changes b/c using coord_rearrange


library(dplyr)
library(stringr)
library(tidyr)

dversion<-"24specs_20191102"

# roi name and roi number
roi_names <-
   read.table("txt/labels_ROI_mni_MP_20191022.txt", sep=":") %>% 
   rename(roi_label=V1) %>%
   select(-V2) %>%
    mutate(roi_num=1:n(),
           roi_label=gsub('\\(dm ?\\?\\) ?','', roi_label))

# per coord csv
roi_subj_val <- 
   read.csv(sprintf('txt/LCModel_vals_%s.csv', dversion)) %>%
   mutate( ids=str_extract(File, "\\d{5}_\\d{8}-[^/]+"),
          coord=str_extract(File, "(?<=spectrum\\.)[0-9.]+")) %>%
   separate(ids, c("ld8", "mrid"), sep="-", extra="merge") %>%
   separate(coord, c("row", "col"), extra="drop") %>%
   mutate(row=as.numeric(row),col=as.numeric(col))

# 65	73	50  1 xxxx_yyyyyy fffffffffffff
roi_subj_pos <-
   read.table(sprintf("txt/pos_%s.txt", dversion)) %>%
   `names<-`(c("x", "y", "z", "roi_num", "ld8", "specfile"))

subj_val_pos_label <-
   inner_join(roi_subj_val, roi_subj_pos,
              by=c("col"="x", "row"="y", "ld8"="ld8"),
              suffix=c(".val",".pos")) %>%
   inner_join(.,roi_names, by="roi_num") 

# txt/subj_label_val_24specs_20191102.csv
write.csv(subj_val_pos_label, sprintf("txt/subj_label_val_%s.csv", dversion))


# read in output of ./051_GM_Count_24.bash
GM <- read.table(pipe('cat /Volumes/Hera/Projects/7TBrainMech/subjs/*/slice_PFC/MRSI_roi/spectrum/percent_cnt_ROI_mni_MP_20191022.txt'))
names(GM) <- c("ld8", "ver", "roi_num", "FSfracGM", "nvoxel")

# combine together
subj_val_pos_label_gm <- merge(subj_val_pos_label, GM, by=c("ld8", "roi_num"))
write.csv(subj_val_pos_label_gm, sprintf("txt/subj_label_val_gm_%s.csv", dversion))
# txt/subj_label_val_gm_24specs_20191102.csv
