library(tidyverse)
library(ggplot2)
library(lme4)
library(lmerTest)
library(dplyr)
setwd("/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI_roi")
getwd()
merge7t <- read.csv('/Volumes/Hera/Projects/7TBrainMech/scripts/txt/merged_7t.csv')

length(unique(merge7T$lunaid))
length(unique(YSR_data$lunaid))
length(unique(ASR_data$lunaid))

X7T_ASR_data <- read.csv('/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI_roi/')
install.packages("tidyverse")
install.packages("ggplot2")

merge7T <- read.csv("../../txt/merged_7t.csv", header=TRUE)
merge7T$rest.invage <- 1/merge7T$rest.age
merge7T$rest.age2 <- (merge7T$rest.age - mean(merge7T$rest.age, na.rm = T))^2
merge7T$rest.age2 <- (merge7T$rest.age - mean(merge7T$rest.age))^2

merge7T_restonly <- merge7T %>% 
  filter(!is.na(rest.age)) %>%
  mutate(rest.age_centered = rest.age - mean(rest.age),
         rest.age2         = rest.age_centered^2)

merge7T$sr.externalizing_probs_T

#testing git#
#git testing 2#


####NAA####

merge7T<- merge7T %>% 
  mutate(NAA_ACC_inv_z=scale(sipfc.ACC_NAA_gamadj, center=T, scale=T),
         NAA_MPFC_inv_z=scale(sipfc.MPFC_NAA_gamadj, center=T, scale=T),
         NAA_DLPFC_inv_z=scale(sipfc.DLPFC_NAA_gamadj, center=T, scale=T),
         NAA_RDLPFC_inv_z=scale(sipfc.RDLPFC_NAA_gamadj, center=T, scale=T),
         NAA_LDLPFC_inv_z=scale(sipfc.LDLPFC_NAA_gamadj, center=T, scale=T),
         rest.age_z=scale(rest.age, center=T, scale=T), 
         rest.invage_z=scale(rest.invage, center=T, scale=T))
#ACC
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.ACC_NAA_gamadj) + geom_point() + stat_smooth()+ theme_classic(base_size=15) +xlab("Age") +ylab("ACC NAA")
NAA_ACC <- lmer(data=merge7T,sipfc.ACC_NAA_gamadj ~ rest.age + visitno + (1|lunaid))
summary(NAA_ACC)

merge7T<- merge7t %>% 
  mutate(NAA_ACC_z=scale(sipfc.ACC_NAA_gamadj, center=T, scale=T),
         rest.age_z=scale(rest.age, center=T, scale=T))
NAA_ACC_z <- lmer(data=merge7T, NAA_ACC_z ~ rest.age_z + visitno + (1|lunaid))
summary(NAA_ACC_z)

#ACC INV
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.ACC_NAA_gamadj) + geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + theme_classic(base_size=15) +xlab("Age") +ylab("ACC NAA")
NAA_ACC_inv <- lmer(data=merge7T,sipfc.ACC_NAA_gamadj ~ rest.invage + visitno + (1|lunaid))
summary(NAA_ACC_inv)
merge7T<- merge7T %>% 
  mutate(NAA_ACC_inv_z=scale(sipfc.ACC_NAA_gamadj, center=T, scale=T),
         rest.invage_z=scale(rest.invage, center=T, scale=T))
NAA_ACC_inv_z <- lmer(data=merge7T, NAA_ACC_z ~ rest.invage_z + visitno + (1|lunaid))
summary(NAA_ACC_inv_z)
#ACC quad
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.ACC_gamadj) + geom_point() 
NAA_ACC_quadage <- lmer(data=merge7T, sipfc.ACC_NAA_gamadj ~ rest.age + rest.age2 + visitno  + (1|lunaid))
summary(NAA_ACC_quadage)  
AIC(NAA_ACC)
AIC(NAA_ACC_inv) 
AIC(NAA_ACC_quadage)


#MPFC
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.MPFC_NAA_gamadj) + geom_point() + geom_smooth + stat_smooth() + theme_classic(base_size=15) +xlab("Age") +ylab("MPFC NAA")
NAA_MPFC <- lmer(data=merge7T,sipfc.MPFC_NAA_gamadj ~ rest.age + visitno + (1|lunaid))
summary(NAA_MPFC)
#MPFC INV
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.MPFC_NAA_gamadj) + geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T)+ theme_classic(base_size=15) +xlab("Age") +ylab("MPFC NAA")
NAA_MPFC_inv <- lmer(data=merge7T,sipfc.MPFC_NAA_gamadj ~ rest.invage + visitno + (1|lunaid))
summary(NAA_MPFC_inv)

NAA_MPFC_inv_z <- lmer(data=merge7T, NAA_MPFC_inv_z ~ rest.invage_z + visitno + (1|lunaid))
summary(NAA_MPFC_inv_z)

#MPFC quad
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.MPFC_gamadj) + geom_point() + 
NAA_MPFC_quadage <- lmer(data=merge7T, sipfc.MPFC_NAA_gamadj ~ rest.age + rest.age2 + visitno  + (1|lunaid))
summary(NAA_MPFC_quadage)  
AIC(NAA_MPFC)
AIC(NAA_MPFC_inv) 
AIC(NAA_MPFC_quadage)

#DLPFC
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.DLPFC_NAA_gamadj) + geom_point() + stat_smooth()+ theme_classic(base_size=15) +xlab("Age") +ylab("DLPFC NAA")
NAA_DLPFC <- lmer(data=merge7T,sipfc.DLPFC_NAA_gamadj ~ rest.age + visitno + (1|lunaid))
summary(NAA_DLPFC)
#DLPFC INV
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.DLPFC_NAA_gamadj) + geom_point() +  geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + theme_classic(base_size=15) +xlab("Age") +ylab("DLPFC NAA")
NAA_DLPFC_inv <- lmer(data=merge7T,sipfc.DLPFC_NAA_gamadj ~ rest.invage + visitno + (1|lunaid))
summary(NAA_DLPFC_inv)
AIC(NAA_DLPFC, NAA_DLPFC_inv)

NAA_DLPFC_inv_z <- lmer(data=merge7T, NAA_DLPFC_inv_z ~ rest.invage_z + visitno + (1|lunaid))
summary(NAA_DLPFC_inv_z)

#DLPFC quad
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.DLPFC_gamadj) + geom_point() 
NAA_DLPFC_quadage <- lmer(data=merge7T, sipfc.DLPFC_NAA_gamadj ~ rest.age + rest.age2 + visitno  + (1|lunaid))
summary(NAA_DLPFC_quadage)  
AIC(NAA_DLPFC)
AIC(NAA_DLPFC_inv) 
AIC(NAA_DLPFC_quadage)
#RDLPFC
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.RDLPFC_NAA_gamadj) + geom_point() + stat_smooth()+ theme_classic(base_size=15) +xlab("Age") +ylab("RDLPFC NAA")
NAA_RDLPFC <- lmer(data=merge7T,sipfc.RDLPFC_NAA_gamadj ~ rest.age + visitno + (1|lunaid))
summary(NAA_RDLPFC)
#RDLPFC INV
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.RDLPFC_NAA_gamadj) + geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + theme_classic(base_size=15) +xlab("Age") +ylab("RDLPFC NAA")
NAA_RDLPFC_inv <- lmer(data=merge7T,sipfc.RDLPFC_NAA_gamadj ~ rest.invage + visitno + (1|lunaid))
summary(NAA_RDLPFC_inv)

NAA_RDLPFC_inv_z <- lmer(data=merge7T, NAA_RDLPFC_inv_z ~ rest.invage_z + visitno + (1|lunaid))
summary(NAA_RDLPFC_inv_z)

#RDLPFC quad
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.RDLPFC_gamadj) + geom_point() + 
NAA_RDLPFC_quadage <- lmer(data=merge7T, sipfc.RDLPFC_NAA_gamadj ~ rest.age + rest.age2 + visitno  + (1|lunaid))
summary(NAA_RDLPFC_quadage)  
AIC(NAA_RDLPFC)
AIC(NAA_RDLPFC_inv) 
AIC(NAA_RDLPFC_quadage)
#LDLPFC
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.LDLPFC_NAA_gamadj) + geom_point() + stat_smooth()+ theme_classic(base_size=15) +xlab("Age") +ylab("LDLPFC NAA")
NAA_LDLPFC <- lmer(data=merge7T,sipfc.LDLPFC_NAA_gamadj ~ rest.age + visitno + (1|lunaid))
summary(NAA_LDLPFC)
#LDLPFC INV
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.LDLPFC_NAA_gamadj) + geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T)+ theme_classic(base_size=15) +xlab("Age") +ylab("LDLPFC NAA")
NAA_LDLPFC_inv <- lmer(data=merge7T,sipfc.LDLPFC_NAA_gamadj ~ rest.invage + visitno + (1|lunaid))
summary(NAA_LDLPFC_inv)

NAA_LDLPFC_inv_z <- lmer(data=merge7T, NAA_LDLPFC_inv_z ~ rest.invage_z + visitno + (1|lunaid))
summary(NAA_LDLPFC_inv_z)

#LDLPFC quad
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.LDLPFC_gamadj) + geom_point() + 
NAA_LDLPFC_quadage <- lmer(data=merge7T, sipfc.LDLPFC_NAA_gamadj ~ rest.age + rest.age2 + visitno  + (1|lunaid))
summary(NAA_LDLPFC_quadage)  
AIC(NAA_LDLPFC)
AIC(NAA_LDLPFC_inv) 
AIC(NAA_LDLPFC_quadage)

####Myoinositol####
merge7T<- merge7T %>% 
  mutate(mI_ACC_inv_z=scale(sipfc.ACC_mI_gamadj, center=T, scale=T),
         mI_MPFC_inv_z=scale(sipfc.MPFC_mI_gamadj, center=T, scale=T),
         mI_DLPFC_inv_z=scale(sipfc.DLPFC_mI_gamadj, center=T, scale=T),
         mI_RDLPFC_inv_z=scale(sipfc.RDLPFC_mI_gamadj, center=T, scale=T),
         mI_LDLPFC_inv_z=scale(sipfc.LDLPFC_mI_gamadj, center=T, scale=T),
         rest.age_z=scale(rest.age, center=T, scale=T), 
         rest.invage_z=scale(rest.invage, center=T, scale=T))

