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

#1.0 Metabolites ~ Age ####

##1.1 NAA####

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
NAA_ACC <- lmer(data=merge7T,sipfc.ACC_NAA_gamadj ~ rest.age + (1|lunaid))
summary(NAA_ACC)

merge7T<- merge7t %>% 
  mutate(NAA_ACC_z=scale(sipfc.ACC_NAA_gamadj, center=T, scale=T),
         rest.age_z=scale(rest.age, center=T, scale=T))
NAA_ACC_z <- lmer(data=merge7T, NAA_ACC_z ~ rest.age_z + (1|lunaid))
summary(NAA_ACC_z)

#ACC INV
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.ACC_NAA_gamadj) + geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + theme_classic(base_size=15) +xlab("Age") +ylab("ACC NAA")
NAA_ACC_inv <- lmer(data=merge7T,sipfc.ACC_NAA_gamadj ~ rest.invage + (1|lunaid))
summary(NAA_ACC_inv)
merge7T<- merge7T %>% 
  mutate(NAA_ACC_inv_z=scale(sipfc.ACC_NAA_gamadj, center=T, scale=T),
         rest.invage_z=scale(rest.invage, center=T, scale=T))
NAA_ACC_inv_z <- lmer(data=merge7T, NAA_ACC_z ~ rest.invage_z + (1|lunaid))
summary(NAA_ACC_inv_z)
#ACC quad
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.ACC_gamadj) + geom_point() 
NAA_ACC_quadage <- lmer(data=merge7T, sipfc.ACC_NAA_gamadj ~ rest.age + rest.age2 + (1|lunaid))
summary(NAA_ACC_quadage)  
AIC(NAA_ACC)
AIC(NAA_ACC_inv) 
AIC(NAA_ACC_quadage)


#MPFC
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.MPFC_NAA_gamadj) + geom_point() + geom_smooth + stat_smooth() + theme_classic(base_size=15) +xlab("Age") +ylab("MPFC NAA")
NAA_MPFC <- lmer(data=merge7T,sipfc.MPFC_NAA_gamadj ~ rest.age  + (1|lunaid))
summary(NAA_MPFC)
#MPFC INV
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.MPFC_NAA_gamadj) + geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T)+ theme_classic(base_size=15) +xlab("Age") +ylab("MPFC NAA")
NAA_MPFC_inv <- lmer(data=merge7T,sipfc.MPFC_NAA_gamadj ~ rest.invage + (1|lunaid))
summary(NAA_MPFC_inv)

NAA_MPFC_inv_z <- lmer(data=merge7T, NAA_MPFC_inv_z ~ rest.invage_z  + (1|lunaid))
summary(NAA_MPFC_inv_z)

#MPFC quad
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.MPFC_gamadj) + geom_point() + 
  NAA_MPFC_quadage <- lmer(data=merge7T, sipfc.MPFC_NAA_gamadj ~ rest.age + rest.age2  + (1|lunaid))
summary(NAA_MPFC_quadage)  
AIC(NAA_MPFC)
AIC(NAA_MPFC_inv) 
AIC(NAA_MPFC_quadage)

#DLPFC
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.DLPFC_NAA_gamadj) + geom_point() + stat_smooth()+ theme_classic(base_size=15) +xlab("Age") +ylab("DLPFC NAA")
NAA_DLPFC <- lmer(data=merge7T,sipfc.DLPFC_NAA_gamadj ~ rest.age + (1|lunaid))
summary(NAA_DLPFC)
#DLPFC INV
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.DLPFC_NAA_gamadj) + geom_point() +  geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + theme_classic(base_size=15) +xlab("Age") +ylab("DLPFC NAA")
NAA_DLPFC_inv <- lmer(data=merge7T,sipfc.DLPFC_NAA_gamadj ~ rest.invage + (1|lunaid))
summary(NAA_DLPFC_inv)
AIC(NAA_DLPFC, NAA_DLPFC_inv)

NAA_DLPFC_inv_z <- lmer(data=merge7T, NAA_DLPFC_inv_z ~ rest.invage_z + (1|lunaid))
summary(NAA_DLPFC_inv_z)

