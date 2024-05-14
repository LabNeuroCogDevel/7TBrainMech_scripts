library(dplyr)
library(tidyr)
library(ggplot2)
rois <- c("1_RAntInsula", "2_LAntInsula", "3_RPostInsula", "4_LPostInsula", "5_RCaudate", "6_LCaudate", "7_ACC", "8_MPFC", "9_RDLPFC", "10_LDLPFC", "11_RSTS", "12_LSTS", "13_RThal")
low <- read.table('ts/atlas-MP13GM_prefix-brnasw/11786_20190830.1D', col.names=rois) %>% mutate(tp=1:n(),annote="low",ld8="11786_20190830") %>% gather("roi","value",-tp, -annote, -ld8)  
high <- read.table('ts/atlas-MP13GM_prefix-brnasw/11641_20180510.1D', col.names=rois) %>% mutate(tp=1:n(),annote="high",ld8="11641_20180510") %>% gather("roi","value",-tp, -annote, -ld8)  


to_plot <- rbind(low,high) %>%
   filter(grepl("DLPFC",roi)) %>%
   mutate(roi=gsub('.*_','',roi),
          zscore_all=scale(value,center=T))  %>%
   group_by(ld8,annote,roi) %>%
   mutate(zscore_roivisit=scale(value,center=T))


hurst_in_r <- to_plot %>%
   group_by(ld8,annote,roi) %>%
   summarise(hurstr=pracma::hurstexp(value,display=F)$Hrs,
             hurst_zwithin=pracma::hurstexp(zscore_roivisit,display=F)$Hrs,
             hurst_zall=pracma::hurstexp(zscore_all,display=F)$Hrs)

ggplot(to_plot) + aes(x=tp, y=value, color=annote,linetype=roi) + geom_line() + see::theme_modern() +
   labs(x="time point",
        y=expression(BOLD[1000/median]),
        linetype="ROI", color="Hurst Value")


# zcore
ggplot(to_plot) +
   aes(x=tp, y=zscore_all,
       color=annote,linetype=roi) + geom_line() + see::theme_modern() +
   labs(x="time point",
        y="zscore", title="zscored across all bold",
        linetype="ROI", color="Hurst Value")

ggplot(to_plot) +
   aes(x=tp, y=zscore_roivisit,
       color=annote,linetype=roi) +
   geom_line() + see::theme_modern() +
   labs(x="time point",
        y="zscore within roi visit",
        title="zscored bold with visit+roi",
        linetype="ROI", color="Hurst Value")




read_ts <- function(ld8){
   read.table(paste0('/Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_nowarp/',ld8,'/mrsipfc13_nzmean_ts.1D'),
           col.names=rois) %>%
   mutate(tp=1:n(), ld8=ld8) %>%
   gather("roi","value",-tp, -ld8)  
}

hurst_values <-
   read.csv('stats/MRSI_pfc13_H.csv') %>%
   select(ld8,matches('DLPFC')) %>%
   gather("roi","hurst_ml",-ld8)

ts_data <- lapply(c('11786_20190830','11641_20180510'),read_ts) %>%
   bind_rows %>%
   mutate(roi=gsub('.*_','',roi),
          zscore_all=scale(value,center=T))  %>%
   group_by(ld8,roi) %>%
   mutate(zscore_roivisit=scale(value,center=T)) %>%
   merge(hurst_values, by=c("ld8","roi")) %>%
   arrange(ld8,roi,hurst_ml,tp)

hurst_in_r <- ts_data %>%
   group_by(ld8,roi) %>%
   summarise(hurst_r=pracma::hurstexp(value,display=F)$Hrs,
             hurst_rzwithin=pracma::hurstexp(zscore_roivisit,display=F)$Hrs,
             hurst_rzall=pracma::hurstexp(zscore_all,display=F)$Hrs)

to_plot2 <- merge(ts_data, hurst_in_r, by=c("ld8","roi"))

ggplot(to_plot2) +
   aes(x=tp, y=value, linetype=roi,
       color=paste(ld8, round(hurst_ml,2),round(hurst_r,2))) + geom_line() + see::theme_modern() +
   labs(x="time point",
        y=expression(BOLD[1000/median]),
        linetype="ROI", color="Hurst Value (ml, r)",
        title="hurst for nowarp mrsipfc13_nzmean_ts")

ggplot(to_plot2 %>% filter(roi=="RDLPFC")) +
   aes(x=tp, y=zscore_roivisit,
       color=paste(ld8, round(hurst_ml,2),round(hurst_r,2))) +
       geom_line() + see::theme_modern() +
   labs(x="time point",
        y="within roi zscore",
        linetype="ROI", color="Hurst Value (ml, r)",
        title="zscored ts; hurst for nowarp mrsipfc13_nzmean_ts")