mI_ACC_inv_z <- lmer(data=merge7T, mI_ACC_inv_z ~ rest.invage_z + visitno + (1|lunaid))
summary(mI_ACC_inv_z)
mI_MPFC_inv_z <- lmer(data=merge7T, mI_MPFC_inv_z ~ rest.invage_z + visitno + (1|lunaid))
summary(mI_MPFC_inv_z)
mI_DLPFC_inv_z <- lmer(data=merge7T, mI_DLPFC_inv_z ~ rest.invage_z + visitno + (1|lunaid))
summary(mI_DLPFC_inv_z)
mI_RDLPFC_inv_z <- lmer(data=merge7T, mI_RDLPFC_inv_z ~ rest.invage_z + visitno + (1|lunaid))
summary(mI_RDLPFC_inv_z)
mI_LDLPFC_inv_z <- lmer(data=merge7T, mI_LDLPFC_inv_z ~ rest.invage_z + visitno + (1|lunaid))
summary(mI_LDLPFC_inv_z)

#ACC
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.ACC_mI_gamadj) + geom_point() + stat_smooth()+ theme_classic(base_size=15) +xlab("Age") +ylab("ACC mI")
mI_ACC <- lmer(data=merge7T,sipfc.ACC_mI_gamadj ~ rest.age + visitno + (1|lunaid))
summary(mI_ACC)
#ACC INV
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.ACC_mI_gamadj) + geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + theme_classic(base_size=15) +xlab("Age") +ylab("ACC mI")
mI_ACC_inv <- lmer(data=merge7T,sipfc.ACC_mI_gamadj ~ rest.invage + visitno + (1|lunaid))
summary(mI_ACC_inv)
#ACC quad
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.ACC_mI_gamadj) + geom_point() 
mI_ACC_quadage <- lmer(data=merge7T, sipfc.ACC_mI_gamadj ~ rest.age + rest.age2 + visitno  + (1|lunaid))
summary(mI_ACC_quadage)  
AIC(mI_ACC)
AIC(mI_ACC_inv) 
AIC(mI_ACC_quadage)

#MPFC
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.MPFC_mI_gamadj) + geom_point() + stat_smooth() + theme_classic(base_size=15) +xlab("Age") +ylab("MPFC mI")
mI_MPFC <- lmer(data=merge7T,sipfc.MPFC_mI_gamadj ~ rest.age + visitno + (1|lunaid))
summary(mI_MPFC)
#MPFC INV
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.MPFC_mI_gamadj) + geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T)+ theme_classic(base_size=15) +xlab("Age") +ylab("MPFC mI")
mI_MPFC_inv <- lmer(data=merge7T,sipfc.MPFC_mI_gamadj ~ rest.invage + visitno + (1|lunaid))
summary(mI_MPFC_inv)
#MPFC quad
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.MPFC_gamadj) + geom_point() + 
mI_MPFC_quadage <- lmer(data=merge7T, sipfc.MPFC_mI_gamadj ~ rest.age + rest.age2 + visitno  + (1|lunaid))
summary(mI_MPFC_quadage)  
AIC(mI_MPFC)
AIC(mI_MPFC_inv) 
AIC(mI_MPFC_quadage)

#DLPFC
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.DLPFC_mI_gamadj) + geom_point() + stat_smooth()+ theme_classic(base_size=15) +xlab("Age") +ylab("DLPFC mI")
mI_DLPFC <- lmer(data=merge7T,sipfc.DLPFC_mI_gamadj ~ rest.age + visitno + (1|lunaid))
summary(mI_DLPFC)
#DLPFC INV
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.DLPFC_mI_gamadj) + geom_point() +  geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + theme_classic(base_size=15) +xlab("Age") +ylab("DLPFC mI")
mI_DLPFC_inv <- lmer(data=merge7T,sipfc.DLPFC_mI_gamadj ~ rest.invage + visitno + (1|lunaid))
summary(mI_DLPFC_inv)
AIC(mI_DLPFC, mI_DLPFC_inv)
#DLPFC quad
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.DLPFC_gamadj) + geom_point() 
mI_DLPFC_quadage <- lmer(data=merge7T, sipfc.DLPFC_mI_gamadj ~ rest.age + rest.age2 + visitno  + (1|lunaid))
summary(mI_DLPFC_quadage)  
AIC(mI_DLPFC)
AIC(mI_DLPFC_inv) 
AIC(mI_DLPFC_quadage)
#RDLPFC
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.RDLPFC_mI_gamadj) + geom_point() + stat_smooth()+ theme_classic(base_size=15) +xlab("Age") +ylab("RDLPFC mI")
mI_RDLPFC <- lmer(data=merge7T,sipfc.RDLPFC_mI_gamadj ~ rest.age + visitno + (1|lunaid))
summary(mI_RDLPFC)
#RDLPFC INV
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.RDLPFC_mI_gamadj) + geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + theme_classic(base_size=15) +xlab("Age") +ylab("RDLPFC mI")
mI_RDLPFC_inv <- lmer(data=merge7T,sipfc.RDLPFC_mI_gamadj ~ rest.invage + visitno + (1|lunaid))
summary(mI_RDLPFC_inv)
#RDLPFC quad
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.RDLPFC_gamadj) + geom_point() + 
mI_RDLPFC_quadage <- lmer(data=merge7T, sipfc.RDLPFC_mI_gamadj ~ rest.age + rest.age2 + visitno  + (1|lunaid))
summary(mI_RDLPFC_quadage)  
AIC(mI_RDLPFC)
AIC(mI_RDLPFC_inv) 
AIC(mI_RDLPFC_quadage)
#LDLPFC
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.LDLPFC_mI_gamadj) + geom_point() + stat_smooth()+ theme_classic(base_size=15) +xlab("Age") +ylab("LDLPFC mI")
mI_LDLPFC <- lmer(data=merge7T,sipfc.LDLPFC_mI_gamadj ~ rest.age + visitno + (1|lunaid))
summary(mI_LDLPFC)
#LDLPFC INV
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.LDLPFC_mI_gamadj) + geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T)+ theme_classic(base_size=15) +xlab("Age") +ylab("LDLPFC mI")
mI_LDLPFC_inv <- lmer(data=merge7T,sipfc.LDLPFC_mI_gamadj ~ rest.invage + visitno + (1|lunaid))
summary(mI_LDLPFC_inv)
#LDLPFC quad
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.LDLPFC_gamadj) + geom_point() + 
mI_LDLPFC_quadage <- lmer(data=merge7T, sipfc.LDLPFC_mI_gamadj ~ rest.age + rest.age2 + visitno  + (1|lunaid))
summary(mI_LDLPFC_quadage)  
AIC(mI_LDLPFC)
AIC(mI_LDLPFC_inv) 
AIC(mI_LDLPFC_quadage)

####Glutathione####
merge7T<- merge7T %>% 
  mutate(GSH_ACC_inv_z=scale(sipfc.ACC_GSH_gamadj, center=T, scale=T),
         GSH_MPFC_inv_z=scale(sipfc.MPFC_GSH_gamadj, center=T, scale=T),
         GSH_DLPFC_inv_z=scale(sipfc.DLPFC_GSH_gamadj, center=T, scale=T),
         GSH_RDLPFC_inv_z=scale(sipfc.RDLPFC_GSH_gamadj, center=T, scale=T),
         GSH_LDLPFC_inv_z=scale(sipfc.LDLPFC_GSH_gamadj, center=T, scale=T),
         rest.age_z=scale(rest.age, center=T, scale=T), 
         rest.invage_z=scale(rest.invage, center=T, scale=T))

GSH_ACC_inv_z <- lmer(data=merge7T, GSH_ACC_inv_z ~ rest.invage_z + visitno + (1|lunaid))
summary(GSH_ACC_inv_z)
GSH_MPFC_inv_z <- lmer(data=merge7T, GSH_MPFC_inv_z ~ rest.invage_z + visitno + (1|lunaid))
summary(GSH_MPFC_inv_z)
GSH_DLPFC_inv_z <- lmer(data=merge7T, GSH_DLPFC_inv_z ~ rest.invage_z + visitno + (1|lunaid))
summary(GSH_DLPFC_inv_z)
GSH_RDLPFC_inv_z <- lmer(data=merge7T, GSH_RDLPFC_inv_z ~ rest.invage_z + visitno + (1|lunaid))
summary(GSH_RDLPFC_inv_z)
GSH_LDLPFC_inv_z <- lmer(data=merge7T, GSH_LDLPFC_inv_z ~ rest.invage_z + visitno + (1|lunaid))
summary(GSH_LDLPFC_inv_z)
#ACC
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.ACC_GSH_gamadj) + geom_point() + stat_smooth()+ theme_classic(base_size=15) +xlab("Age") +ylab("ACC GSH")
GSH_ACC <- lmer(data=merge7T,sipfc.ACC_GSH_gamadj ~ rest.age + visitno + (1|lunaid))
summary(GSH_ACC)
#ACC INV
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.ACC_GSH_gamadj) + geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + theme_classic(base_size=15) +xlab("Age") +ylab("ACC GSH")
GSH_ACC_inv <- lmer(data=merge7T,sipfc.ACC_GSH_gamadj ~ rest.invage + visitno + (1|lunaid))
summary(GSH_ACC_inv)
#ACC quad
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.ACC_GSH_gamadj) + geom_point() 
GSH_ACC_quadage <- lmer(data=merge7T, sipfc.ACC_GSH_gamadj ~ rest.age + rest.age2 + visitno  + (1|lunaid))
summary(GSH_ACC_quadage)  
AIC(GSH_ACC)
AIC(GSH_ACC_inv) 
AIC(GSH_ACC_quadage)