#DLPFC quad
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.DLPFC_gamadj) + geom_point() 
NAA_DLPFC_quadage <- lmer(data=merge7T, sipfc.DLPFC_NAA_gamadj ~ rest.age + rest.age2 +   + (1|lunaid))
summary(NAA_DLPFC_quadage)  
AIC(NAA_DLPFC)
AIC(NAA_DLPFC_inv) 
AIC(NAA_DLPFC_quadage)
#RDLPFC
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.RDLPFC_NAA_gamadj) + geom_point() + stat_smooth()+ theme_classic(base_size=15) +xlab("Age") +ylab("RDLPFC NAA")
NAA_RDLPFC <- lmer(data=merge7T,sipfc.RDLPFC_NAA_gamadj ~ rest.age + (1|lunaid))
summary(NAA_RDLPFC)
#RDLPFC INV
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.RDLPFC_NAA_gamadj) + geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + theme_classic(base_size=15) +xlab("Age") +ylab("RDLPFC NAA")
NAA_RDLPFC_inv <- lmer(data=merge7T,sipfc.RDLPFC_NAA_gamadj ~ rest.invage + (1|lunaid))
summary(NAA_RDLPFC_inv)

NAA_RDLPFC_inv_z <- lmer(data=merge7T, NAA_RDLPFC_inv_z ~ rest.invage_z + (1|lunaid))
summary(NAA_RDLPFC_inv_z)

#RDLPFC quad
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.RDLPFC_gamadj) + geom_point() + 
  NAA_RDLPFC_quadage <- lmer(data=merge7T, sipfc.RDLPFC_NAA_gamadj ~ rest.age + rest.age2 +   + (1|lunaid))
summary(NAA_RDLPFC_quadage)  
AIC(NAA_RDLPFC)
AIC(NAA_RDLPFC_inv) 
AIC(NAA_RDLPFC_quadage)
#LDLPFC
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.LDLPFC_NAA_gamadj) + geom_point() + stat_smooth()+ theme_classic(base_size=15) +xlab("Age") +ylab("LDLPFC NAA")
NAA_LDLPFC <- lmer(data=merge7T,sipfc.LDLPFC_NAA_gamadj ~ rest.age + (1|lunaid))
summary(NAA_LDLPFC)
#LDLPFC INV
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.LDLPFC_NAA_gamadj) + geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T)+ theme_classic(base_size=15) +xlab("Age") +ylab("LDLPFC NAA")
NAA_LDLPFC_inv <- lmer(data=merge7T,sipfc.LDLPFC_NAA_gamadj ~ rest.invage + (1|lunaid))
summary(NAA_LDLPFC_inv)

NAA_LDLPFC_inv_z <- lmer(data=merge7T, NAA_LDLPFC_inv_z ~ rest.invage_z + (1|lunaid))
summary(NAA_LDLPFC_inv_z)

#LDLPFC quad
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.LDLPFC_gamadj) + geom_point() + 
  NAA_LDLPFC_quadage <- lmer(data=merge7T, sipfc.LDLPFC_NAA_gamadj ~ rest.age + rest.age2 +   + (1|lunaid))
summary(NAA_LDLPFC_quadage)  
AIC(NAA_LDLPFC)
AIC(NAA_LDLPFC_inv) 
AIC(NAA_LDLPFC_quadage)

##1.2 Myoinositol####
merge7T<- merge7T %>% 
  mutate(mI_ACC_inv_z=scale(sipfc.ACC_mI_gamadj, center=T, scale=T),
         mI_MPFC_inv_z=scale(sipfc.MPFC_mI_gamadj, center=T, scale=T),
         mI_DLPFC_inv_z=scale(sipfc.DLPFC_mI_gamadj, center=T, scale=T),
         mI_RDLPFC_inv_z=scale(sipfc.RDLPFC_mI_gamadj, center=T, scale=T),
         mI_LDLPFC_inv_z=scale(sipfc.LDLPFC_mI_gamadj, center=T, scale=T),
         rest.age_z=scale(rest.age, center=T, scale=T), 
         rest.invage_z=scale(rest.invage, center=T, scale=T))

mI_ACC_inv_z <- lmer(data=merge7T, mI_ACC_inv_z ~ rest.invage_z + (1|lunaid))
summary(mI_ACC_inv_z)
mI_MPFC_inv_z <- lmer(data=merge7T, mI_MPFC_inv_z ~ rest.invage_z + (1|lunaid))
summary(mI_MPFC_inv_z)
mI_DLPFC_inv_z <- lmer(data=merge7T, mI_DLPFC_inv_z ~ rest.invage_z + (1|lunaid))
summary(mI_DLPFC_inv_z)
mI_RDLPFC_inv_z <- lmer(data=merge7T, mI_RDLPFC_inv_z ~ rest.invage_z + (1|lunaid))
summary(mI_RDLPFC_inv_z)
mI_LDLPFC_inv_z <- lmer(data=merge7T, mI_LDLPFC_inv_z ~ rest.invage_z + (1|lunaid))
summary(mI_LDLPFC_inv_z)

