#!/usr/bin/env Rscript

# 20221111WF - init
#   read in the counts for hc placed roi within aseg hc label (after warp to hc scout)
#   combine and plot


f <- Sys.glob('/Volumes/Hera/Projects/7TBrainMech/scripts/mri/Hc/spectrum/*/FS_warp/hc_macro_coverage.txt')
d <- dplyr::bind_rows(lapply(f,read.table, header=T))

library(dplyr); library(ggplot2)
theme_set(cowplot::theme_cowplot())
d_long <- d %>%
   select(-Sub.brick) %>%
   tidyr::gather(roi,nzcnt,-File) %>%
   mutate(roi=gsub('.*_','',roi)%>%as.numeric(),
          File=stringr::str_extract(File,'\\d{5}_\\d{8}'),
          prct_in_hc=nzcnt/1000) 

ggplot(d_long) +
   aes(x=as.factor(roi), y=prct_in_hc) +
   geom_boxplot() 