#MPFC
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.MPFC_GSH_gamadj) + geom_point() + stat_smooth() + theme_classic(base_size=15) +xlab("Age") +ylab("MPFC GSH")
GSH_MPFC <- lmer(data=merge7T,sipfc.MPFC_GSH_gamadj ~ rest.age + visitno + (1|lunaid))
summary(GSH_MPFC)
#MPFC INV
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.MPFC_GSH_gamadj) + geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T)+ theme_classic(base_size=15) +xlab("Age") +ylab("MPFC GSH")
GSH_MPFC_inv <- lmer(data=merge7T,sipfc.MPFC_GSH_gamadj ~ rest.invage + visitno + (1|lunaid))
summary(GSH_MPFC_inv)
#MPFC quad
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.MPFC_gamadj) + geom_point() + 
GSH_MPFC_quadage <- lmer(data=merge7T, sipfc.MPFC_GSH_gamadj ~ rest.age + rest.age2 + visitno  + (1|lunaid))
summary(GSH_MPFC_quadage)  
AIC(GSH_MPFC)
AIC(GSH_MPFC_inv) 
AIC(GSH_MPFC_quadage)

#DLPFC
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.DLPFC_GSH_gamadj) + geom_point() + stat_smooth()+ theme_classic(base_size=15) +xlab("Age") +ylab("DLPFC GSH")
GSH_DLPFC <- lmer(data=merge7T,sipfc.DLPFC_GSH_gamadj ~ rest.age + visitno + (1|lunaid))
summary(GSH_DLPFC)
#DLPFC INV
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.DLPFC_GSH_gamadj) + geom_point() +  geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + theme_classic(base_size=15) +xlab("Age") +ylab("DLPFC GSH")
GSH_DLPFC_inv <- lmer(data=merge7T,sipfc.DLPFC_GSH_gamadj ~ rest.invage + visitno + (1|lunaid))
summary(GSH_DLPFC_inv)
#DLPFC quad
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.DLPFC_gamadj) + geom_point() 
GSH_DLPFC_quadage <- lmer(data=merge7T, sipfc.DLPFC_GSH_gamadj ~ rest.age + rest.age2 + visitno  + (1|lunaid))
summary(GSH_DLPFC_quadage)  
AIC(GSH_DLPFC)
AIC(GSH_DLPFC_inv) 
AIC(GSH_DLPFC_quadage)
#RDLPFC
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.RDLPFC_GSH_gamadj) + geom_point() + stat_smooth()+ theme_classic(base_size=15) +xlab("Age") +ylab("RDLPFC GSH")
GSH_RDLPFC <- lmer(data=merge7T,sipfc.RDLPFC_GSH_gamadj ~ rest.age + visitno + (1|lunaid))
summary(GSH_RDLPFC)
#RDLPFC INV
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.RDLPFC_GSH_gamadj) + geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + theme_classic(base_size=15) +xlab("Age") +ylab("RDLPFC GSH")
GSH_RDLPFC_inv <- lmer(data=merge7T,sipfc.RDLPFC_GSH_gamadj ~ rest.invage + visitno + (1|lunaid))
summary(GSH_RDLPFC_inv)
#RDLPFC quad
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.RDLPFC_gamadj) + geom_point() + 
GSH_RDLPFC_quadage <- lmer(data=merge7T, sipfc.RDLPFC_GSH_gamadj ~ rest.age + rest.age2 + visitno  + (1|lunaid))
summary(GSH_RDLPFC_quadage)  
AIC(GSH_RDLPFC)
AIC(GSH_RDLPFC_inv) 
AIC(GSH_RDLPFC_quadage)
#LDLPFC
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.LDLPFC_GSH_gamadj) + geom_point() + stat_smooth()+ theme_classic(base_size=15) +xlab("Age") +ylab("LDLPFC GSH")
GSH_LDLPFC <- lmer(data=merge7T,sipfc.LDLPFC_GSH_gamadj ~ rest.age + visitno + (1|lunaid))
summary(GSH_LDLPFC)
#LDLPFC INV
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.LDLPFC_GSH_gamadj) + geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T)+ theme_classic(base_size=15) +xlab("Age") +ylab("LDLPFC GSH")
GSH_LDLPFC_inv <- lmer(data=merge7T,sipfc.LDLPFC_GSH_gamadj ~ rest.invage + visitno + (1|lunaid))
summary(GSH_LDLPFC_inv)
#LDLPFC quad
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.LDLPFC_gamadj) + geom_point() + 
GSH_LDLPFC_quadage <- lmer(data=merge7T, sipfc.LDLPFC_GSH_gamadj ~ rest.age + rest.age2 + visitno  + (1|lunaid))
summary(GSH_LDLPFC_quadage)  
AIC(GSH_LDLPFC)
AIC(GSH_LDLPFC_inv) 
AIC(GSH_LDLPFC_quadage)


lmer()

merge7T %>% select(sr.externalizing_probs_T,rest.age,sex,lunaid) %>% str
merge7T$sr.externalizing_probs_T <- as.numeric(merge7T$sr.externalizing_probs_T)

# remove eg. '-B' from asr/ysr _T values like '60-B', and make all columns numeric
merge7T <- merge7T %>% 
  mutate(across(matches('^sr.*T'), 
                function(x) gsub('-[A-Z]','',x) |>
                  as.numeric()))

merge7T %>% select(sr.internalizing_probs_T,rest.age,sex,lunaid) %>% str
merge7T$sr.internalizing_probs_T <- as.numeric(merge7T$sr.internalizing_probs_T)

# remove eg. '-B' from asr/ysr _T values like '60-B', and make all columns numeric
merge7T <- merge7T %>% 
  mutate(across(matches('^sr.*T'), 
                function(x) gsub('-[A-Z]','',x) |>
                  as.numeric()))


MRS_glu$glu_z <- MRS_glu %>% mutate(glu_z=scale(Glu.Cr, center=T, scale=T))

###externalizing and age and sex###
ext_age_sex_fixed <- lmer(data=merge7T, sr.externalizing_probs_T ~ rest.age + sex + (1|lunaid)) #fixed model for age
summary(ext_age_sex_fixed)
ext_age_sex_interaction <- lmer(data=merge7T, sr.externalizing_probs_T ~ rest.age + rest.age*sex + (1|lunaid)) #interaction btwn age and sex
summary(ext_age_sex_interaction)
ggplot(data=merge7T)+aes(x=rest.age, y=sr.externalizing_probs_T, color = sex) + geom_point() + stat_smooth()+ theme_classic(base_size=15) +xlab("Age") +ylab("Externalizing") 

ext_age_sex_fixed_inv <- lmer(data=merge7T, sr.externalizing_probs_T ~ rest.invage + sex + (1|lunaid)) #fixed model for age
summary(ext_age_sex_fixed_inv)
ext_age_sex_interaction_inv <- lmer(data=merge7T, sr.externalizing_probs_T ~ rest.invage + rest.invage*sex + (1|lunaid)) #interaction btwn age and sex
summary(ext_age_sex_interaction_inv)
ggplot(data=merge7T)+aes(x=rest.age, y=sr.externalizing_probs_T, color = sex) + geom_point() +  geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + theme_classic(base_size=15) +xlab("Age") +ylab("Externalizing")

AIC(ext_age_sex_fixed)
AIC(ext_age_sex_fixed_inv)
AIC(ext_age_sex_interaction)
AIC(ext_age_sex_interaction_inv)

merge7T<- merge7T %>% 
  mutate(externalizing_probs_z=scale(sr.externalizing_probs_T, center=T, scale=T),
         rest.invage_z=scale(rest.invage, center=T, scale=T))
ext_age_sex_fixed_inv_z <- lmer(data=merge7T, externalizing_probs_z ~ rest.invage_z + sex + (1|lunaid)) #fixed model for age
summary(ext_age_sex_fixed_inv_z)
ext_age_sex_interaction_inv_z <- lmer(data=merge7T, externalizing_probs_z ~ rest.invage_z + rest.invage_z*sex + (1|lunaid)) #interaction btwn age and sex
summary(ext_age_sex_interaction_inv_z)


##split dataframes by age###
YSR_data <- merge7T %>% filter (rest.age < 18)
ASR_data <- merge7T%>% filter(rest.age > 18) 

#add inv#
YSR_data$rest.invage <- 1/YSR_data$rest.age
ASR_data$rest.invage <- 1/ASR_data$rest.age

YSR_data<- YSR_data %>% 
  mutate(externalizing_probs_z=scale(sr.externalizing_probs_T, center=T, scale=T),
         rest.invage_z=scale(rest.invage, center=T, scale=T))

ASR_data<- ASR_data %>% 
  mutate(externalizing_probs_z=scale(sr.externalizing_probs_T, center=T, scale=T),
         rest.invage_z=scale(rest.invage, center=T, scale=T))

##externalizing by age#
ext_age_YSR_fixed <- lmer(data=YSR_data, sr.externalizing_probs_T ~ rest.age + sex + (1|lunaid)) #fixed model for age
summary(ext_age_YSR_fixed)
ext_age_sex_interaction_YSR <- lmer(data=YSR_data, sr.externalizing_probs_T ~ rest.age + rest.age*sex + (1|lunaid)) #interaction btwn age and sex
summary(ext_age_sex_interaction_YSR)
ggplot(data=YSR_data)+aes(x=rest.age, y=sr.externalizing_probs_T, color = sex) + geom_point() + stat_smooth()+ theme_classic(base_size=15) +xlab("Age") +ylab("Externalizing")

ext_age_YSR_fixed_inv <- lmer(data=YSR_data, sr.externalizing_probs_T ~ rest.invage + sex + (1|lunaid)) #fixed model for age
summary(ext_age_YSR_fixed_inv)
ext_age_sex_interaction_YSR_inv <- lmer(data=YSR_data, sr.externalizing_probs_T ~ rest.invage + rest.age*sex + (1|lunaid)) #interaction btwn age and sex
summary(ext_age_sex_interaction_YSR_inv)
ggplot(data=YSR_data)+aes(x=rest.age, y=sr.externalizing_probs_T, color = sex) + geom_point() +  geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + theme_classic(base_size=15) +xlab("Age") +ylab("Externalizing")

AIC(ext_age_YSR_fixed)
AIC(ext_age_YSR_fixed_inv)
AIC(ext_age_sex_interaction_YSR)
AIC(ext_age_sex_interaction_YSR_inv)