#ACC
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.ACC_mI_gamadj) + geom_point() + stat_smooth()+ theme_classic(base_size=15) +xlab("Age") +ylab("ACC mI")
mI_ACC <- lmer(data=merge7T,sipfc.ACC_mI_gamadj ~ rest.age + (1|lunaid))
summary(mI_ACC)
#ACC INV
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.ACC_mI_gamadj) + geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + theme_classic(base_size=15) +xlab("Age") +ylab("ACC mI")
mI_ACC_inv <- lmer(data=merge7T,sipfc.ACC_mI_gamadj ~ rest.invage + (1|lunaid))
summary(mI_ACC_inv)
#ACC quad
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.ACC_mI_gamadj) + geom_point() 
mI_ACC_quadage <- lmer(data=merge7T, sipfc.ACC_mI_gamadj ~ rest.age + rest.age2 +   + (1|lunaid))
summary(mI_ACC_quadage)  
AIC(mI_ACC)
AIC(mI_ACC_inv) 
AIC(mI_ACC_quadage)

#MPFC
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.MPFC_mI_gamadj) + geom_point() + stat_smooth() + theme_classic(base_size=15) +xlab("Age") +ylab("MPFC mI")
mI_MPFC <- lmer(data=merge7T,sipfc.MPFC_mI_gamadj ~ rest.age + (1|lunaid))
summary(mI_MPFC)
#MPFC INV
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.MPFC_mI_gamadj) + geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T)+ theme_classic(base_size=15) +xlab("Age") +ylab("MPFC mI")
mI_MPFC_inv <- lmer(data=merge7T,sipfc.MPFC_mI_gamadj ~ rest.invage + (1|lunaid))
summary(mI_MPFC_inv)
#MPFC quad
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.MPFC_gamadj) + geom_point() + 
  mI_MPFC_quadage <- lmer(data=merge7T, sipfc.MPFC_mI_gamadj ~ rest.age + rest.age2 +   + (1|lunaid))
summary(mI_MPFC_quadage)  
AIC(mI_MPFC)
AIC(mI_MPFC_inv) 
AIC(mI_MPFC_quadage)

#DLPFC
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.DLPFC_mI_gamadj) + geom_point() + stat_smooth()+ theme_classic(base_size=15) +xlab("Age") +ylab("DLPFC mI")
mI_DLPFC <- lmer(data=merge7T,sipfc.DLPFC_mI_gamadj ~ rest.age + (1|lunaid))
summary(mI_DLPFC)
#DLPFC INV
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.DLPFC_mI_gamadj) + geom_point() +  geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + theme_classic(base_size=15) +xlab("Age") +ylab("DLPFC mI")
mI_DLPFC_inv <- lmer(data=merge7T,sipfc.DLPFC_mI_gamadj ~ rest.invage + (1|lunaid))
summary(mI_DLPFC_inv)
AIC(mI_DLPFC, mI_DLPFC_inv)
#DLPFC quad
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.DLPFC_gamadj) + geom_point() 
mI_DLPFC_quadage <- lmer(data=merge7T, sipfc.DLPFC_mI_gamadj ~ rest.age + rest.age2 +   + (1|lunaid))
summary(mI_DLPFC_quadage)  
AIC(mI_DLPFC)
AIC(mI_DLPFC_inv) 
AIC(mI_DLPFC_quadage)
#RDLPFC
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.RDLPFC_mI_gamadj) + geom_point() + stat_smooth()+ theme_classic(base_size=15) +xlab("Age") +ylab("RDLPFC mI")
mI_RDLPFC <- lmer(data=merge7T,sipfc.RDLPFC_mI_gamadj ~ rest.age + (1|lunaid))
summary(mI_RDLPFC)
#RDLPFC INV
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.RDLPFC_mI_gamadj) + geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + theme_classic(base_size=15) +xlab("Age") +ylab("RDLPFC mI")
mI_RDLPFC_inv <- lmer(data=merge7T,sipfc.RDLPFC_mI_gamadj ~ rest.invage + (1|lunaid))
summary(mI_RDLPFC_inv)
#RDLPFC quad
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.RDLPFC_gamadj) + geom_point() + 
  mI_RDLPFC_quadage <- lmer(data=merge7T, sipfc.RDLPFC_mI_gamadj ~ rest.age + rest.age2 +   + (1|lunaid))
