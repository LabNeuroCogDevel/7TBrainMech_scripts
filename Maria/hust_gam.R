#!/usr/bin/env Rscript

# gam growthrate for hurst
#
# 20231204WF - init
#

library(dplyr)
library(tidyr)
library(LNCDR)
m7t <- read.csv('../txt/merged_7t.csv')

# what level of fmri preprocessing?
hurst_col_pattern <- 'hurst_brns.'
# names(m7t) %>% grep('hurst',.,value=T) %>% gsub('\\..*','.',.) %>% unique # "hurst_brns." "hurst_ns."

# subset to only the columns we care about
#  * make row per visit+roi, "value" col is husrt (ns)
#  * lunaid as factor -- otherwise model treats id as numeric
age_hurst <-
    m7t %>%
    select(lunaid, visitno, age=rest.age, matches(hurst_col_pattern)) %>% 
    pivot_longer(cols=matches(hurst_col_pattern), names_to="roi") %>%
    mutate(roi=gsub(hurst_col_pattern,'',roi),
           lunaid=as.factor(lunaid)) %>%
    separate(roi, c('hemi','roi'),1) %>%
    filter(!is.na(age), !is.na(value))

unique(age_hurst$roi)
# c("RAnteriorInsula", "LAnteriorInsula", "RPosteriorInsula", "LPosteriorInsula", 
# "RCaudate", "LCaudate", "ACC", "MPFC", "RDLPFC", "LDLPFC", "RSTS", 
# "LSTS", "RThalamus")

gam_plot <- function(d, gam_formula=value ~ s(age, k=5) + hemi + s(lunaid, bs="re")) { # + s(visitno) 
  m <- mgcv::gam(gam_formula, data=d)
  ci <- gam_growthrate(m, agevar='age', idvar='lunaid')
  gam_plots <- gam_growthrate_plot(d, m, ci, 'age', 'lunaid', yplotname = 'Hurst', draw_points = F)
  roi_name <- first(d$roi)
  main <- gam_plots$ageplot +
     annotate('text', x = 30, y = 1.75, label = roi_name, size=8, fontface = 2) +
     geom_point(data = d, aes(x = age, y = value, shape=hemi)) +
     geom_line(data = d, aes(x = age, y = value, group = interaction(lunaid, hemi)), alpha=0.2) +
     theme(legend.position = c(.9, .12),
           legend.title = element_text(size = 14),
           legend.text = element_text(size = 14),
           legend.spacing.y = unit(0, "mm"),
           legend.background = element_blank(),
           legend.box.background = element_rect(colour = "black"),
           axis.title.y = element_text(margin = margin(t = 0, r = -20, b = 0, l = 0)))
  raster <- gam_plots$tile +
     theme(axis.title.x = element_text(margin = margin(t = -20, r = 0, b = 00, l = 0)))
  gp <- gam_growthrate_plot_combine(main,raster)
}

# single
p_example <- age_hurst %>% filter(grepl('DLPFC', roi)) %>% gam_plot

#all
all_gam_plots <- split(age_hurst, age_hurst$roi) %>% lapply(gam_plot)

# LNCDR::gam_growthrate_plot_combine(all_gam_plots[[1]]$ageplot, all_gam_plots[[1]]$tile)
# all_gam_plots[[1]]$combined