ext_age_YSR_fixed_inv_z <- lmer(data=YSR_data, externalizing_probs_z ~ rest.invage_z + sex + (1|lunaid)) #fixed model for age
summary(ext_age_YSR_fixed_inv_z)
ext_age_sex_interaction_YSR_inv_z <- lmer(data=YSR_data, externalizing_probs_z ~ rest.invage_z + rest.invage_z*sex + (1|lunaid)) #interaction btwn age and sex
summary(ext_age_sex_interaction_YSR_inv_z)

ext_age_ASR_fixed_z <- lmer(data=ASR_data, externalizing_probs_z ~ rest.invage_z + sex + (1|lunaid)) #fixed model for age
summary(ext_age_ASR_fixed_z)
ext_age_sex_interaction_ASR_z <- lmer(data=ASR_data, externalizing_probs_z ~ rest.invage_z + rest.invage_z*sex + (1|lunaid)) #interaction btwn age and sex
summary(ext_age_sex_interaction_ASR_z)
ggplot(data=ASR_data)+aes(x=rest.age, y=sr.externalizing_probs_T, color = sex) + geom_point() + stat_smooth()+ theme_classic(base_size=15) +xlab("Age") +ylab("Externalizing")

ext_age_ASR_fixed_inv <- lmer(data=ASR_data, sr.externalizing_probs_T ~ rest.invage + sex + (1|lunaid)) #fixed model for age
summary(ext_age_ASR_fixed_inv)
ext_age_sex_interaction_ASR_inv <- lmer(data=ASR_data, sr.externalizing_probs_T ~ rest.invage + rest.age*sex + (1|lunaid)) #interaction btwn age and sex
summary(ext_age_sex_interaction_ASR_inv)
ggplot(data=ASR_data)+aes(x=rest.age, y=sr.externalizing_probs_T, color = sex) + geom_point() +  geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + theme_classic(base_size=15) +xlab("Age") +ylab("Externalizing")

AIC(ext_age_ASR_fixed)
AIC(ext_age_ASR_fixed_inv)
AIC(ext_age_sex_interaction_ASR)
AIC(ext_age_sex_interaction_ASR_inv)


###internalizing and age and sex###
int_age_sex_fixed <- lmer(data=merge7T, sr.internalizing_probs_T ~ rest.age + sex + (1|lunaid)) #fixed model for age
summary(int_age_sex_fixed)
int_age_sex_interaction <- lmer(data=merge7T, sr.internalizing_probs_T ~ rest.age + rest.age*sex + (1|lunaid)) #interaction btwn age and sex
summary(int_age_sex_interaction)
ggplot(data=merge7T)+aes(x=rest.age, y=sr.internalizing_probs_T, color = sex) + geom_point() + stat_smooth()+ theme_classic(base_size=15) +xlab("Age") +ylab("internalizing") 

int_age_sex_fixed_inv <- lmer(data=merge7T, sr.internalizing_probs_T ~ rest.invage + sex + (1|lunaid)) #fixed model for age
summary(int_age_sex_fixed_inv)
int_age_sex_interaction_inv <- lmer(data=merge7T, sr.internalizing_probs_T ~ rest.invage + rest.invage*sex + (1|lunaid)) #interaction btwn age and sex
summary(int_age_sex_interaction_inv)
ggplot(data=merge7T)+aes(x=rest.age, y=sr.internalizing_probs_T, color = sex) + geom_point() +  geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + theme_classic(base_size=15) +xlab("Age") +ylab("internalizing")

AIC(int_age_sex_fixed)
AIC(int_age_sex_fixed_inv)
AIC(int_age_sex_interaction)
AIC(int_age_sex_interaction_inv)

merge7T<- merge7T %>% 
  mutate(internalizing_probs_z=scale(sr.internalizing_probs_T, center=T, scale=T),
         rest.invage_z=scale(rest.invage, center=T, scale=T))
int_age_sex_fixed_inv_z <- lmer(data=merge7T, internalizing_probs_z ~ rest.invage_z + sex + (1|lunaid)) #fixed model for age
summary(int_age_sex_fixed_inv_z)
int_age_sex_interaction_inv_z <- lmer(data=merge7T, internalizing_probs_z ~ rest.invage_z + rest.invage_z*sex + (1|lunaid)) #interaction btwn age and sex
summary(int_age_sex_interaction_inv_z)


##split dataframes by age###
YSR_data <- merge7T %>% filter (rest.age < 18)
ASR_data <- merge7T%>% filter(rest.age > 18) 

#add inv#
YSR_data$rest.invage <- 1/YSR_data$rest.age
ASR_data$rest.invage <- 1/ASR_data$rest.age

YSR_data<- YSR_data %>% 
  mutate(internalizing_probs_z=scale(sr.internalizing_probs_T, center=T, scale=T),
         rest.invage_z=scale(rest.invage, center=T, scale=T))

ASR_data<- ASR_data %>% 
  mutate(internalizing_probs_z=scale(sr.internalizing_probs_T, center=T, scale=T),
         rest.invage_z=scale(rest.invage, center=T, scale=T))

##internalizing by age#

#YSR#
int_age_YSR_fixed <- lmer(data=YSR_data, sr.internalizing_probs_T ~ rest.age + sex + (1|lunaid)) #fixed model for age
summary(int_age_YSR_fixed)
int_age_sex_interaction_YSR <- lmer(data=YSR_data, sr.internalizing_probs_T ~ rest.age + rest.age*sex + (1|lunaid)) #interaction btwn age and sex
summary(int_age_sex_interaction_YSR)
ggplot(data=YSR_data)+aes(x=rest.age, y=sr.internalizing_probs_T, color = sex) + geom_point() + stat_smooth()+ theme_classic(base_size=15) +xlab("Age") +ylab("internalizing")

int_age_YSR_fixed_inv <- lmer(data=YSR_data, sr.internalizing_probs_T ~ rest.invage + sex + (1|lunaid)) #fixed model for age
summary(int_age_YSR_fixed_inv)
int_age_sex_interaction_YSR_inv <- lmer(data=YSR_data, sr.internalizing_probs_T ~ rest.invage + rest.age*sex + (1|lunaid)) #interaction btwn age and sex
summary(int_age_sex_interaction_YSR_inv)
ggplot(data=YSR_data)+aes(x=rest.age, y=sr.internalizing_probs_T, color = sex) + geom_point() +  geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + theme_classic(base_size=15) +xlab("Age") +ylab("internalizing")

AIC(int_age_YSR_fixed)
AIC(int_age_YSR_fixed_inv)
AIC(int_age_sex_interaction_YSR)
AIC(int_age_sex_interaction_YSR_inv)

int_age_YSR_fixed_inv_z <- lmer(data_YSR_data, internalizing_probs_z ~ rest.invage_z + sex + (1|lunaid)) #fixed model for age
summary(int_age_YSR_fixed_inv_z)
int_age_sex_interaction_YSR_inv_z <- lmer(data=YSR_data, internalizing_probs_z ~ rest.invage_z + rest.invage_z*sex + (1|lunaid)) #interaction btwn age and sex
summary(int_age_sex_interaction_YSR_inv_z)

#ASR#
int_age_ASR_fixed <- lmer(data=ASR_data, sr.internalizing_probs_T ~ rest.age + sex + (1|lunaid)) #fixed model for age
summary(int_age_ASR_fixed)
int_age_sex_interaction_ASR <- lmer(data=ASR_data, sr.internalizing_probs_T ~ rest.age + rest.age*sex + (1|lunaid)) #interaction btwn age and sex
summary(int_age_sex_interaction_ASR)
ggplot(data=ASR_data)+aes(x=rest.age, y=sr.internalizing_probs_T, color = sex) + geom_point() + stat_smooth()+ theme_classic(base_size=15) +xlab("Age") +ylab("internalizing")

int_age_ASR_fixed_inv <- lmer(data=ASR_data, sr.internalizing_probs_T ~ rest.invage + sex + (1|lunaid)) #fixed model for age
summary(int_age_ASR_fixed_inv)
int_age_sex_interaction_ASR_inv <- lmer(data=ASR_data, sr.internalizing_probs_T ~ rest.invage + rest.age*sex + (1|lunaid)) #interaction btwn age and sex
summary(int_age_sex_interaction_ASR_inv)
ggplot(data=ASR_data)+aes(x=rest.age, y=sr.internalizing_probs_T, color = sex) + geom_point() +  geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + theme_classic(base_size=15) +xlab("Age") +ylab("internalizing")

AIC(int_age_ASR_fixed)
AIC(int_age_ASR_fixed_inv)
AIC(int_age_sex_interaction_ASR)
AIC(int_age_sex_interaction_ASR_inv)

int_age_ASR_fixed_inv_z <- lmer(data=ASR_data, internalizing_probs_z ~ rest.invage_z + sex + (1|lunaid)) #fixed model for age
summary(int_age_ASR_fixed_inv_z)
int_age_sex_interaction_ASR_inv_z <- lmer(data=ASR_data, internalizing_probs_z ~ rest.invage_z + rest.invage_z*sex + (1|lunaid)) #interaction btwn age and sex
summary(int_age_sex_interaction_ASR_inv_z)

##correlation btwn metabolites and externalizing##
lmer(data = adult, ext ~ MRSI + sex)
ggplot(ext, MRSI)
    ####YSR####

YSR_data<- YSR_data %>% 
  mutate(NAA_ACC_z=scale(sipfc.ACC_NAA_gamadj, center=T, scale=T),
         NAA_MPFC_z=scale(sipfc.MPFC_NAA_gamadj, center=T, scale=T),
         NAA_DLPFC_z=scale(sipfc.DLPFC_NAA_gamadj, center=T, scale=T),
         NAA_RDLPFC_z=scale(sipfc.RDLPFC_NAA_gamadj, center=T, scale=T),
         NAA_LDLPFC_z=scale(sipfc.LDLPFC_NAA_gamadj, center=T, scale=T),
         externalizing_probs_z=scale(sr.externalizing_probs_T, center=T, scale=T))