summary(mI_RDLPFC_quadage)  
AIC(mI_RDLPFC)
AIC(mI_RDLPFC_inv) 
AIC(mI_RDLPFC_quadage)
#LDLPFC
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.LDLPFC_mI_gamadj) + geom_point() + stat_smooth()+ theme_classic(base_size=15) +xlab("Age") +ylab("LDLPFC mI")
mI_LDLPFC <- lmer(data=merge7T,sipfc.LDLPFC_mI_gamadj ~ rest.age + (1|lunaid))
summary(mI_LDLPFC)
#LDLPFC INV
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.LDLPFC_mI_gamadj) + geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T)+ theme_classic(base_size=15) +xlab("Age") +ylab("LDLPFC mI")
mI_LDLPFC_inv <- lmer(data=merge7T,sipfc.LDLPFC_mI_gamadj ~ rest.invage + (1|lunaid))
summary(mI_LDLPFC_inv)
#LDLPFC quad
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.LDLPFC_gamadj) + geom_point() + 
  mI_LDLPFC_quadage <- lmer(data=merge7T, sipfc.LDLPFC_mI_gamadj ~ rest.age + rest.age2 +   + (1|lunaid))
summary(mI_LDLPFC_quadage)  
AIC(mI_LDLPFC)
AIC(mI_LDLPFC_inv) 
AIC(mI_LDLPFC_quadage)

##1.3 Glutathione####
merge7T<- merge7T %>% 
  mutate(GSH_ACC_inv_z=scale(sipfc.ACC_GSH_gamadj, center=T, scale=T),
         GSH_MPFC_inv_z=scale(sipfc.MPFC_GSH_gamadj, center=T, scale=T),
         GSH_DLPFC_inv_z=scale(sipfc.DLPFC_GSH_gamadj, center=T, scale=T),
         GSH_RDLPFC_inv_z=scale(sipfc.RDLPFC_GSH_gamadj, center=T, scale=T),
         GSH_LDLPFC_inv_z=scale(sipfc.LDLPFC_GSH_gamadj, center=T, scale=T),
         rest.age_z=scale(rest.age, center=T, scale=T), 
         rest.invage_z=scale(rest.invage, center=T, scale=T))

GSH_ACC_inv_z <- lmer(data=merge7T, GSH_ACC_inv_z ~ rest.invage_z + (1|lunaid))
summary(GSH_ACC_inv_z)
GSH_MPFC_inv_z <- lmer(data=merge7T, GSH_MPFC_inv_z ~ rest.invage_z + (1|lunaid))
summary(GSH_MPFC_inv_z)
GSH_DLPFC_inv_z <- lmer(data=merge7T, GSH_DLPFC_inv_z ~ rest.invage_z + (1|lunaid))
summary(GSH_DLPFC_inv_z)
GSH_RDLPFC_inv_z <- lmer(data=merge7T, GSH_RDLPFC_inv_z ~ rest.invage_z + (1|lunaid))
summary(GSH_RDLPFC_inv_z)
GSH_LDLPFC_inv_z <- lmer(data=merge7T, GSH_LDLPFC_inv_z ~ rest.invage_z + (1|lunaid))
summary(GSH_LDLPFC_inv_z)
#ACC
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.ACC_GSH_gamadj) + geom_point() + stat_smooth()+ theme_classic(base_size=15) +xlab("Age") +ylab("ACC GSH")
GSH_ACC <- lmer(data=merge7T,sipfc.ACC_GSH_gamadj ~ rest.age + (1|lunaid))
summary(GSH_ACC)
#ACC INV
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.ACC_GSH_gamadj) + geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + theme_classic(base_size=15) +xlab("Age") +ylab("ACC GSH")
GSH_ACC_inv <- lmer(data=merge7T,sipfc.ACC_GSH_gamadj ~ rest.invage + (1|lunaid))
summary(GSH_ACC_inv)
#ACC quad
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.ACC_GSH_gamadj) + geom_point() 
GSH_ACC_quadage <- lmer(data=merge7T, sipfc.ACC_GSH_gamadj ~ rest.age + rest.age2 +   + (1|lunaid))
summary(GSH_ACC_quadage)  
AIC(GSH_ACC)
AIC(GSH_ACC_inv) 
AIC(GSH_ACC_quadage)

