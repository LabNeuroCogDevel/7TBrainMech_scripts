#!/usr/bin/env Rscript
pacman::p_load(dplyr,tidyr,readr)
d <- read_delim(Sys.glob('/Volumes/Hera/Projects/7TBrainMech/subjs/*/slice_PFC/MRSI_roi/ThalRedo/gm*/gm_count.txt'),
           delim="\t",
           col_names=c("info","gm","nvox")) |>
    separate(info,c("lunaid","vdate","roi","roival")) |>
    mutate(atlas="ThalRedo")

# lunaid,vdate,roi,roival,gm,nvox,atlas
write.csv(d,file="ThalRedo_gm.csv",row.names=F,quote=F)