YSR_ext_NAA_ACC_z <- lmer(data=YSR_data, externalizing_probs_z ~ NAA_ACC_z + sex + (1|lunaid))
summary(YSR_ext_NAA_ACC_z)
YSR_ext_NAA_MPFC_z <- lmer(data=YSR_data, externalizing_probs_z ~ NAA_MPFC_z + sex + (1|lunaid))
summary(YSR_ext_NAA_MPFC_z)
YSR_ext_NAA_DLPFC_z <- lmer(data=YSR_data, externalizing_probs_z ~ NAA_DLPFC_z + sex + (1|lunaid))
summary(YSR_ext_NAA_DLPFC_z)
YSR_ext_NAA_RDLPFC_z <- lmer(data=YSR_data, externalizing_probs_z ~ NAA_RDLPFC_z + sex + (1|lunaid))
summary(YSR_ext_NAA_RDLPFC_z)
YSR_ext_NAA_LDLPFC_z <- lmer(data=YSR_data, externalizing_probs_z ~ NAA_LDLPFC_z + sex + (1|lunaid))
summary(YSR_ext_NAA_LDLPFC_z)

#NAA ACC#
YSR_ext_NAA_ACC <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.ACC_NAA_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sr.externalizing_probs_T, y=sipfc.ACC_NAA_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("Externalizing") + ylab("NAA ACC")
summary(YSR_ext_NAA_ACC)

YSR_ext_NAA_ACC_age_int <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.ACC_NAA_gamadj * rest.age + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.ACC_NAA_gamadj, y=sr.externalizing_probs_T) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("NAA ACC") + ylab("Externalizing")
summary(YSR_ext_NAA_ACC_age_int)

YSR_ext_NAA_ACC_age <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.ACC_NAA_gamadj + rest.age + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.ACC_NAA_gamadj, y=sr.externalizing_probs_T) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("NAA ACC") + ylab("Externalizing")
summary(YSR_ext_NAA_ACC_age)

#NAA MPFC#
YSR_ext_NAA_MPFC <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.MPFC_NAA_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sr.externalizing_probs_T, y=sipfc.MPFC_NAA_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("Externalizing") + ylab("NAA MPFC")
summary(YSR_ext_NAA_MPFC)
#NAA DLPFC#
YSR_ext_NAA_DLPFC <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.DLPFC_NAA_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sr.externalizing_probs_T, y=sipfc.DLPFC_NAA_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("Externalizing") + ylab("NAA DLPFC")
summary(YSR_ext_NAA_DLPFC)
#NAA RDLPFC#
YSR_ext_NAA_RDLPFC <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.RDLPFC_NAA_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sr.externalizing_probs_T, y=sipfc.RDLPFC_NAA_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("Externalizing") + ylab("NAA RDLPFC")
summary(YSR_ext_NAA_RDLPFC)
#NAA LDLPFC#
YSR_ext_NAA_LDLPFC <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.LDLPFC_NAA_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sr.externalizing_probs_T, y=sipfc.LDLPFC_NAA_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("Externalizing") + ylab("NAA LDLPFC")
summary(YSR_ext_NAA_LDLPFC)

YSR_data<- YSR_data %>% 
  mutate(mI_ACC_z=scale(sipfc.ACC_mI_gamadj, center=T, scale=T),
         mI_MPFC_z=scale(sipfc.MPFC_mI_gamadj, center=T, scale=T),
         mI_DLPFC_z=scale(sipfc.DLPFC_mI_gamadj, center=T, scale=T),
         mI_RDLPFC_z=scale(sipfc.RDLPFC_mI_gamadj, center=T, scale=T),
         mI_LDLPFC_z=scale(sipfc.LDLPFC_mI_gamadj, center=T, scale=T),
         externalizing_probs_z=scale(sr.externalizing_probs_T, center=T, scale=T))

YSR_ext_mI_ACC_z <- lmer(data=YSR_data, externalizing_probs_z ~ mI_ACC_z + sex + (1|lunaid))
summary(YSR_ext_mI_ACC_z)
YSR_ext_mI_MPFC_z <- lmer(data=YSR_data, externalizing_probs_z ~ mI_MPFC_z + sex + (1|lunaid))
summary(YSR_ext_mI_MPFC_z)
YSR_ext_mI_DLPFC_z <- lmer(data=YSR_data, externalizing_probs_z ~ mI_DLPFC_z + sex + (1|lunaid))
summary(YSR_ext_mI_DLPFC_z)
YSR_ext_mI_RDLPFC_z <- lmer(data=YSR_data, externalizing_probs_z ~ mI_RDLPFC_z + sex + (1|lunaid))
summary(YSR_ext_mI_RDLPFC_z)
YSR_ext_mI_LDLPFC_z <- lmer(data=YSR_data, externalizing_probs_z ~ mI_LDLPFC_z + sex + (1|lunaid))
summary(YSR_ext_mI_LDLPFC_z)

#mI ACC#
YSR_ext_mI_ACC <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.ACC_mI_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sr.externalizing_probs_T, y=sipfc.ACC_mI_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("Externalizing") + ylab("mI ACC")
summary(YSR_ext_mI_ACC)
#mI MPFC#
YSR_ext_mI_MPFC <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.MPFC_mI_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sr.externalizing_probs_T, y=sipfc.MPFC_mI_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("Externalizing") + ylab("mI MPFC")
summary(YSR_ext_mI_MPFC)
#mI DLPFC#
YSR_ext_mI_DLPFC <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.DLPFC_mI_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sr.externalizing_probs_T, y=sipfc.DLPFC_mI_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("Externalizing") + ylab("mI DLPFC")
summary(YSR_ext_mI_DLPFC)
#mI RDLPFC#
YSR_ext_mI_RDLPFC <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.RDLPFC_mI_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sr.externalizing_probs_T, y=sipfc.RDLPFC_mI_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("Externalizing") + ylab("mI RDLPFC")
summary(YSR_ext_mI_RDLPFC)
#mI LDLPFC#
YSR_ext_mI_LDLPFC <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.LDLPFC_mI_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sr.externalizing_probs_T, y=sipfc.LDLPFC_mI_gamadj, color=sex) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("Externalizing") + ylab("mI LDLPFC")
summary(YSR_ext_mI_LDLPFC)

YSR_data<- YSR_data %>% 
  mutate(GSH_ACC_z=scale(sipfc.ACC_GSH_gamadj, center=T, scale=T),
         GSH_MPFC_z=scale(sipfc.MPFC_GSH_gamadj, center=T, scale=T),
         GSH_DLPFC_z=scale(sipfc.DLPFC_GSH_gamadj, center=T, scale=T),
         GSH_RDLPFC_z=scale(sipfc.RDLPFC_GSH_gamadj, center=T, scale=T),
         GSH_LDLPFC_z=scale(sipfc.LDLPFC_GSH_gamadj, center=T, scale=T),
         externalizing_probs_z=scale(sr.externalizing_probs_T, center=T, scale=T))

YSR_ext_GSH_ACC_z <- lmer(data=YSR_data, externalizing_probs_z ~ GSH_ACC_z + sex + (1|lunaid))
summary(YSR_ext_GSH_ACC_z)
YSR_ext_GSH_MPFC_z <- lmer(data=YSR_data, externalizing_probs_z ~ GSH_MPFC_z + sex + (1|lunaid))
summary(YSR_ext_GSH_MPFC_z)
YSR_ext_GSH_DLPFC_z <- lmer(data=YSR_data, externalizing_probs_z ~ GSH_DLPFC_z + sex + (1|lunaid))
summary(YSR_ext_GSH_DLPFC_z)
YSR_ext_GSH_RDLPFC_z <- lmer(data=YSR_data, externalizing_probs_z ~ GSH_RDLPFC_z + sex + (1|lunaid))
summary(YSR_ext_GSH_RDLPFC_z)
YSR_ext_GSH_LDLPFC_z <- lmer(data=YSR_data, externalizing_probs_z ~ GSH_LDLPFC_z + sex + (1|lunaid))
summary(YSR_ext_GSH_LDLPFC_z)

#GSH ACC#
YSR_ext_GSH_ACC <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.ACC_GSH_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sr.externalizing_probs_T, y=sipfc.ACC_GSH_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("Externalizing") + ylab("GSH ACC")
summary(YSR_ext_GSH_ACC)

YSR_ext_GSH_ACC_age_int <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.ACC_GSH_gamadj * rest.age + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.ACC_GSH_gamadj, y=sr.externalizing_probs_T) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("GSH ACC") + ylab("Externalizing")
summary(YSR_ext_GSH_ACC_age_int)

YSR_ext_GSH_ACC_age <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.ACC_GSH_gamadj + rest.age + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.ACC_GSH_gamadj, y=sr.externalizing_probs_T) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("GSH ACC") + ylab("Externalizing")
summary(YSR_ext_GSH_ACC_age)

#GSH MPFC#
YSR_ext_GSH_MPFC <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.MPFC_GSH_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sr.externalizing_probs_T, y=sipfc.MPFC_GSH_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("Externalizing") + ylab("GSH MPFC")
summary(YSR_ext_GSH_MPFC)
#GSH DLPFC#
YSR_ext_GSH_DLPFC <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.DLPFC_GSH_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sr.externalizing_probs_T, y=sipfc.DLPFC_GSH_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("Externalizing") + ylab("GSH DLPFC")
summary(YSR_ext_GSH_DLPFC)
#GSH RDLPFC#
YSR_ext_GSH_RDLPFC <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.RDLPFC_GSH_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sr.externalizing_probs_T, y=sipfc.RDLPFC_GSH_gamadj, color=sex) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("Externalizing") + ylab("GSH RDLPFC")
summary(YSR_ext_GSH_RDLPFC)
#GSH LDLPFC#
YSR_ext_GSH_LDLPFC <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.LDLPFC_GSH_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sr.externalizing_probs_T, y=sipfc.LDLPFC_GSH_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("Externalizing") + ylab("GSH LDLPFC")
summary(YSR_ext_GSH_LDLPFC)


####ASR####

ASR_data<- ASR_data %>% 
  mutate(NAA_ACC_z=scale(sipfc.ACC_NAA_gamadj, center=T, scale=T),
         NAA_MPFC_z=scale(sipfc.MPFC_NAA_gamadj, center=T, scale=T),
         NAA_DLPFC_z=scale(sipfc.DLPFC_NAA_gamadj, center=T, scale=T),
         NAA_RDLPFC_z=scale(sipfc.RDLPFC_NAA_gamadj, center=T, scale=T),
         NAA_LDLPFC_z=scale(sipfc.LDLPFC_NAA_gamadj, center=T, scale=T),
         externalizing_probs_z=scale(sr.externalizing_probs_T, center=T, scale=T))