#MPFC
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.MPFC_GSH_gamadj) + geom_point() + stat_smooth() + theme_classic(base_size=15) +xlab("Age") +ylab("MPFC GSH")
GSH_MPFC <- lmer(data=merge7T,sipfc.MPFC_GSH_gamadj ~ rest.age + (1|lunaid))
summary(GSH_MPFC)
#MPFC INV
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.MPFC_GSH_gamadj) + geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T)+ theme_classic(base_size=15) +xlab("Age") +ylab("MPFC GSH")
GSH_MPFC_inv <- lmer(data=merge7T,sipfc.MPFC_GSH_gamadj ~ rest.invage + (1|lunaid))
summary(GSH_MPFC_inv)
#MPFC quad
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.MPFC_gamadj) + geom_point() + 
  GSH_MPFC_quadage <- lmer(data=merge7T, sipfc.MPFC_GSH_gamadj ~ rest.age + rest.age2 +   + (1|lunaid))
summary(GSH_MPFC_quadage)  
AIC(GSH_MPFC)
AIC(GSH_MPFC_inv) 
AIC(GSH_MPFC_quadage)

#DLPFC
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.DLPFC_GSH_gamadj) + geom_point() + stat_smooth()+ theme_classic(base_size=15) +xlab("Age") +ylab("DLPFC GSH")
GSH_DLPFC <- lmer(data=merge7T,sipfc.DLPFC_GSH_gamadj ~ rest.age + (1|lunaid))
summary(GSH_DLPFC)
#DLPFC INV
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.DLPFC_GSH_gamadj) + geom_point() +  geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + theme_classic(base_size=15) +xlab("Age") +ylab("DLPFC GSH")
GSH_DLPFC_inv <- lmer(data=merge7T,sipfc.DLPFC_GSH_gamadj ~ rest.invage + (1|lunaid))
summary(GSH_DLPFC_inv)
#DLPFC quad
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.DLPFC_gamadj) + geom_point() 
GSH_DLPFC_quadage <- lmer(data=merge7T, sipfc.DLPFC_GSH_gamadj ~ rest.age + rest.age2 +   + (1|lunaid))
summary(GSH_DLPFC_quadage)  
AIC(GSH_DLPFC)
AIC(GSH_DLPFC_inv) 
AIC(GSH_DLPFC_quadage)
#RDLPFC
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.RDLPFC_GSH_gamadj) + geom_point() + stat_smooth()+ theme_classic(base_size=15) +xlab("Age") +ylab("RDLPFC GSH")
GSH_RDLPFC <- lmer(data=merge7T,sipfc.RDLPFC_GSH_gamadj ~ rest.age + (1|lunaid))
summary(GSH_RDLPFC)
#RDLPFC INV
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.RDLPFC_GSH_gamadj) + geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + theme_classic(base_size=15) +xlab("Age") +ylab("RDLPFC GSH")
GSH_RDLPFC_inv <- lmer(data=merge7T,sipfc.RDLPFC_GSH_gamadj ~ rest.invage + (1|lunaid))
summary(GSH_RDLPFC_inv)
#RDLPFC quad
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.RDLPFC_gamadj) + geom_point() + 
  GSH_RDLPFC_quadage <- lmer(data=merge7T, sipfc.RDLPFC_GSH_gamadj ~ rest.age + rest.age2 +   + (1|lunaid))
summary(GSH_RDLPFC_quadage)  
AIC(GSH_RDLPFC)
AIC(GSH_RDLPFC_inv) 
AIC(GSH_RDLPFC_quadage)
#LDLPFC
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.LDLPFC_GSH_gamadj) + geom_point() + stat_smooth()+ theme_classic(base_size=15) +xlab("Age") +ylab("LDLPFC GSH")
GSH_LDLPFC <- lmer(data=merge7T,sipfc.LDLPFC_GSH_gamadj ~ rest.age + (1|lunaid))
summary(GSH_LDLPFC)
#LDLPFC INV
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.LDLPFC_GSH_gamadj) + geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T)+ theme_classic(base_size=15) +xlab("Age") +ylab("LDLPFC GSH")
GSH_LDLPFC_inv <- lmer(data=merge7T,sipfc.LDLPFC_GSH_gamadj ~ rest.invage + (1|lunaid))
summary(GSH_LDLPFC_inv)
#LDLPFC quad
ggplot(data=merge7T)+aes(x=rest.age, y=sipfc.LDLPFC_gamadj) + geom_point() + 
  GSH_LDLPFC_quadage <- lmer(data=merge7T, sipfc.LDLPFC_GSH_gamadj ~ rest.age + rest.age2 +   + (1|lunaid))
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


MRS_glu$glu_z <- MRS_glu %>% mutate(glu_z=scale(Glu.Cr, center=T, scale=T))
