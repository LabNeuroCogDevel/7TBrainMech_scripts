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
   filter(!is.na(nzcnt)) %>%
   group_by(roi) %>%
   filter(n()>2) %>%
   ungroup %>% group_by(File) %>% filter(sum(nzcnt)> 2) %>%
   mutate(roi=gsub('.*_','',roi)%>%as.numeric(),
          File=stringr::str_extract(File,'\\d{5}_\\d{8}'),
          in_hc=nzcnt/1000) 

ggplot(d_long) +
   aes(x=in_hc) +
   geom_histogram()# +
   #geom_text(data=group_by(d_long,roi) %>% summarise(n=n()),
   #           y=1,
   #           aes(label=n)) +
   #labs(title="per ROI Hc coverage",
   #     x="ROI Num (per visit, not paired)",
   #     y="Ratio of 3dUnDump in Hc aseg label")

d_long %>%
 group_by(File) %>%
 summarise(visit_avg_roi_cov=round(sum(nzcnt)/n(),0),
           mncov=min(nzcnt),mxcov=max(nzcnt),
           n0=length(which(nzcnt==0)),n=n()) %>%
 print.data.frame(row.names=F)
 #%>% clipr::write_clip()