ASR_ext_NAA_ACC_z <- lmer(data=ASR_data, externalizing_probs_z ~ NAA_ACC_z + sex + (1|lunaid))
summary(ASR_ext_NAA_ACC_z)
ASR_ext_NAA_MPFC_z <- lmer(data=ASR_data, externalizing_probs_z ~ NAA_MPFC_z + sex + (1|lunaid))
summary(ASR_ext_NAA_MPFC_z)
ASR_ext_NAA_DLPFC_z <- lmer(data=ASR_data, externalizing_probs_z ~ NAA_DLPFC_z + sex + (1|lunaid))
summary(ASR_ext_NAA_DLPFC_z)
ASR_ext_NAA_RDLPFC_z <- lmer(data=ASR_data, externalizing_probs_z ~ NAA_RDLPFC_z + sex + (1|lunaid))
summary(ASR_ext_NAA_RDLPFC_z)
ASR_ext_NAA_LDLPFC_z <- lmer(data=ASR_data, externalizing_probs_z ~ NAA_LDLPFC_z + sex + (1|lunaid))
summary(ASR_ext_NAA_LDLPFC_z)

#NAA ACC#
ASR_ext_NAA_ACC <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.ACC_NAA_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sr.externalizing_probs_T, y=sipfc.ACC_NAA_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("Externalizing") + ylab("NAA ACC")
summary(ASR_ext_NAA_ACC)

ASR_ext_NAA_ACC_age_int <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.ACC_NAA_gamadj * rest.age + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.ACC_NAA_gamadj, y=sr.externalizing_probs_T) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("NAA ACC") + ylab("Externalizing")
summary(ASR_ext_NAA_ACC_age_int)

ASR_ext_NAA_ACC_age <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.ACC_NAA_gamadj + rest.age + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.ACC_NAA_gamadj, y=sr.externalizing_probs_T) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("NAA ACC") + ylab("Externalizing")
summary(ASR_ext_NAA_ACC_age)

#NAA MPFC#
ASR_ext_NAA_MPFC <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.MPFC_NAA_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sr.externalizing_probs_T, y=sipfc.MPFC_NAA_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("Externalizing") + ylab("NAA MPFC")
summary(ASR_ext_NAA_MPFC)
#NAA DLPFC#
ASR_ext_NAA_DLPFC <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.DLPFC_NAA_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sr.externalizing_probs_T, y=sipfc.DLPFC_NAA_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("Externalizing") + ylab("NAA DLPFC")
summary(ASR_ext_NAA_DLPFC)
#NAA RDLPFC#
ASR_ext_NAA_RDLPFC <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.RDLPFC_NAA_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sr.externalizing_probs_T, y=sipfc.RDLPFC_NAA_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("Externalizing") + ylab("NAA RDLPFC")
summary(ASR_ext_NAA_RDLPFC)
#NAA LDLPFC#
ASR_ext_NAA_LDLPFC <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.LDLPFC_NAA_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sr.externalizing_probs_T, y=sipfc.LDLPFC_NAA_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("Externalizing") + ylab("NAA LDLPFC")
summary(ASR_ext_NAA_LDLPFC)

ASR_data<- ASR_data %>% 
  mutate(mI_ACC_z=scale(sipfc.ACC_mI_gamadj, center=T, scale=T),
         mI_MPFC_z=scale(sipfc.MPFC_mI_gamadj, center=T, scale=T),
         mI_DLPFC_z=scale(sipfc.DLPFC_mI_gamadj, center=T, scale=T),
         mI_RDLPFC_z=scale(sipfc.RDLPFC_mI_gamadj, center=T, scale=T),
         mI_LDLPFC_z=scale(sipfc.LDLPFC_mI_gamadj, center=T, scale=T),
         externalizing_probs_z=scale(sr.externalizing_probs_T, center=T, scale=T))

ASR_ext_mI_ACC_z <- lmer(data=ASR_data, externalizing_probs_z ~ mI_ACC_z + sex + (1|lunaid))
summary(ASR_ext_mI_ACC_z)
ASR_ext_mI_MPFC_z <- lmer(data=ASR_data, externalizing_probs_z ~ mI_MPFC_z + sex + (1|lunaid))
summary(ASR_ext_mI_MPFC_z)
ASR_ext_mI_DLPFC_z <- lmer(data=ASR_data, externalizing_probs_z ~ mI_DLPFC_z + sex + (1|lunaid))
summary(ASR_ext_mI_DLPFC_z)
ASR_ext_mI_RDLPFC_z <- lmer(data=ASR_data, externalizing_probs_z ~ mI_RDLPFC_z + sex + (1|lunaid))
summary(ASR_ext_mI_RDLPFC_z)
ASR_ext_mI_LDLPFC_z <- lmer(data=ASR_data, externalizing_probs_z ~ mI_LDLPFC_z + sex + (1|lunaid))
summary(ASR_ext_mI_LDLPFC_z)

#mI ACC#
ASR_ext_mI_ACC <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.ACC_mI_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sr.externalizing_probs_T, y=sipfc.ACC_mI_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("Externalizing") + ylab("mI ACC")
summary(ASR_ext_mI_ACC)
#mI MPFC#
ASR_ext_mI_MPFC <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.MPFC_mI_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sr.externalizing_probs_T, y=sipfc.MPFC_mI_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("Externalizing") + ylab("mI MPFC")
summary(ASR_ext_mI_MPFC)
#mI DLPFC#
ASR_ext_mI_DLPFC <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.DLPFC_mI_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sr.externalizing_probs_T, y=sipfc.DLPFC_mI_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("Externalizing") + ylab("mI DLPFC")
summary(ASR_ext_mI_DLPFC)
#mI RDLPFC#
ASR_ext_mI_RDLPFC <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.RDLPFC_mI_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sr.externalizing_probs_T, y=sipfc.RDLPFC_mI_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("Externalizing") + ylab("mI RDLPFC")
summary(ASR_ext_mI_RDLPFC)
#mI LDLPFC#
ASR_ext_mI_LDLPFC <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.LDLPFC_mI_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sr.externalizing_probs_T, y=sipfc.LDLPFC_mI_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("Externalizing") + ylab("mI LDLPFC")
summary(ASR_ext_mI_LDLPFC)

ASR_data<- ASR_data %>% 
  mutate(GSH_ACC_z=scale(sipfc.ACC_GSH_gamadj, center=T, scale=T),
         GSH_MPFC_z=scale(sipfc.MPFC_GSH_gamadj, center=T, scale=T),
         GSH_DLPFC_z=scale(sipfc.DLPFC_GSH_gamadj, center=T, scale=T),
         GSH_RDLPFC_z=scale(sipfc.RDLPFC_GSH_gamadj, center=T, scale=T),
         GSH_LDLPFC_z=scale(sipfc.LDLPFC_GSH_gamadj, center=T, scale=T),
         externalizing_probs_z=scale(sr.externalizing_probs_T, center=T, scale=T))

ASR_ext_GSH_ACC_z <- lmer(data=ASR_data, externalizing_probs_z ~ GSH_ACC_z + sex + (1|lunaid))
summary(ASR_ext_GSH_ACC_z)
ASR_ext_GSH_MPFC_z <- lmer(data=ASR_data, externalizing_probs_z ~ GSH_MPFC_z + sex + (1|lunaid))
summary(ASR_ext_GSH_MPFC_z)
ASR_ext_GSH_DLPFC_z <- lmer(data=ASR_data, externalizing_probs_z ~ GSH_DLPFC_z + sex + (1|lunaid))
summary(ASR_ext_GSH_DLPFC_z)
ASR_ext_GSH_RDLPFC_z <- lmer(data=ASR_data, externalizing_probs_z ~ GSH_RDLPFC_z + sex + (1|lunaid))
summary(ASR_ext_GSH_RDLPFC_z)
ASR_ext_GSH_LDLPFC_z <- lmer(data=ASR_data, externalizing_probs_z ~ GSH_LDLPFC_z + sex + (1|lunaid))
summary(ASR_ext_GSH_LDLPFC_z)

#GSH ACC#
ASR_ext_GSH_ACC <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.ACC_GSH_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sr.externalizing_probs_T, y=sipfc.ACC_GSH_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("Externalizing") + ylab("GSH ACC")
summary(ASR_ext_GSH_ACC)
#GSH MPFC#
ASR_ext_GSH_MPFC <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.MPFC_GSH_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sr.externalizing_probs_T, y=sipfc.MPFC_GSH_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("Externalizing") + ylab("GSH MPFC")
summary(ASR_ext_GSH_MPFC)
#GSH DLPFC#
ASR_ext_GSH_DLPFC <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.DLPFC_GSH_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sr.externalizing_probs_T, y=sipfc.DLPFC_GSH_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("Externalizing") + ylab("GSH DLPFC")
summary(ASR_ext_GSH_DLPFC)
#GSH RDLPFC#
ASR_ext_GSH_RDLPFC <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.RDLPFC_GSH_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.RDLPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("Externalizing") + ylab("GSH RDLPFC")
summary(ASR_ext_GSH_RDLPFC)
#GSH LDLPFC#
ASR_ext_GSH_LDLPFC <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.LDLPFC_GSH_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sr.externalizing_probs_T, y=sipfc.LDLPFC_GSH_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("Externalizing") + ylab("GSH LDLPFC")
summary(ASR_ext_GSH_LDLPFC)


##correlation btwn metabolites and internalizing##
lmer(data = adult, int ~ MRSI + sex)
ggplot(int, MRSI)
####YSR####

YSR_data<- YSR_data %>% 
  mutate(NAA_ACC_z=scale(sipfc.ACC_NAA_gamadj, center=T, scale=T),
         NAA_MPFC_z=scale(sipfc.MPFC_NAA_gamadj, center=T, scale=T),
         NAA_DLPFC_z=scale(sipfc.DLPFC_NAA_gamadj, center=T, scale=T),
         NAA_RDLPFC_z=scale(sipfc.RDLPFC_NAA_gamadj, center=T, scale=T),
         NAA_LDLPFC_z=scale(sipfc.LDLPFC_NAA_gamadj, center=T, scale=T),
         internalizing_probs_z=scale(sr.internalizing_probs_T, center=T, scale=T))

