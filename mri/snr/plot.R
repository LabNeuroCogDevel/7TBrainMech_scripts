#!/usr/bin/env Rscript
library(ggplot2)
library(cowplot)
setwd('/Volumes/Hera/Projects/7TBrainMech/scripts/mri/snr/')

fd   <- read.csv("/Volumes/Hera/Projects/7TBrainMech/scripts/mri/txt/rest_fd.csv")

tsnr <- read.table("date_tsnr.txt")
names(tsnr) <- c("id", "d8", "tsnr")
tsnr$id <- as.character(tsnr$id)
tsnr$d8 <- as.character(tsnr$d8)

d<-merge(fd, ages, by=c("id", "d8"), all=T) %>% merge(tsnr, by=c("id", "d8"), all=T)
d <- d %>% dplyr::select(id,d8,fd,vscore,age,vtimestamp,tsnr) %>% unique 
write.csv(d, "/Volumes/Hera/Projects/7TBrainMech/scripts/mri/txt/fd_tsnr.csv")
 
# input file output of ../030_getfd.R
p <- ggplot(d) +
   aes(x=vtimestamp,
       y=tsnr,
       color=cut(age, breaks=c(0, 12, 15, 20, Inf)),
       shape=cut(fd, breaks=c(0, .4, Inf)),
       size=fd) +
   geom_point() +
   scale_shape_manual(values=c(15, 21)) +
   scale_color_manual(values=c("red", "orange", "green", "blue" ))
ggsave(p, file="t2_tsnr.png")

