library(dplyr)
library(tidyr)
library(tidyverse)
library(lubridate)
library(ggplot2)
library(LNCDR)
library(car)
library(lme4)

csi_roi_gmmax_values<-read.table("/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI/csi_roi_gmmax_values_2.txt")
names(csi_roi_gmmax_values) <-c("Subject","DOB","Gender", "ROI","measure", "value" )
csi_roi_gmmax_values<-spread(csi_roi_gmmax_values, measure, value)
rois<-c('L MFG','R MFG','L dlPFC','R dlPFC','mPFC','ACC','Thal','L Insula','R Insula','L postIT','R postIT')

# split up the ID to calculate the age 
#splitID_csi_roi_gmmax_values<-csi_roi_gmmax_values %>% separate(Subject,c("id","vdate")) %>% 
#  mutate(vdate=ymd(vdate), DOB = ymd(DOB), age = round((vdate - DOB)/365.25), digits=2)
splitID_csi_roi_gmmax_values<-csi_roi_gmmax_values %>% separate(Subject,c("id","vdate")) %>% 
  mutate(vdate=ymd(vdate), DOB = ymd(DOB), age = (vdate - DOB)/365.25)

d<-splitID_csi_roi_gmmax_values[splitID_csi_roi_gmmax_values$GABA_SD<20 & splitID_csi_roi_gmmax_values$GABA_SD>0 & splitID_csi_roi_gmmax_values$ROI<12,]
d$ROI<-as.factor(d$ROI)

d$GABA_SD <- d$GABA_SD + sample(seq(from=-.2,to=.2, length.out=length(d$GABA_SD)))

gp<-lunaize(
	ggplot(data=d, 
		aes(x=age, y=GABA_SD, color=ROI)) + 
		geom_point() + 
	  scale_color_manual(labels = rois, values = seq(1,11)) +
	  labs(x = "Age", y="CRLB (%sd)") +
		stat_smooth(aes(color=NULL), method=glm)
) +           theme(rect = element_rect(fill = "transparent"),
                    panel.background = element_rect(fill = "transparent"), # bg of the panel
                    plot.background = element_rect(fill = "transparent", color = NA), # bg of the plot
                    panel.grid.major = element_blank(), # get rid of major grid
#                    panel.grid.minor = element_blank(), # get rid of minor grid
                    legend.background = element_rect(fill = "transparent"), # get rid of legend bg
                    legend.key = element_rect(fill = "transparent", colour = NA), # get rid of key legend fill, and of the surrounding
                    axis.line = element_line(colour = "black") # adding a black line for x and y axis
)


ggsave('gaba_crlb.png', plot=gp, path='./', scale=1, width=8, height=4, units="in", dpi=300,  bg = "transparent")

lm.model<-lmer(data=d, 'GABA_SD ~ age + ROI + (1|id)')
print(car::Anova(lm.model))