YSR_int_NAA_ACC_z <- lmer(data=YSR_data, internalizing_probs_z ~ NAA_ACC_z + sex + (1|lunaid))
summary(YSR_int_NAA_ACC_z)
YSR_int_NAA_MPFC_z <- lmer(data=YSR_data, internalizing_probs_z ~ NAA_MPFC_z + sex + (1|lunaid))
summary(YSR_int_NAA_MPFC_z)
YSR_int_NAA_DLPFC_z <- lmer(data=YSR_data, internalizing_probs_z ~ NAA_DLPFC_z + sex + (1|lunaid))
summary(YSR_int_NAA_DLPFC_z)
YSR_int_NAA_RDLPFC_z <- lmer(data=YSR_data, internalizing_probs_z ~ NAA_RDLPFC_z + sex + (1|lunaid))
summary(YSR_int_NAA_RDLPFC_z)
YSR_int_NAA_LDLPFC_z <- lmer(data=YSR_data, internalizing_probs_z ~ NAA_LDLPFC_z + sex + (1|lunaid))
summary(YSR_int_NAA_LDLPFC_z)

#NAA ACC#
YSR_int_NAA_ACC <- lmer(data=YSR_data, sr.internalizing_probs_T ~ sipfc.ACC_NAA_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sr.internalizing_probs_T, y=sipfc.ACC_NAA_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("internalizing") + ylab("NAA ACC")
summary(YSR_int_NAA_ACC)
#NAA MPFC#
YSR_int_NAA_MPFC <- lmer(data=YSR_data, sr.internalizing_probs_T ~ sipfc.MPFC_NAA_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sr.internalizing_probs_T, y=sipfc.MPFC_NAA_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("internalizing") + ylab("NAA MPFC")
summary(YSR_int_NAA_MPFC)
#NAA DLPFC#
YSR_int_NAA_DLPFC <- lmer(data=YSR_data, sr.internalizing_probs_T ~ sipfc.DLPFC_NAA_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sr.internalizing_probs_T, y=sipfc.DLPFC_NAA_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("internalizing") + ylab("NAA DLPFC")
summary(YSR_int_NAA_DLPFC)
#NAA RDLPFC#
YSR_int_NAA_RDLPFC <- lmer(data=YSR_data, sr.internalizing_probs_T ~ sipfc.RDLPFC_NAA_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sr.internalizing_probs_T, y=sipfc.RDLPFC_NAA_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("internalizing") + ylab("NAA RDLPFC")
summary(YSR_int_NAA_RDLPFC)
#NAA LDLPFC#
YSR_int_NAA_LDLPFC <- lmer(data=YSR_data, sr.internalizing_probs_T ~ sipfc.LDLPFC_NAA_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sr.internalizing_probs_T, y=sipfc.LDLPFC_NAA_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("internalizing") + ylab("NAA LDLPFC")
summary(YSR_int_NAA_LDLPFC)

YSR_data<- YSR_data %>% 
  mutate(mI_ACC_z=scale(sipfc.ACC_mI_gamadj, center=T, scale=T),
         mI_MPFC_z=scale(sipfc.MPFC_mI_gamadj, center=T, scale=T),
         mI_DLPFC_z=scale(sipfc.DLPFC_mI_gamadj, center=T, scale=T),
         mI_RDLPFC_z=scale(sipfc.RDLPFC_mI_gamadj, center=T, scale=T),
         mI_LDLPFC_z=scale(sipfc.LDLPFC_mI_gamadj, center=T, scale=T),
         internalizing_probs_z=scale(sr.internalizing_probs_T, center=T, scale=T))

YSR_int_mI_ACC_z <- lmer(data=YSR_data, internalizing_probs_z ~ mI_ACC_z + sex + (1|lunaid))
summary(YSR_int_mI_ACC_z)
YSR_int_mI_MPFC_z <- lmer(data=YSR_data, internalizing_probs_z ~ mI_MPFC_z + sex + (1|lunaid))
summary(YSR_int_mI_MPFC_z)
YSR_int_mI_DLPFC_z <- lmer(data=YSR_data, internalizing_probs_z ~ mI_DLPFC_z + sex + (1|lunaid))
summary(YSR_int_mI_DLPFC_z)
YSR_int_mI_RDLPFC_z <- lmer(data=YSR_data, internalizing_probs_z ~ mI_RDLPFC_z + sex + (1|lunaid))
summary(YSR_int_mI_RDLPFC_z)
YSR_int_mI_LDLPFC_z <- lmer(data=YSR_data, internalizing_probs_z ~ mI_LDLPFC_z + sex + (1|lunaid))
summary(YSR_int_mI_LDLPFC_z)

#mI ACC#
YSR_int_mI_ACC <- lmer(data=YSR_data, sr.internalizing_probs_T ~ sipfc.ACC_mI_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sr.internalizing_probs_T, y=sipfc.ACC_mI_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("internalizing") + ylab("mI ACC")
summary(YSR_int_mI_ACC)
#mI MPFC#
YSR_int_mI_MPFC <- lmer(data=YSR_data, sr.internalizing_probs_T ~ sipfc.MPFC_mI_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sr.internalizing_probs_T, y=sipfc.MPFC_mI_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("internalizing") + ylab("mI MPFC")
summary(YSR_int_mI_MPFC)
#mI DLPFC#
YSR_int_mI_DLPFC <- lmer(data=YSR_data, sr.internalizing_probs_T ~ sipfc.DLPFC_mI_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sr.internalizing_probs_T, y=sipfc.DLPFC_mI_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("internalizing") + ylab("mI DLPFC")
summary(YSR_int_mI_DLPFC)
#mI RDLPFC#
YSR_int_mI_RDLPFC <- lmer(data=YSR_data, sr.internalizing_probs_T ~ sipfc.RDLPFC_mI_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sr.internalizing_probs_T, y=sipfc.RDLPFC_mI_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("internalizing") + ylab("mI RDLPFC")
summary(YSR_int_mI_RDLPFC)
#mI LDLPFC#
YSR_int_mI_LDLPFC <- lmer(data=YSR_data, sr.internalizing_probs_T ~ sipfc.LDLPFC_mI_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sr.internalizing_probs_T, y=sipfc.LDLPFC_mI_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("internalizing") + ylab("mI LDLPFC")
summary(YSR_int_mI_LDLPFC)

YSR_data<- YSR_data %>% 
  mutate(GSH_ACC_z=scale(sipfc.ACC_GSH_gamadj, center=T, scale=T),
         GSH_MPFC_z=scale(sipfc.MPFC_GSH_gamadj, center=T, scale=T),
         GSH_DLPFC_z=scale(sipfc.DLPFC_GSH_gamadj, center=T, scale=T),
         GSH_RDLPFC_z=scale(sipfc.RDLPFC_GSH_gamadj, center=T, scale=T),
         GSH_LDLPFC_z=scale(sipfc.LDLPFC_GSH_gamadj, center=T, scale=T),
         internalizing_probs_z=scale(sr.internalizing_probs_T, center=T, scale=T))

YSR_int_GSH_ACC_z <- lmer(data=YSR_data, internalizing_probs_z ~ GSH_ACC_z + sex + (1|lunaid))
summary(YSR_int_GSH_ACC_z)
YSR_int_GSH_MPFC_z <- lmer(data=YSR_data, internalizing_probs_z ~ GSH_MPFC_z + sex + (1|lunaid))
summary(YSR_int_GSH_MPFC_z)
YSR_int_GSH_DLPFC_z <- lmer(data=YSR_data, internalizing_probs_z ~ GSH_DLPFC_z + sex + (1|lunaid))
summary(YSR_int_GSH_DLPFC_z)
YSR_int_GSH_RDLPFC_z <- lmer(data=YSR_data, internalizing_probs_z ~ GSH_RDLPFC_z + sex + (1|lunaid))
summary(YSR_int_GSH_RDLPFC_z)
YSR_int_GSH_LDLPFC_z <- lmer(data=YSR_data, internalizing_probs_z ~ GSH_LDLPFC_z + sex + (1|lunaid))
summary(YSR_int_GSH_LDLPFC_z)

#GSH ACC#
YSR_int_GSH_ACC <- lmer(data=YSR_data, sr.internalizing_probs_T ~ sipfc.ACC_GSH_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sr.internalizing_probs_T, y=sipfc.ACC_GSH_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("internalizing") + ylab("GSH ACC")
summary(YSR_int_GSH_ACC)
#GSH MPFC#
YSR_int_GSH_MPFC <- lmer(data=YSR_data, sr.internalizing_probs_T ~ sipfc.MPFC_GSH_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sr.internalizing_probs_T, y=sipfc.MPFC_GSH_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("internalizing") + ylab("GSH MPFC")
summary(YSR_int_GSH_MPFC)
#GSH DLPFC#
YSR_int_GSH_DLPFC <- lmer(data=YSR_data, sr.internalizing_probs_T ~ sipfc.DLPFC_GSH_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sr.internalizing_probs_T, y=sipfc.DLPFC_GSH_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("internalizing") + ylab("GSH DLPFC")
summary(YSR_int_GSH_DLPFC)
#GSH RDLPFC#
YSR_int_GSH_RDLPFC <- lmer(data=YSR_data, sr.internalizing_probs_T ~ sipfc.RDLPFC_GSH_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sr.internalizing_probs_T, y=sipfc.RDLPFC_GSH_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("internalizing") + ylab("GSH RDLPFC")
summary(YSR_int_GSH_RDLPFC)
#GSH LDLPFC#
YSR_int_GSH_LDLPFC <- lmer(data=YSR_data, sr.internalizing_probs_T ~ sipfc.LDLPFC_GSH_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sr.internalizing_probs_T, y=sipfc.LDLPFC_GSH_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("internalizing") + ylab("GSH LDLPFC")
summary(YSR_int_GSH_LDLPFC)


####ASR####

ASR_data<- ASR_data %>% 
  mutate(NAA_ACC_z=scale(sipfc.ACC_NAA_gamadj, center=T, scale=T),
         NAA_MPFC_z=scale(sipfc.MPFC_NAA_gamadj, center=T, scale=T),
         NAA_DLPFC_z=scale(sipfc.DLPFC_NAA_gamadj, center=T, scale=T),
         NAA_RDLPFC_z=scale(sipfc.RDLPFC_NAA_gamadj, center=T, scale=T),
         NAA_LDLPFC_z=scale(sipfc.LDLPFC_NAA_gamadj, center=T, scale=T),
         internalizing_probs_z=scale(sr.internalizing_probs_T, center=T, scale=T))

ASR_int_NAA_ACC_z <- lmer(data=ASR_data, internalizing_probs_z ~ NAA_ACC_z + sex + (1|lunaid))
summary(ASR_int_NAA_ACC_z)
ASR_int_NAA_MPFC_z <- lmer(data=ASR_data, internalizing_probs_z ~ NAA_MPFC_z + sex + (1|lunaid))
summary(ASR_int_NAA_MPFC_z)
ASR_int_NAA_DLPFC_z <- lmer(data=ASR_data, internalizing_probs_z ~ NAA_DLPFC_z + sex + (1|lunaid))
summary(ASR_int_NAA_DLPFC_z)
ASR_int_NAA_RDLPFC_z <- lmer(data=ASR_data, internalizing_probs_z ~ NAA_RDLPFC_z + sex + (1|lunaid))
summary(ASR_int_NAA_RDLPFC_z)
ASR_int_NAA_LDLPFC_z <- lmer(data=ASR_data, internalizing_probs_z ~ NAA_LDLPFC_z + sex + (1|lunaid))
summary(ASR_int_NAA_LDLPFC_z)

#NAA ACC#
ASR_int_NAA_ACC <- lmer(data=ASR_data, sr.internalizing_probs_T ~ sipfc.ACC_NAA_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sr.internalizing_probs_T, y=sipfc.ACC_NAA_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("internalizing") + ylab("NAA ACC")
summary(ASR_int_NAA_ACC)
#NAA MPFC#
ASR_int_NAA_MPFC <- lmer(data=ASR_data, sr.internalizing_probs_T ~ sipfc.MPFC_NAA_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sr.internalizing_probs_T, y=sipfc.MPFC_NAA_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("internalizing") + ylab("NAA MPFC")
summary(ASR_int_NAA_MPFC)
#NAA DLPFC#
ASR_int_NAA_DLPFC <- lmer(data=ASR_data, sr.internalizing_probs_T ~ sipfc.DLPFC_NAA_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sr.internalizing_probs_T, y=sipfc.DLPFC_NAA_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("internalizing") + ylab("NAA DLPFC")
summary(ASR_int_NAA_DLPFC)
#NAA RDLPFC#
ASR_int_NAA_RDLPFC <- lmer(data=ASR_data, sr.internalizing_probs_T ~ sipfc.RDLPFC_NAA_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sr.internalizing_probs_T, y=sipfc.RDLPFC_NAA_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("internalizing") + ylab("NAA RDLPFC")
summary(ASR_int_NAA_RDLPFC)
#NAA LDLPFC#
ASR_int_NAA_LDLPFC <- lmer(data=ASR_data, sr.internalizing_probs_T ~ sipfc.LDLPFC_NAA_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sr.internalizing_probs_T, y=sipfc.LDLPFC_NAA_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("internalizing") + ylab("NAA LDLPFC")
summary(ASR_int_NAA_LDLPFC)

ASR_data<- ASR_data %>% 
  mutate(mI_ACC_z=scale(sipfc.ACC_mI_gamadj, center=T, scale=T),
         mI_MPFC_z=scale(sipfc.MPFC_mI_gamadj, center=T, scale=T),
         mI_DLPFC_z=scale(sipfc.DLPFC_mI_gamadj, center=T, scale=T),
         mI_RDLPFC_z=scale(sipfc.RDLPFC_mI_gamadj, center=T, scale=T),
         mI_LDLPFC_z=scale(sipfc.LDLPFC_mI_gamadj, center=T, scale=T),
         internalizing_probs_z=scale(sr.internalizing_probs_T, center=T, scale=T))

ASR_int_mI_ACC_z <- lmer(data=ASR_data, internalizing_probs_z ~ mI_ACC_z + sex + (1|lunaid))
summary(ASR_int_mI_ACC_z)
ASR_int_mI_MPFC_z <- lmer(data=ASR_data, internalizing_probs_z ~ mI_MPFC_z + sex + (1|lunaid))
summary(ASR_int_mI_MPFC_z)
ASR_int_mI_DLPFC_z <- lmer(data=ASR_data, internalizing_probs_z ~ mI_DLPFC_z + sex + (1|lunaid))
summary(ASR_int_mI_DLPFC_z)
ASR_int_mI_RDLPFC_z <- lmer(data=ASR_data, internalizing_probs_z ~ mI_RDLPFC_z + sex + (1|lunaid))
summary(ASR_int_mI_RDLPFC_z)
ASR_int_mI_LDLPFC_z <- lmer(data=ASR_data, internalizing_probs_z ~ mI_LDLPFC_z + sex + (1|lunaid))
summary(ASR_int_mI_LDLPFC_z)

#mI ACC#
ASR_int_mI_ACC <- lmer(data=ASR_data, sr.internalizing_probs_T ~ sipfc.ACC_mI_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sr.internalizing_probs_T, y=sipfc.ACC_mI_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("internalizing") + ylab("mI ACC")
summary(ASR_int_mI_ACC)
#mI MPFC#
ASR_int_mI_MPFC <- lmer(data=ASR_data, sr.internalizing_probs_T ~ sipfc.MPFC_mI_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sr.internalizing_probs_T, y=sipfc.MPFC_mI_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("internalizing") + ylab("mI MPFC")
summary(ASR_int_mI_MPFC)
#mI DLPFC#
ASR_int_mI_DLPFC <- lmer(data=ASR_data, sr.internalizing_probs_T ~ sipfc.DLPFC_mI_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sr.internalizing_probs_T, y=sipfc.DLPFC_mI_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("internalizing") + ylab("mI DLPFC")
summary(ASR_int_mI_DLPFC)
#mI RDLPFC#
ASR_int_mI_RDLPFC <- lmer(data=ASR_data, sr.internalizing_probs_T ~ sipfc.RDLPFC_mI_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sr.internalizing_probs_T, y=sipfc.RDLPFC_mI_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("internalizing") + ylab("mI RDLPFC")
summary(ASR_int_mI_RDLPFC)
#mI LDLPFC#
ASR_int_mI_LDLPFC <- lmer(data=ASR_data, sr.internalizing_probs_T ~ sipfc.LDLPFC_mI_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sr.internalizing_probs_T, y=sipfc.LDLPFC_mI_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("internalizing") + ylab("mI LDLPFC")
summary(ASR_int_mI_LDLPFC)

ASR_data<- ASR_data %>% 
  mutate(GSH_ACC_z=scale(sipfc.ACC_GSH_gamadj, center=T, scale=T),
         GSH_MPFC_z=scale(sipfc.MPFC_GSH_gamadj, center=T, scale=T),
         GSH_DLPFC_z=scale(sipfc.DLPFC_GSH_gamadj, center=T, scale=T),
         GSH_RDLPFC_z=scale(sipfc.RDLPFC_GSH_gamadj, center=T, scale=T),
         GSH_LDLPFC_z=scale(sipfc.LDLPFC_GSH_gamadj, center=T, scale=T),
         internalizing_probs_z=scale(sr.internalizing_probs_T, center=T, scale=T))

ASR_int_GSH_ACC_z <- lmer(data=ASR_data, internalizing_probs_z ~ GSH_ACC_z + sex + (1|lunaid))
summary(ASR_int_GSH_ACC_z)
ASR_int_GSH_MPFC_z <- lmer(data=ASR_data, internalizing_probs_z ~ GSH_MPFC_z + sex + (1|lunaid))
summary(ASR_int_GSH_MPFC_z)
ASR_int_GSH_DLPFC_z <- lmer(data=ASR_data, internalizing_probs_z ~ GSH_DLPFC_z + sex + (1|lunaid))
summary(ASR_int_GSH_DLPFC_z)
ASR_int_GSH_RDLPFC_z <- lmer(data=ASR_data, internalizing_probs_z ~ GSH_RDLPFC_z + sex + (1|lunaid))
summary(ASR_int_GSH_RDLPFC_z)
ASR_int_GSH_LDLPFC_z <- lmer(data=ASR_data, internalizing_probs_z ~ GSH_LDLPFC_z + sex + (1|lunaid))
summary(ASR_int_GSH_LDLPFC_z)

#GSH ACC#
ASR_int_GSH_ACC <- lmer(data=ASR_data, sr.internalizing_probs_T ~ sipfc.ACC_GSH_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sr.internalizing_probs_T, y=sipfc.ACC_GSH_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("internalizing") + ylab("GSH ACC")
summary(ASR_int_GSH_ACC)
#GSH MPFC#
ASR_int_GSH_MPFC <- lmer(data=ASR_data, sr.internalizing_probs_T ~ sipfc.MPFC_GSH_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sr.internalizing_probs_T, y=sipfc.MPFC_GSH_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("internalizing") + ylab("GSH MPFC")
summary(ASR_int_GSH_MPFC)
#GSH DLPFC#
ASR_int_GSH_DLPFC <- lmer(data=ASR_data, sr.internalizing_probs_T ~ sipfc.DLPFC_GSH_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sr.internalizing_probs_T, y=sipfc.DLPFC_GSH_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("internalizing") + ylab("GSH DLPFC")
summary(ASR_int_GSH_DLPFC)
#GSH RDLPFC#
ASR_int_GSH_RDLPFC <- lmer(data=ASR_data, sr.internalizing_probs_T ~ sipfc.RDLPFC_GSH_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sr.internalizing_probs_T, y=sipfc.RDLPFC_GSH_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("internalizing") + ylab("GSH RDLPFC")
summary(ASR_int_GSH_RDLPFC)
#GSH LDLPFC#
ASR_int_GSH_LDLPFC <- lmer(data=ASR_data, sr.internalizing_probs_T ~ sipfc.LDLPFC_GSH_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sr.internalizing_probs_T, y=sipfc.LDLPFC_GSH_gamadj, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("internalizing") + ylab("GSH LDLPFC")
summary(ASR_int_GSH_LDLPFC)
