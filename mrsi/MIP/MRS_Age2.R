#### MRS metabolite ~ age analyses ####
# 9/18/20 #

library(tidyverse)
library(ggplot2)
library(readxl)
library(Hmisc)
library(lmerTest)
library(corrplot)
library(RColorBrewer)
library(data.table)
library(missMDA)
library(FactoMineR)

### input files
MRS_csv <- "/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI_roi/txt/13MP20200207_LCMv2fixidx.csv"
#  "~/Desktop/Lab/Projects/2020_MRSMGS/13MP20200207_LCMv2fixidx.csv"
LCM_xlsx <- "/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI_roi/txt/lcm.xlsx"
#  "~/Desktop/Lab/Projects/2020_MRSMGS/lcm.xlsx"

#### Get data and remove bad quality data ####
MRS <- read.csv(MRS_csv)

# Step 1 Outlier Detection - visual inspection of LCModel fits/spectra
# create a list of who to remove and remove them
lcm <- read_excel(LCM_xlsx, col_names = FALSE)
lcm <- separate(lcm, "...1", c("ld8", "junk","y","x"),extra="merge", sep = "[-.]")
lcm <- select(lcm, -junk)
lcm$bad <- TRUE
MRS <- MRS %>% mutate(x=216+1-x,y=216+1-y)
MRS <- merge(MRS, lcm, by=c("ld8", "x", "y"), all=T) 
MRS <- filter(MRS, is.na(bad))
MRS <- select(MRS, -bad)

#keep only visit 1 people
MRS <- MRS %>% filter(visitnum==1)
#keep people's correct coordinates
MRS <- MRS %>% filter(!is.na(roi))
#get rid of people who are actually visit 2 but for some reason aren't filtered out
MRS <- MRS %>% filter(ld8!="10195_20191205")

# Step 2 Outlier Detection - get rid of peole who have bad data for 3 major metabolite peaks - GPC+Cho, NAA+NAAG, Cr
MRS<- filter(MRS, GPC.Cho.SD <= 10 | is.na(GPC.Cho.SD))
MRS <- filter(MRS, NAA.NAAG.SD <= 10 | is.na(NAA.NAAG.SD))
MRS <- filter(MRS, Cr.SD <= 10 | is.na(Cr.SD))

# Step 3 Outlier Detection - get rid of people who have lots of macromolecule in their spectra, as that can create distortions
MRS <- filter(MRS, MM20.Cr <= 3 | is.na(MM20.Cr))

#make inverse age column
MRS$invage <- 1/MRS$age
#make age^2 column
MRS$age2 <- (MRS$age - mean(MRS$age))^2

#### Glutamate and Age ####

# Create dataframe with good quality Glutamate data 
MRS_glu <- MRS %>% filter(Glu.Cr != 0)
MRS_glu <- MRS_glu %>% filter(Glu.SD <=20)
z_thres = 2
MRS_glu <- MRS_glu %>%
  group_by(label) %>%
  mutate(zscore_glu=scale(Glu.Cr, center=T, scale=T)) %>%
  filter(abs(zscore_glu) <= z_thres) %>% ungroup

MRS_glu <- MRS_glu %>%
  group_by(label) %>%
  mutate(zscore_invage=scale(invage, center=T, scale=T)) %>% ungroup

MRS_glu <- MRS_glu %>%
  group_by(label) %>%
  mutate(zscore_gm=scale(GMrat, center=T, scale=T)) %>% ungroup


# ROI 1 (R Anterior Insula) and 2 (L Anterior Insula)

ROI12_Glu <- MRS_glu %>% filter(roi == 1 | roi == 2)

# pick best model
ROI12_Glu_age <- lmer(data=ROI12_Glu, Glu.Cr ~ age + label + sex + GMrat + (1|ld8))
summary(ROI12_Glu_age)
ROI12_Glu_invage <- lmer(data=ROI12_Glu, Glu.Cr ~ invage + label + sex + GMrat + (1|ld8))
summary(ROI12_Glu_invage) 
ROI12_Glu_quadage <- lmer(data=ROI12_Glu, Glu.Cr ~ age + age2 + label + sex + GMrat + (1|ld8))
summary(ROI12_Glu_quadage) 

AIC(ROI12_Glu_age)
AIC(ROI12_Glu_invage) # best fit by a lot
AIC(ROI12_Glu_quadage)

# effect sizes
ROI12_zGlu <- lmer(data=ROI12_Glu, zscore_glu ~ zscore_invage + label + (1|ld8))
summary(ROI12_zGlu) # just glu ~ age effect

ROI12_zGlu_invage <- lmer(data=ROI12_Glu, zscore_glu ~ zscore_invage + label + sex + zscore_gm + (1|ld8))
summary(ROI12_zGlu_invage) # all covariates for table

# test for interactions w/ age
ROI12_Glu_hemi_int <- lmer(data=ROI12_Glu, Glu.Cr ~ invage * label + sex + GMrat + (1|ld8))
summary(ROI12_Glu_hemi_int) 
ROI12_Glu_sex_int <- lmer(data=ROI12_Glu, Glu.Cr ~ invage * sex + label + GMrat + (1|ld8))
summary(ROI12_Glu_sex_int) 
ROI12_Glu_gmrat_int <- lmer(data=ROI12_Glu, Glu.Cr ~ invage * GMrat + sex + label + (1|ld8))
summary(ROI12_Glu_gmrat_int) 


# ROI 7 (ACC)
ROI7_Glu <- MRS_glu %>% filter(roi == 7)

# pick best model
ROI7_Glu_age <- lm(data=ROI7_Glu, Glu.Cr ~ age + sex + GMrat)
summary(ROI7_Glu_age)
ROI7_Glu_invage <- lm(data=ROI7_Glu, Glu.Cr ~ invage + sex + GMrat)
summary(ROI7_Glu_invage)
ROI7_Glu_quadage <- lm(data=ROI7_Glu, Glu.Cr ~ age + age2 + sex + GMrat)
summary(ROI7_Glu_quadage)

AIC(ROI7_Glu_age) 
AIC(ROI7_Glu_invage) # best fit
AIC(ROI7_Glu_quadage)

#effect sizes
ROI7_zGlu <- lm(data=ROI7_Glu, zscore_glu ~ zscore_invage)
summary(ROI7_zGlu)
ROI7_zGlu_invage <- lm(data=ROI7_Glu, zscore_glu ~ zscore_invage + sex + zscore_gm)
summary(ROI7_zGlu_invage)

# test for interactions
ROI7_age_sex_int <- lm(data=ROI7_Glu, Glu.Cr ~ invage * sex + GMrat)
summary(ROI7_age_sex_int)
ROI7_gm_sex_int <- lm(data=ROI7_Glu, Glu.Cr ~ invage * GMrat + sex)
summary(ROI7_gm_sex_int)


ggplot(ROI7_Glu, aes(x=age, y=Glu.Cr)) + geom_point() + geom_smooth(method="lm") + theme_classic()


# ROI 8 (MPFC)
ROI8_Glu <- MRS_glu %>% filter( roi == 8)

ROI8_Glu_age <- lm(data=ROI8_Glu, Glu.Cr ~ age + sex + GMrat)
summary(ROI8_Glu_age)
ROI8_Glu_invage <- lm(data=ROI8_Glu, Glu.Cr ~ invage + sex + GMrat)
summary(ROI8_Glu_invage)
ROI8_Glu_quadage <- lm(data=ROI8_Glu, Glu.Cr ~ age + age2 + sex + GMrat)
summary(ROI8_Glu_quadage)

AIC(ROI8_Glu_age)
AIC(ROI8_Glu_invage) # best fit
AIC(ROI8_Glu_quadage)

ROI8_zGlu <- lm(data=ROI8_Glu, zscore_glu ~ zscore_invage)
summary(ROI8_zGlu)
ROI8_zGlu_invage <- lm(data=ROI8_Glu, zscore_glu ~ zscore_invage + sex + zscore_gm)
summary(ROI8_zGlu_invage)

# test for interactions
ROI8_age_sex_int <- lm(data=ROI8_Glu, Glu.Cr ~ invage * sex + GMrat)
summary(ROI8_age_sex_int)
ROI8_gm_sex_int <- lm(data=ROI8_Glu, Glu.Cr ~ invage * GMrat + sex)
summary(ROI8_gm_sex_int)

ggplot(ROI8_Glu, aes(x=age, y=Glu.Cr)) + geom_point() + geom_smooth(method="lm") + theme_classic()


# ROI 9 ( R DLPFC) and 10 (L DLPFC)
ROI910_Glu <- MRS_glu %>% filter(roi == 9 | roi == 10)

#ROI910_Glu %>% select(ld8,label) %>% gather(label)

ROI910_Glu_invage <- lmer(data=ROI910_Glu, Glu.Cr ~ invage + label + sex + GMrat + (1|ld8))
summary(ROI910_Glu_invage) 

ROI910_zGlu <- lmer(data=ROI910_Glu, zscore_glu ~ zscore_invage + label + (1|ld8))
summary(ROI910_zGlu)
ROI910_zGlu_invage <- lmer(data=ROI910_Glu, zscore_glu ~ zscore_invage + label + sex + zscore_gm + (1|ld8))
summary(ROI910_zGlu_invage) 

# test for interactions w/ age
ROI910_age_hemi_int <- lmer(data=ROI910_Glu, Glu.Cr ~ invage * label + sex + GMrat + (1|ld8))
summary(ROI910_age_hemi_int) 
ROI910_age_sex_int <- lmer(data=ROI910_Glu, Glu.Cr ~ invage * sex + label + GMrat + (1|ld8))
summary(ROI910_age_sex_int) 
ROI910_age_gmrat_int <- lmer(data=ROI910_Glu, Glu.Cr ~ invage * GMrat + sex + label + (1|ld8))
summary(ROI910_age_gmrat_int) 


ggplot(ROI910_Glu, aes(x=age, y=Glu.Cr, color=label)) + geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + theme_classic()




#### GABA & Age ####

# Create dataframe with good quality GABAtamate data 
MRS_GABA <- MRS %>% filter(GABA.SD <=20)
z_thres = 2
MRS_GABA <- MRS_GABA %>%
  group_by(label) %>%
  mutate(zscore_GABA=scale(GABA.Cr, center=T, scale=T)) %>%
  filter(abs(zscore_GABA) <= z_thres) %>% ungroup

MRS_GABA <- MRS_GABA %>%
  group_by(label) %>%
  mutate(zscore_invage=scale(invage, center=T, scale=T)) %>% ungroup

MRS_GABA <- MRS_GABA %>%
  group_by(label) %>%
  mutate(zscore_gm=scale(GMrat, center=T, scale=T)) %>% ungroup


# ROI 1 (R Anterior Insula) and 2 (L Anterior Insula)

ROI12_GABA <- MRS_GABA %>% filter(roi == 1 | roi == 2)

# pick best model
ROI12_GABA_age <- lmer(data=ROI12_GABA, GABA.Cr ~ age + label + sex + GMrat + (1|ld8))
summary(ROI12_GABA_age)
ROI12_GABA_invage <- lmer(data=ROI12_GABA, GABA.Cr ~ invage + label + sex + GMrat + (1|ld8))
summary(ROI12_GABA_invage) 
ROI12_GABA_quadage <- lmer(data=ROI12_GABA, GABA.Cr ~ age + age2 + label + sex + GMrat + (1|ld8))
summary(ROI12_GABA_quadage) 

AIC(ROI12_GABA_age)
AIC(ROI12_GABA_invage)
AIC(ROI12_GABA_quadage)

# effect sizes
ROI12_zGABA <- lmer(data=ROI12_GABA, zscore_GABA ~ zscore_invage + label + (1|ld8))
summary(ROI12_zGABA) # just GABA ~ age effect

ROI12_zGABA_invage <- lmer(data=ROI12_GABA, zscore_GABA ~ zscore_invage + label + sex + zscore_gm + (1|ld8))
summary(ROI12_zGABA_invage) # all covariates for table

# test for interactions w/ age
ROI12_GABA_hemi_int <- lmer(data=ROI12_GABA, GABA.Cr ~ invage * label + sex + GMrat + (1|ld8))
summary(ROI12_GABA_hemi_int) 
ROI12_GABA_sex_int <- lmer(data=ROI12_GABA, GABA.Cr ~ invage * sex + label + GMrat + (1|ld8))
summary(ROI12_GABA_sex_int) 
ROI12_GABA_gmrat_int <- lmer(data=ROI12_GABA, GABA.Cr ~ invage * GMrat + sex + label + (1|ld8))
summary(ROI12_GABA_gmrat_int) 


# ROI 7 (ACC)
ROI7_GABA <- MRS_GABA %>% filter(roi == 7)

# pick best model
ROI7_GABA_age <- lm(data=ROI7_GABA, GABA.Cr ~ age + sex + GMrat)
summary(ROI7_GABA_age)
ROI7_GABA_invage <- lm(data=ROI7_GABA, GABA.Cr ~ invage + sex + GMrat)
summary(ROI7_GABA_invage)
ROI7_GABA_quadage <- lm(data=ROI7_GABA, GABA.Cr ~ age + age2 + sex + GMrat)
summary(ROI7_GABA_quadage)

AIC(ROI7_GABA_age) 
AIC(ROI7_GABA_invage) # best fit
AIC(ROI7_GABA_quadage)

#effect sizes
ROI7_zGABA <- lm(data=ROI7_GABA, zscore_GABA ~ zscore_invage)
summary(ROI7_zGABA)
ROI7_zGABA_invage <- lm(data=ROI7_GABA, zscore_GABA ~ zscore_invage + sex + zscore_gm)
summary(ROI7_zGABA_invage)

# test for interactions
ROI7_age_sex_int <- lm(data=ROI7_GABA, GABA.Cr ~ invage * sex + GMrat)
summary(ROI7_age_sex_int)
ROI7_gm_sex_int <- lm(data=ROI7_GABA, GABA.Cr ~ invage * GMrat + sex)
summary(ROI7_gm_sex_int)


ggplot(ROI7_GABA, aes(x=age, y=GABA.Cr)) + geom_point() + geom_smooth(method="lm") + theme_classic()


# ROI 8 (MPFC)
ROI8_GABA <- MRS_GABA %>% filter( roi == 8)

ROI8_GABA_age <- lm(data=ROI8_GABA, GABA.Cr ~ age + sex + GMrat)
summary(ROI8_GABA_age)
ROI8_GABA_invage <- lm(data=ROI8_GABA, GABA.Cr ~ invage + sex + GMrat)
summary(ROI8_GABA_invage)
ROI8_GABA_quadage <- lm(data=ROI8_GABA, GABA.Cr ~ age + age2 + sex + GMrat)
summary(ROI8_GABA_quadage)

AIC(ROI8_GABA_age)
AIC(ROI8_GABA_invage) # best fit
AIC(ROI8_GABA_quadage)

ROI8_zGABA <- lm(data=ROI8_GABA, zscore_GABA ~ zscore_invage)
summary(ROI8_zGABA)
ROI8_zGABA_invage <- lm(data=ROI8_GABA, zscore_GABA ~ zscore_invage + sex + zscore_gm)
summary(ROI8_zGABA_invage)

# test for interactions
ROI8_age_sex_int <- lm(data=ROI8_GABA, GABA.Cr ~ invage * sex + GMrat)
summary(ROI8_age_sex_int)
ROI8_gm_sex_int <- lm(data=ROI8_GABA, GABA.Cr ~ invage * GMrat + sex)
summary(ROI8_gm_sex_int)

ggplot(ROI8_GABA, aes(x=age, y=GABA.Cr)) + geom_point() + geom_smooth(method="lm") + theme_classic()


# ROI 9 ( R DLPFC) and 10 (L DLPFC)
ROI910_GABA <- MRS_GABA %>% filter(roi == 9 | roi == 10)

#ROI910_GABA %>% select(ld8,label) %>% gather(label)

ROI910_GABA_invage <- lmer(data=ROI910_GABA, GABA.Cr ~ invage + label + sex + GMrat + (1|ld8))
summary(ROI910_GABA_invage) 

ROI910_zGABA <- lmer(data=ROI910_GABA, zscore_GABA ~ zscore_invage + label + (1|ld8))
summary(ROI910_zGABA)
ROI910_zGABA_invage <- lmer(data=ROI910_GABA, zscore_GABA ~ zscore_invage + label + sex + zscore_gm + (1|ld8))
summary(ROI910_zGABA_invage) 

# test for interactions w/ age
ROI910_age_hemi_int <- lmer(data=ROI910_GABA, GABA.Cr ~ invage * label + sex + GMrat + (1|ld8))
summary(ROI910_age_hemi_int) 
ROI910_age_sex_int <- lmer(data=ROI910_GABA, GABA.Cr ~ invage * sex + label + GMrat + (1|ld8))
summary(ROI910_age_sex_int) 
ROI910_age_gmrat_int <- lmer(data=ROI910_GABA, GABA.Cr ~ invage * GMrat + sex + label + (1|ld8))
summary(ROI910_age_gmrat_int) 


ggplot(ROI910_GABA, aes(x=age, y=GABA.Cr, color=label)) + geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + theme_classic()

#### Ratio & Age ####

# create dataframe keeping only people who have both good quality Glu and good GABA data to
# make a ratio out of 
MRS_Ratio <- MRS_glu %>% filter(GABA.SD <=20)
MRS_Ratio <- MRS_Ratio %>%
  group_by(roi) %>%
  mutate(zscore=scale(GABA.Cr, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres) %>% ungroup

MRS_Ratio$Ratio <- MRS_Ratio$Glu.Cr/MRS_Ratio$GABA.Cr

MRS_Ratio <- MRS_Ratio %>%
  group_by(roi) %>%
  mutate(zscore=scale(Ratio, center=T, scale=T)) %>%
  filter(abs(zscore_Ratio) <= z_thres) %>% ungroup

MRS_Ratio <- MRS_Ratio %>%
  group_by(label) %>%
  mutate(zscore_invage=scale(invage, center=T, scale=T)) %>% ungroup

MRS_Ratio <- MRS_Ratio %>%
  group_by(label) %>%
  mutate(zscore_gm=scale(GMrat, center=T, scale=T)) %>% ungroup


# ROI 1 (R Anterior Insula) and 2 (L Anterior Insula)

ROI12_Ratio <- MRS_Ratio %>% filter(roi == 1 | roi == 2)

# pick best model
ROI12_Ratio_age <- lmer(data=ROI12_Ratio, Ratio ~ age + label + sex + GMrat + (1|ld8))
summary(ROI12_Ratio_age)
ROI12_Ratio_invage <- lmer(data=ROI12_Ratio, Ratio ~ invage + label + sex + GMrat + (1|ld8))
summary(ROI12_Ratio_invage) 
ROI12_Ratio_quadage <- lmer(data=ROI12_Ratio, Ratio ~ age + age2 + label + sex + GMrat + (1|ld8))
summary(ROI12_Ratio_quadage) 

AIC(ROI12_Ratio_age)
AIC(ROI12_Ratio_invage)
AIC(ROI12_Ratio_quadage)

# effect sizes
ROI12_zRatio <- lmer(data=ROI12_Ratio, zscore_Ratio ~ zscore_invage + label + (1|ld8))
summary(ROI12_zRatio) # just Ratio ~ age effect

ROI12_zRatio_invage <- lmer(data=ROI12_Ratio, zscore_Ratio ~ zscore_invage + label + sex + zscore_gm + (1|ld8))
summary(ROI12_zRatio_invage) # all covariates for table

# test for interactions w/ age
ROI12_Ratio_hemi_int <- lmer(data=ROI12_Ratio, Ratio ~ invage * label + sex + GMrat + (1|ld8))
summary(ROI12_Ratio_hemi_int) 
ROI12_Ratio_sex_int <- lmer(data=ROI12_Ratio, Ratio ~ invage * sex + label + GMrat + (1|ld8))
summary(ROI12_Ratio_sex_int) 
ROI12_Ratio_gmrat_int <- lmer(data=ROI12_Ratio, Ratio ~ invage * GMrat + sex + label + (1|ld8))
summary(ROI12_Ratio_gmrat_int) 


# ROI 7 (ACC)
ROI7_Ratio <- MRS_Ratio %>% filter(roi == 7)

# pick best model
ROI7_Ratio_age <- lm(data=ROI7_Ratio, Ratio ~ age + sex + GMrat)
summary(ROI7_Ratio_age)
ROI7_Ratio_invage <- lm(data=ROI7_Ratio, Ratio ~ invage + sex + GMrat)
summary(ROI7_Ratio_invage)
ROI7_Ratio_quadage <- lm(data=ROI7_Ratio, Ratio ~ age + age2 + sex + GMrat)
summary(ROI7_Ratio_quadage)

AIC(ROI7_Ratio_age) 
AIC(ROI7_Ratio_invage) # best fit
AIC(ROI7_Ratio_quadage)

#effect sizes
ROI7_zRatio <- lm(data=ROI7_Ratio, zscore_Ratio ~ zscore_invage)
summary(ROI7_zRatio)
ROI7_zRatio_invage <- lm(data=ROI7_Ratio, zscore_Ratio ~ zscore_invage + sex + zscore_gm)
summary(ROI7_zRatio_invage)

# test for interactions
ROI7_age_sex_int <- lm(data=ROI7_Ratio, Ratio ~ invage * sex + GMrat)
summary(ROI7_age_sex_int)
ROI7_gm_sex_int <- lm(data=ROI7_Ratio, Ratio ~ invage * GMrat + sex)
summary(ROI7_gm_sex_int)


ggplot(ROI7_Ratio, aes(x=age, y=Ratio)) + geom_point() + geom_smooth(method="lm") + theme_classic()


# ROI 8 (MPFC)
ROI8_Ratio <- MRS_Ratio %>% filter( roi == 8)

ROI8_Ratio_age <- lm(data=ROI8_Ratio, Ratio ~ age + sex + GMrat)
summary(ROI8_Ratio_age)
ROI8_Ratio_invage <- lm(data=ROI8_Ratio, Ratio ~ invage + sex + GMrat)
summary(ROI8_Ratio_invage)
ROI8_Ratio_quadage <- lm(data=ROI8_Ratio, Ratio ~ age + age2 + sex + GMrat)
summary(ROI8_Ratio_quadage)

AIC(ROI8_Ratio_age)
AIC(ROI8_Ratio_invage) # best fit
AIC(ROI8_Ratio_quadage)

ROI8_zRatio <- lm(data=ROI8_Ratio, zscore_Ratio ~ zscore_invage)
summary(ROI8_zRatio)
ROI8_zRatio_invage <- lm(data=ROI8_Ratio, zscore_Ratio ~ zscore_invage + sex + zscore_gm)
summary(ROI8_zRatio_invage)

# test for interactions
ROI8_age_sex_int <- lm(data=ROI8_Ratio, Ratio ~ invage * sex + GMrat)
summary(ROI8_age_sex_int)
ROI8_gm_sex_int <- lm(data=ROI8_Ratio, Ratio ~ invage * GMrat + sex)
summary(ROI8_gm_sex_int)

ggplot(ROI8_Ratio, aes(x=age, y=Ratio)) + geom_point() + geom_smooth(method="lm") + theme_classic()


# ROI 9 ( R DLPFC) and 10 (L DLPFC)
ROI910_Ratio <- MRS_Ratio %>% filter(roi == 9 | roi == 10)

#ROI910_Ratio %>% select(ld8,label) %>% gather(label)

ROI910_Ratio_invage <- lmer(data=ROI910_Ratio, Ratio ~ invage + label + sex + GMrat + (1|ld8))
summary(ROI910_Ratio_invage) 

ROI910_zRatio <- lmer(data=ROI910_Ratio, zscore_Ratio ~ zscore_invage + label + (1|ld8))
summary(ROI910_zRatio)
ROI910_zRatio_invage <- lmer(data=ROI910_Ratio, zscore_Ratio ~ zscore_invage + label + sex + zscore_gm + (1|ld8))
summary(ROI910_zRatio_invage) 

# test for interactions w/ age
ROI910_age_hemi_int <- lmer(data=ROI910_Ratio, Ratio ~ invage * label + sex + GMrat + (1|ld8))
summary(ROI910_age_hemi_int) 
ROI910_age_sex_int <- lmer(data=ROI910_Ratio, Ratio ~ invage * sex + label + GMrat + (1|ld8))
summary(ROI910_age_sex_int) 
ROI910_age_gmrat_int <- lmer(data=ROI910_Ratio, Ratio ~ invage * GMrat + sex + label + (1|ld8))
summary(ROI910_age_gmrat_int) 


ggplot(ROI910_Ratio, aes(x=age, y=Ratio, color=label)) + geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + theme_classic()

#### Plot GABA and Glu on same graph ####
gaba12 <- ROI12_GABA %>% select(concentration=GABA.Cr, age, sex, GMrat, label) %>% mutate(metabolite="GABA")
glu12 <- ROI12_Glu %>% select(concentration=Glu.Cr, age, sex, GMrat, label) %>% mutate(metabolite="Glu")
gabaglu12 <- rbind(gaba12,glu12)
ggplot(gabaglu12) + aes(y=concentration, x=age, color=metabolite, linetype = label, shape=label) +
  geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + 
  theme_classic(base_size = 18) +xlab("Age") + ylab("Metabolite/Cr") + 
  labs(color= "Metabolite", shape = "Hemisphere") + 
  scale_shape_manual(values=c(16, 1)) + 
  scale_color_manual(values=c("#FF6666", "#66B2FF"), guide = guide_legend(reverse = TRUE)) +
  guides(linetype=FALSE) + 
  theme(legend.key = element_rect(fill = "white", colour = "black"))

gaba910 <- ROI910_GABA %>% select(concentration=GABA.Cr, age, sex, GMrat, label) %>% mutate(metabolite="GABA")
glu910 <- ROI910_Glu %>% select(concentration=Glu.Cr, age, sex, GMrat, label) %>% mutate(metabolite="Glu")
gabaglu910 <- rbind(gaba910,glu910)
ggplot(gabaglu910) + aes(y=concentration, x=age, color=metabolite, linetype = label, shape=label) +
  geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + 
  theme_classic(base_size = 18) +xlab("Age") + ylab("Metabolite/Cr") + 
  labs(color= "Metabolite", shape = "Hemisphere") + 
  scale_shape_manual(values=c(16, 1)) + 
  scale_color_manual(values=c("#FF6666", "#66B2FF"), guide = guide_legend(reverse = TRUE)) +
  guides(linetype=FALSE) + 
  theme(legend.key = element_rect(fill = "white", colour = "black"))

gaba7 <- ROI7_GABA %>% select(concentration=GABA.Cr, age, sex, GMrat) %>% mutate(metabolite="GABA")
glu7 <- ROI7_Glu %>% select(concentration=Glu.Cr, age, sex, GMrat) %>% mutate(metabolite="Glu")
gabaglu7 <- rbind(gaba7,glu7)
ggplot(gabaglu7) + aes(y=concentration, x=age, color=metabolite) +
  geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + 
  theme_classic(base_size = 18) +xlab("Age") + ylab("Metabolite/Cr") + 
  labs(color= "Metabolite") + 
  scale_shape_manual(values=c(16, 1)) + 
  scale_color_manual(values=c("#FF6666", "#66B2FF"), guide = guide_legend(reverse = TRUE)) +
  guides(linetype=FALSE) + 
  theme(legend.key = element_rect(fill = "white", colour = "black"))

gaba8 <- ROI8_GABA %>% select(concentration=GABA.Cr, age, sex, GMrat) %>% mutate(metabolite="GABA")
glu8 <- ROI8_Glu %>% select(concentration=Glu.Cr, age, sex, GMrat) %>% mutate(metabolite="Glu")
gabaglu8 <- rbind(gaba8,glu8)
ggplot(gabaglu8) + aes(y=concentration, x=age, color=metabolite) +
  geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + 
  theme_classic(base_size = 18) +xlab("Age") + ylab("Metabolite/Cr") + 
  labs(color= "Metabolite") + 
  scale_shape_manual(values=c(16, 1)) + 
  scale_color_manual(values=c("#FF6666", "#66B2FF"), guide = guide_legend(reverse = TRUE)) +
  guides(linetype=FALSE) + 
  theme(legend.key = element_rect(fill = "white", colour = "black"))


#### Plot Ratio and Age ####
ggplot(ROI12_Ratio) + aes(y=Ratio, x=age, linetype = label, shape=label) +
  geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + 
  theme_classic(base_size = 18) +xlab("Age") + ylab("Glu/GABA") + 
  labs(shape = "Hemisphere") + 
  scale_shape_manual(values=c(16, 1)) + 
  theme(legend.key = element_rect(fill = "white", colour = "black"))

ggplot(ROI910_Ratio) + aes(y=Ratio, x=age, linetype = label, shape=label) +
  geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + 
  theme_classic(base_size = 18) +xlab("Age") + ylab("Glu/GABA") + 
  labs(shape = "Hemisphere") + 
  scale_shape_manual(values=c(16, 1)) + 
  theme(legend.key = element_rect(fill = "white", colour = "black"))

ggplot(ROI7_Ratio) + aes(y=Ratio, x=age) +
  geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + 
  theme_classic(base_size = 18) +xlab("Age") + ylab("Glu/GABA") + 
  theme(legend.key = element_rect(fill = "white", colour = "black"))

ggplot(ROI8_Ratio) + aes(y=Ratio, x=age) +
  geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + 
  theme_classic(base_size = 18) +xlab("Age") + ylab("Glu/GABA") + 
  theme(legend.key = element_rect(fill = "white", colour = "black"))

#### Correlation matrices ####

# How correlated is Glutamate between regions?

# Step 1 - Residualize age out of the correlation
mk_age_resid_glu <- function(d) {d[,'Glu.Cr'] <- lm(Glu.Cr ~ invage, d)$residuals; return(d) }
resids_glu <- MRS_glu %>% split(MRS_glu$label) %>% lapply(mk_age_resid_glu)
resids_glu <- resids %>% bind_rows
# Step 1 - take good Glu data in MRS_glu dataframe and change the format
MRS_glu_wide <- pivot_wider(resids_glu, id_cols=ld8, names_from=label, values_from=Glu.Cr)
MRS_glu_wide <- select(MRS_glu_wide, -`R STS`, -`L STS`)

#Step 2 - Make correlation matrix
Glu_corr<- cor(MRS_glu_wide %>% select_if(is.numeric), use="pairwise.complete.obs")

#Step 3 - Make significance matrix 
pvals <- cor.mtest(MRS_glu_wide %>% select_if(is.numeric), conf.level = .95)

#Step 4 - plot correlation matrix 
corrplot(Glu_corr, p.mat = pvals$p, sig.level = .05, method = "number", type="lower", tl.col = "black", tl.srt = 45, insig = "blank", col = rev(brewer.pal(n = 8, name = "Spectral")))


# How correlated is GABA between regions?
# Step 1 - take good GABA data in MRS_GABA dataframe and change the format
mk_age_resid_GABA <- function(d) {d[,'GABA.Cr'] <- lm(GABA.Cr ~ invage, d)$residuals; return(d) }
resids_GABA <- MRS_GABA %>% split(MRS_GABA$label) %>% lapply(mk_age_resid_GABA)
resids_GABA <- resids %>% bind_rows
MRS_GABA_wide <- pivot_wider(resids_GABA, id_cols=ld8, names_from=label, values_from=GABA.Cr)
MRS_GABA_wide <- select(MRS_GABA_wide, -`R STS`, -`L STS`)

#Step 2 - Make correlation matrix
GABA_corr<- cor(MRS_GABA_wide %>% select_if(is.numeric), use="pairwise.complete.obs")

#Step 3 - Make significance matrix 
pvals <- cor.mtest(MRS_GABA_wide %>% select_if(is.numeric), conf.level = .95)

#Step 4 - plot correlation matrix 
corrplot(GABA_corr, p.mat = pvals$p, sig.level = .05, method = "number", type="lower", tl.col = "black", tl.srt = 45, insig = "blank", col = rev(brewer.pal(n = 8, name = "Spectral")))

# How correlated is the ratio between regions?
MRS_ratio_wide <- pivot_wider(MRS_Ratio, id_cols=ld8, names_from=label, values_from=Ratio)
MRS_ratio_wide <- select(MRS_ratio_wide, -`R STS`, -`L STS`)

#Step 2 - Make correlation matrix
ratio_corr<- cor(MRS_ratio_wide %>% select_if(is.numeric), use="pairwise.complete.obs")

#Step 3 - Make significance matrix 
pvals <- cor.mtest(MRS_ratio_wide %>% select_if(is.numeric), conf.level = .95)

#Step 4 - plot correlation matrix 
corrplot(ratio_corr, p.mat = pvals$p, sig.level = .05, method = "number", type="lower", tl.col = "black", tl.srt = 45, insig = "blank", col = rev(brewer.pal(n = 8, name = "Spectral")))


#### Do GABA and Glu get more correlated with age ####
MRS_corr <- MRS_glu %>% filter(GABA.SD <= 20)
MRS_corr <- MRS_corr %>%
  group_by(roi) %>%
  mutate(zscore=scale(GABA.Cr, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres) %>% ungroup

MRS1 <- MRS_corr %>% filter(roi==1)
MRS2 <- MRS_corr %>% filter(roi==2)
MRS7 <- MRS_corr %>% filter(roi==7)
MRS8 <- MRS_corr %>% filter(roi==8)
MRS9 <- MRS_corr %>% filter(roi==9)
MRS10 <- MRS_corr %>% filter(roi==10)

MRS1 %>% mutate(agegrp=cut(breaks=c(0,16,22,Inf), age)) %>% split(.$agegrp) %>% sapply(function(x) cor(x$Glu.Cr, x$GABA.Cr))
MRS1 %>% mutate(agegrp=cut(breaks=c(0,16,22,Inf), age)) %>% group_by(agegrp) %>% tally
MRS1 <- MRS1 %>% mutate(agegrp=cut(breaks=c(0,16,22,Inf), age))
ggplot(MRS1) + aes(y=GABA.Cr, x=Glu.Cr) +
  geom_point() + geom_smooth(method="lm") + 
  theme_classic(base_size = 18) +xlab("Glu.Cr") + ylab("GABA.Cr") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  facet_wrap(~ agegrp) +
  xlab("Glu/Cr") +
  ylab("GABA/Cr")

MRS2 %>% mutate(agegrp=cut(breaks=c(0,16,22,Inf), age)) %>% split(.$agegrp) %>% sapply(function(x) cor(x$Glu.Cr, x$GABA.Cr))
MRS2 %>% mutate(agegrp=cut(breaks=c(0,16,22,Inf), age)) %>% group_by(agegrp) %>% tally
MRS2 <- MRS2 %>% mutate(agegrp=cut(breaks=c(0,16,22,Inf), age))
ggplot(MRS2) + aes(y=GABA.Cr, x=Glu.Cr) +
  geom_point() + geom_smooth(method="lm") + 
  theme_classic(base_size = 13) +xlab("Glu.Cr") + ylab("GABA.Cr") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("Glu ~ GABA in L Anterior Insula") +
  facet_wrap(~ agegrp)


MRS7 %>% mutate(agegrp=cut(breaks=c(0,16,22,Inf), age)) %>% split(.$agegrp) %>% sapply(function(x) cor(x$Glu.Cr, x$GABA.Cr))
MRS7 %>% mutate(agegrp=cut(breaks=c(0,16,22,Inf), age)) %>% group_by(agegrp) %>% tally
MRS7<- MRS7 %>% mutate(agegrp=cut(breaks=c(0,16,22,Inf), age))

levels(MRS7$agegrp) <- c("10-16","17-22", "23-30")
ggplot(MRS7) + aes(y=GABA.Cr, x=Glu.Cr) +
  geom_point() + geom_smooth(method="lm") + 
  theme_classic(base_size = 18) +xlab("Glu.Cr") + ylab("GABA.Cr") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  facet_wrap(~ agegrp) +
  xlab("Glu/Cr") +
  ylab("GABA/Cr")

MRS8 %>% mutate(agegrp=cut(breaks=c(0,16,22,Inf), age)) %>% split(.$agegrp) %>% sapply(function(x) cor(x$Glu.Cr, x$GABA.Cr))
MRS8 %>% mutate(agegrp=cut(breaks=c(0,16,22,Inf), age)) %>% group_by(agegrp) %>% tally
MRS8<- MRS8 %>% mutate(agegrp=cut(breaks=c(0,16,22,Inf), age))
levels(MRS8$agegrp) <- c("10-16","17-22", "23-30")


ggplot(MRS8) + aes(y=GABA.Cr, x=Glu.Cr) +
  geom_point() + geom_smooth(method="lm") + 
  theme_classic(base_size = 18) +xlab("Glu.Cr") + ylab("GABA.Cr") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  facet_wrap(~ agegrp) +
  xlab("Glu/Cr") +
  ylab("GABA/Cr")
  

MRS9 %>% mutate(agegrp=cut(breaks=c(0,16,22,Inf), age)) %>% split(.$agegrp) %>% sapply(function(x) cor(x$Glu.Cr, x$GABA.Cr))
MRS9 %>% mutate(agegrp=cut(breaks=c(0,16,22,Inf), age)) %>% group_by(agegrp) %>% tally
MRS9<- MRS9 %>% mutate(agegrp=cut(breaks=c(0,16,22,Inf), age))
ggplot(MRS9) + aes(y=GABA.Cr, x=Glu.Cr) +
  geom_point() + geom_smooth(method="lm") + 
  theme_classic(base_size = 13) +xlab("Glu.Cr") + ylab("GABA.Cr") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("Glu ~ GABA in RDLPFC") +
  facet_wrap(~ agegrp)

MRS10 %>% mutate(agegrp=cut(breaks=c(0,16,22,Inf), age)) %>% split(.$agegrp) %>% sapply(function(x) cor(x$Glu.Cr, x$GABA.Cr))
MRS10 %>% mutate(agegrp=cut(breaks=c(0,16,22,Inf), age)) %>% group_by(agegrp) %>% tally
MRS10<- MRS10 %>% mutate(agegrp=cut(breaks=c(0,16,22,Inf), age))
ggplot(MRS10) + aes(y=GABA.Cr, x=Glu.Cr) +
  geom_point() + geom_smooth(method="lm") + 
  theme_classic(base_size = 13) +xlab("Glu.Cr") + ylab("GABA.Cr") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("Glu ~ GABA in LDLPFC") +
  facet_wrap(~ agegrp)



#### Residuals of GABA ~ Glu ####

# ACC 

ACC_gabaglu2 <- lm(data=MRS7, GABA.Cr ~ Glu.Cr * age)
summary(ACC_gabaglu2)
MRS7$residuals <- abs(residuals(ACC_gabaglu2))
ggplot(MRS7) + aes(y=residuals, x=age) +
  geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + 
  theme_classic(base_size = 13) +xlab("Age") + ylab("Residuals") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("Age ~ Residuals")

# not just bad data quality and age association
ggplot(MRS7) + aes(y=Glu.SD, x=age) +
  geom_point() + geom_smooth(method="lm") + 
  theme_classic(base_size = 13) +xlab("Age") + ylab("Glu CRLB") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("Age ~ Glu CRLB")

ggplot(MRS7) + aes(y=GABA.SD, x=age) +
  geom_point() + geom_smooth(method="lm") + 
  theme_classic(base_size = 13) +xlab("Age") + ylab("GABA CRLB") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("Age ~ GABA CRLB")

# MPFC 

MPFC_gabaglu2 <- lm(data=MRS8, GABA.Cr ~ Glu.Cr * age)
summary(MPFC_gabaglu2)
MRS8$residuals <- abs(residuals(MPFC_gabaglu2))
ggplot(MRS8) + aes(y=residuals, x=age) +
  geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + 
  theme_classic(base_size = 13) +xlab("Age") + ylab("Residuals") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("Age ~ Residuals")

# not just bad data quality and age association
ggplot(MRS8) + aes(y=Glu.SD, x=age) +
  geom_point() + geom_smooth(method="lm") + 
  theme_classic(base_size = 13) +xlab("Age") + ylab("Glu CRLB") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("Age ~ Glu CRLB")

ggplot(MRS8) + aes(y=GABA.SD, x=age) +
  geom_point() + geom_smooth(method="lm") + 
  theme_classic(base_size = 13) +xlab("Age") + ylab("GABA CRLB") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("Age ~ GABA CRLB")

# DLPFC - to do; should i average r & l or not
# Anterior Insula - to do

#### Get MGS Behavior Data ####
eog <- read.csv('/Users/mariaperica/Desktop/Lab/Projects/2020_MRSMGS/eeg_data_20200929.csv')
eog$ld8 <- paste0(eog$LunaID, '_', eog$ScanDate)
names(eog)
subjData <- eog %>% group_by(ld8, Delay) %>% dplyr::summarize(meanAbsPosErr = mean(abs(PositionError), na.rm=T),
                                                              sdAbsPosErr = sd(abs(PositionError), na.rm=T),
                                                              meanAbsBestErr = mean(abs(BestError), na.rm=T),
                                                              sdAbsBestErr = sd(abs(BestError), na.rm=T),
                                                              meanAbsDispErr = mean(abs(DisplacementError), na.rm=T),
                                                              sdAbsDispErr = sd(abs(DisplacementError), na.rm=T),
                                                              meanPosErr = mean((PositionError), na.rm=T),
                                                              sdPosErr = sd((PositionError), na.rm=T),
                                                              meanDispErr = mean((DisplacementError), na.rm=T),
                                                              sdDispErr = sd((DisplacementError), na.rm=T),                                                          meanVGSLatency = mean(vgsLatency, na.rm=T),
                                                              sdVGSLatency = sd(vgsLatency, na.rm=T),
                                                              meanMGSLatency = mean(mgsLatency, na.rm=T),
                                                              sdMGSLatency = sd(mgsLatency, na.rm=T),
                                                              n=n(),
                                                              delaySaccades = mean(DelaySaccades))

subjData <- subjData %>% separate(ld8, into=c("LunaID", "ScanDate"), sep="_", remove=F)


subjData <- subjData %>%
  unite(ld8, LunaID,ScanDate, remove=F) %>%
  group_by(LunaID) %>%
  arrange(ScanDate) %>%
  mutate(visitno=1+cumsum(ld8 != lag(ld8,default=first(ld8))))

subjData <- subjData %>% filter(visitno == 1)

# get age dataframe 
agefile <- read.table("~/Desktop/Lab/Projects/2020_MRSMGS/eeg_age_sex.tsv", sep="\t", col.names=c("ld8","age","sex"))
agefile <- agefile %>% separate(idvalues, into=c("LunaID", "ScanDate"), sep="_", remove=F)
agefile <- rbind(agefile, c("11802_20190910", 21.73, "F"))

# merge with subjData
MGS_age <- merge(subjData, agefile, by="ld8")
MGS_age$invage <- 1/(as.numeric(MGS_age$age))

# Mean Best Error
MBE <- MGS_age %>% 
  mutate(zscore_beh=scale(meanAbsBestErr, center=T, scale=T)) %>%
  filter(abs(zscore_beh) <= z_thres)
MBE <- MBE %>% mutate(zscore_invage=scale(invage, center=T, scale=T))
MBE <- MBE %>% mutate(zscore_delay=scale(Delay, center=T, scale=T))

MBE_age <- lmer(data=MBE, meanAbsBestErr ~ invage + Delay + (1|ld8))
summary(MBE_age)

MBE_age <- lmer(data=MBE, meanAbsBestErr ~ invage * Delay + (1|ld8))
summary(MBE_age)

MBE_age <- lmer(data=MBE, zscore_beh ~ zscore_invage + zscore_delay + (1|ld8))
summary(MBE_age)
MBE_age <- lmer(data=MBE, meanAbsBestErr ~ invage * Delay + (1|ld8))
summary(MBE_age)

ggplot(data=MGS_age) + aes(x=as.numeric(age), y=meanAbsBestErr, color=as.factor(Delay)) + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + geom_point() + theme_classic(base_size=13)

# sd Best Error 
SDE <- MGS_age %>% 
  mutate(zscore_beh=scale(sdAbsBestErr, center=T, scale=T)) %>%
  filter(abs(zscore_beh) <= z_thres)
SDE <- SDE %>% mutate(zscore_invage=scale(invage, center=T, scale=T))
SDE <- SDE %>% mutate(zscore_delay=scale(Delay, center=T, scale=T))

sdBE_age <- lmer(data=SDE, sdAbsBestErr ~ invage + Delay + (1|ld8))
summary(sdBE_age)
SDE_z <- lmer(data=SDE, zscore_beh ~ zscore_invage + zscore_delay + (1|ld8))
summary(SDE_z)

ggplot(data=SDE) + aes(x=as.numeric(age), y=sdAbsBestErr, color=as.factor(Delay)) + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + geom_point() + theme_classic(base_size=13)

# MGS Latency
MLat <- MGS_age %>% 
  mutate(zscore_beh=scale(meanMGSLatency, center=T, scale=T)) %>%
  filter(abs(zscore_beh) <= z_thres)
MLat <- MLat %>% mutate(zscore_invage=scale(invage, center=T, scale=T))
MLat <- MLat %>% mutate(zscore_delay=scale(Delay, center=T, scale=T))

mlat_age <- lmer(data=MLat, meanMGSLatency ~ invage + Delay + (1|ld8))
summary(mlat_age)

mlat_z <- lmer(data=MLat, zscore_beh ~ zscore_invage + zscore_delay + (1|ld8))
summary(mlat_z)

ggplot(data=MLat) + aes(x=as.numeric(age), y=meanMGSLatency, color=as.factor(Delay)) + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + geom_point() + theme_classic(base_size=13)

# sd MGS Latency
sdMLat <- MGS_age %>% 
  mutate(zscore_beh=scale(sdMGSLatency, center=T, scale=T)) %>%
  filter(abs(zscore_beh) <= z_thres)
sdMLat <- sdMLat %>% mutate(zscore_invage=scale(invage, center=T, scale=T))
sdMLat <- sdMLat %>% mutate(zscore_delay=scale(Delay, center=T, scale=T))

sdmlat_age <- lmer(data=sdMLat, sdMGSLatency ~ invage + Delay + (1|ld8))
summary(sdmlat_age)

sdmlat_z <- lmer(data=sdMLat, zscore_beh ~ zscore_invage + zscore_delay + (1|ld8))
summary(sdmlat_z)

ggplot(data=sdMLat) + aes(x=as.numeric(age), y=sdMGSLatency, color=as.factor(Delay)) + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + geom_point() + theme_classic(base_size=13)




#### MGS Behavior and Residuals ####
# MRS 7 
ACC <- MRS7 %>% separate(ld8, into=c("LunaID", "ScanDate"), sep="_")
ACC_beh <- merge(ACC, subjData, by="LunaID")
z_thres <- 3
ACC_meanAbsPosErr <- ACC_beh %>%
  mutate(zscore=scale(meanAbsPosErr, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(ACC_meanAbsPosErr) + aes(y=meanAbsPosErr, x=residuals2, color=as.factor(agegrp)) +
  geom_point() + geom_smooth(method="lm") + 
  theme_classic(base_size = 13) +xlab("residuals") + ylab("mean AbsPosErr") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("ACC Residuals ~ Mean Abs Pos Err")

ggplot(ACC_meanAbsPosErr) + aes(y=meanAbsPosErr, x=residuals_inv, color=as.factor(agegrp)) +
  geom_point() + geom_smooth(method="lm") + 
  theme_classic(base_size = 13) +xlab("residuals") + ylab("mean AbsPosErr") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("ACC Residuals ~ Mean Abs Pos Err")


ACC_MAPE <- lmer(data=ACC_meanAbsPosErr, meanAbsPosErr ~ residuals2 *age + Delay + (1|LunaID))
summary(ACC_MAPE)

ACC_MAPE <- lmer(data=ACC_meanAbsPosErr, meanAbsPosErr ~ residuals2 *invage + Delay + (1|LunaID))
summary(ACC_MAPE)

ACC_MAPE <- lmer(data=ACC_meanAbsPosErr, meanAbsPosErr ~ residuals_inv *invage + Delay + (1|LunaID))
summary(ACC_MAPE)


ACC_sdAbsPosErr <- ACC_beh %>%
  mutate(zscore=scale(sdAbsPosErr, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(ACC_sdAbsPosErr) + aes(y=sdAbsPosErr, x=residuals2, color=as.factor(agegrp)) +
  geom_point() + geom_smooth(method="lm") + 
  theme_classic(base_size = 13) +xlab("residuals") + ylab("sd AbsPosErr") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("ACC Residuals ~ sd Abs Pos Err")

ACC_sdAPE <- lmer(data=ACC_sdAbsPosErr, sdAbsPosErr ~ residuals2 + Delay + age + (1|LunaID))
summary(ACC_sdAPE)

ACC_meanAbsBestErr <- ACC_beh %>%
  mutate(zscore=scale(meanAbsBestErr, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(ACC_meanAbsBestErr) + aes(y=meanAbsBestErr, x=residuals2, color=as.factor(agegrp)) +
  geom_point() + geom_smooth(method="lm") + 
  theme_classic(base_size = 13) +xlab("residuals") + ylab("mean AbsBestErr") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("ACC Residuals ~ Mean Abs Best Err")

ACC_MBPE <- lmer(data=ACC_meanAbsBestErr, meanAbsBestErr ~ residuals2 + Delay + age + (1|LunaID))
summary(ACC_MBPE)

ACC_MBPE2 <- lmer(data=ACC_meanAbsBestErr, meanAbsBestErr ~ residuals2 * age +  Delay + (1|LunaID))
summary(ACC_MBPE2)
ACC_MBPE3 <- lmer(data=ACC_meanAbsBestErr, meanAbsBestErr ~ residuals2 *invage + Delay + (1|LunaID))
summary(ACC_MBPE3)


ACC_sdAbsBestErr <- ACC_beh %>%
  mutate(zscore=scale(sdAbsBestErr, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(ACC_sdAbsBestErr) + aes(y=sdAbsBestErr, x=residuals2, color=as.factor(agegrp)) +
  geom_point() + geom_smooth(method="lm") + 
  theme_classic(base_size = 13) +xlab("residuals") + ylab("sd AbsBestErr") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("ACC Residuals ~ sd Abs Best Err")

ACC_sdABE <- lmer(data=ACC_sdAbsBestErr, sdAbsBestErr ~ residuals2 + Delay + age + (1|LunaID))
summary(ACC_sdABE)

ACC_sdBE3 <- lmer(data=ACC_sdAbsBestErr, sdAbsBestErr ~ residuals2 *invage + Delay + (1|LunaID))
summary(ACC_sdBE3)


ACC_meanAbsDispErr <- ACC_beh %>%
  mutate(zscore=scale(meanAbsDispErr, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(ACC_meanAbsDispErr) + aes(y=meanAbsDispErr, x=residuals2, color=as.factor(agegrp)) +
  geom_point() + geom_smooth(method="lm") + 
  theme_classic(base_size = 13) +xlab("residuals") + ylab("mean AbsDispErr") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("ACC Residuals ~ Mean Abs Disp Err")

ACC_MADE <- lmer(data=ACC_meanAbsDispErr, meanAbsDispErr ~ residuals2 + Delay + age + (1|LunaID))
summary(ACC_MADE)

ACC_sdAbsDispErr <- ACC_beh %>%
  mutate(zscore=scale(sdAbsDispErr, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(ACC_sdAbsDispErr) + aes(y=sdAbsDispErr, x=residuals2, color=as.factor(agegrp)) +
  geom_point() + geom_smooth(method="lm") + 
  theme_classic(base_size = 13) +xlab("residuals") + ylab("sd AbsDispErr") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("ACC Residuals ~ sd Abs Disp Err")

ACC_sdAPE <- lmer(data=ACC_sdAbsDispErr, sdAbsDispErr ~ residuals2 + Delay + age + (1|LunaID))
summary(ACC_sdAPE)

ACC_meanVGSLatency <- ACC_beh %>%
  mutate(zscore=scale(meanVGSLatency, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(ACC_meanVGSLatency) + aes(y=meanVGSLatency, x=residuals2, color=as.factor(Delay)) +
  geom_point() + geom_smooth(method="lm") + 
  theme_classic(base_size = 13) +xlab("residuals") + ylab("mean VGS Latency") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("ACC Residuals ~ Mean VGS Latency")

ACC_MVL <- lmer(data=ACC_meanVGSLatency, meanVGSLatency ~ residuals2 + Delay + age + (1|LunaID))
summary(ACC_MVL)

ACC_sdVGSLatency <- ACC_beh %>%
  mutate(zscore=scale(sdVGSLatency, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(ACC_sdVGSLatency) + aes(y=sdVGSLatency, x=residuals2, color=as.factor(Delay)) +
  geom_point() + geom_smooth(method="lm") + 
  theme_classic(base_size = 13) +xlab("residuals") + ylab("sd VGS Latency") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("ACC Residuals ~ sd VGS Latency")

ACC_MVL <- lmer(data=ACC_sdVGSLatency, sdVGSLatency ~ residuals2 + Delay + age + (1|LunaID))
summary(ACC_MVL)

ACC_meanMGSLatency <- ACC_beh %>%
  mutate(zscore=scale(meanMGSLatency, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(ACC_meanMGSLatency) + aes(y=meanMGSLatency, x=residuals2, color=as.factor(agegrp)) +
  geom_point() + geom_smooth(method="lm") + 
  theme_classic(base_size = 13) +xlab("residuals") + ylab("mean MGS Latency") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("ACC Residuals ~ Mean MGS Latency")

ACC_MML <- lmer(data=ACC_meanMGSLatency, meanMGSLatency ~ residuals2 + Delay + age + (1|LunaID))
summary(ACC_MML)
ACC_MML2 <- lmer(data=ACC_meanMGSLatency, meanMGSLatency ~ residuals2 *invage + Delay + (1|LunaID))
summary(ACC_MML2)

ACC_sdMGSLatency <- ACC_beh %>%
  mutate(zscore=scale(sdMGSLatency, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(ACC_sdMGSLatency) + aes(y=sdMGSLatency, x=residuals2, color=as.factor(agegrp)) +
  geom_point() + geom_smooth(method="lm") + 
  theme_classic(base_size = 13) +xlab("residuals") + ylab("sd MGS Latency") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("ACC Residuals ~ sd MGS Latency")

ACC_sML <- lmer(data=ACC_sdMGSLatency, sdMGSLatency ~ residuals2 + Delay + age + (1|LunaID))
summary(ACC_sML)
ACC_sML2 <- lmer(data=ACC_sdMGSLatency, sdMGSLatency ~ residuals2 *invage + Delay + (1|LunaID))
summary(ACC_sML2)



#### DLPFC Glu and MGS Behavior ####

# Glutamate and behavior

beh_Glu <- merge(subjData, ROI910_Glu, by="LunaID")
z_thres = 2

# Mean MGS Latency

beh_Glu_Latency <- beh_Glu %>%
  mutate(zscore=scale(meanMGSLatency, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(beh_Glu_Latency) + aes(y=meanMGSLatency, x=Glu.Cr, linetype = label, color=age) +
  geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + 
  theme_classic(base_size = 13) +xlab("Glu.Cr") + ylab("mean MGS Latency") + 
  labs(shape = "Hemisphere") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("DLPFC Glu ~ Latency") + 
  scale_color_gradient(low="blue", high="red")

Glu_Latency_1 <- lmer(data=beh_Glu, meanMGSLatency ~ Glu.Cr + label + Delay + sex + invage + (1|LunaID))
summary(Glu_Latency_1)
Glu_Latency_2 <- lmer(data=beh_Glu_Latency, meanMGSLatency ~ Glu.Cr*label + Delay + sex + invage + (1|LunaID))
summary(Glu_Latency_2)
Glu_Latency_3 <- lmer(data=beh_Glu, meanMGSLatency ~ Glu.Cr * invage + sex + label + Delay + (1|LunaID))
summary(Glu_Latency_3)


# Latency variability
beh_Glu_LatencySD <- beh_Glu %>%
  mutate(zscore=scale(sdMGSLatency, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(beh_Glu_LatencySD) + aes(y=sdMGSLatency, x=Glu.Cr, linetype = label, color=age) +
  geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + 
  theme_classic(base_size = 13) +xlab("Glu.Cr") + ylab("SD MGS Latency") + 
  labs(shape = "Hemisphere") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("DLPFC Glu ~ Variability in Latency ") + 
  scale_color_gradient(low="blue", high="red")

Glu_Latency_Var1 <- lmer(data=beh_Glu_LatencySD, sdMGSLatency ~ Glu.Cr + sex + label + Delay + invage + (1|LunaID))
summary(Glu_Latency_Var1)
Glu_Latency_Var2 <- lmer(data=beh_Glu_LatencySD, sdMGSLatency ~ Glu.Cr*label + sex + Delay + invage + (1|LunaID))
summary(Glu_Latency_Var2)
Glu_Latency_Var3 <- lmer(data=beh_Glu_LatencySD, sdMGSLatency ~ Glu.Cr*invage + sex + label + Delay + (1|LunaID))
summary(Glu_Latency_Var3)


# mean Position Error
beh_Glu_meanAbsPosErr <- beh_Glu %>%
  mutate(zscore=scale(meanAbsPosErr, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(beh_Glu_meanAbsPosErr) + aes(y=meanAbsPosErr, x=Glu.Cr, linetype = label, color=age) +
  geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + 
  theme_classic(base_size = 13) +xlab("Glu.Cr") + ylab("Mean Position Error") + 
  labs(shape = "Hemisphere") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("DLPFC Glu ~ Mean Position Error") + 
  scale_color_gradient(low="blue", high="red")

Glu_meanAbsPosErr1 <- lmer(data=beh_Glu_meanAbsPosErr, meanAbsPosErr ~ Glu.Cr+label + sex+ Delay + invage + (1|LunaID))
summary(Glu_meanAbsPosErr1)
Glu_meanAbsPosErr2 <- lmer(data=beh_Glu_meanAbsPosErr, meanAbsPosErr ~ Glu.Cr*label + sex+Delay + invage + (1|LunaID))
summary(Glu_meanAbsPosErr2)
Glu_meanAbsPosErr3 <- lmer(data=beh_Glu_meanAbsPosErr, meanAbsPosErr ~ Glu.Cr* invage + sex+label + Delay +  (1|LunaID))
summary(Glu_meanAbsPosErr3)


# sd Position Error 
beh_Glu_sdAbsPosErr <- beh_Glu %>%
  mutate(zscore=scale(sdAbsPosErr, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(beh_Glu_sdAbsPosErr) + aes(y=sdAbsPosErr, x=Glu.Cr, linetype = label, color=age) +
  geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + 
  theme_classic(base_size = 13) +xlab("Glu.Cr") + ylab("SD Position Error") + 
  labs(shape = "Hemisphere") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("DLPFC Glu~Variability in Mean Position Error ") + 
  scale_color_gradient(low="blue", high="red")

Glu_sdAbsPosErr1 <- lmer(data=beh_Glu_sdAbsPosErr, sdAbsPosErr ~ Glu.Cr+ invage + sex + label + Delay + (1|LunaID))
summary(Glu_sdAbsPosErr1)
Glu_sdAbsPosErr2 <- lmer(data=beh_Glu_sdAbsPosErr, sdAbsPosErr ~ Glu.Cr* invage + sex + label + Delay + (1|LunaID))
summary(Glu_sdAbsPosErr2)
Glu_sdAbsPosErr3 <- lmer(data=beh_Glu_sdAbsPosErr, sdAbsPosErr ~ Glu.Cr * label + sex + invage +  Delay + (1|LunaID))
summary(Glu_sdAbsPosErr3)

# mean best error 
beh_Glu_meanAbsBestErr <- beh_Glu %>%
  mutate(zscore=scale(meanAbsBestErr, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(beh_Glu_meanAbsBestErr) + aes(y=meanAbsBestErr, x=Glu.Cr, linetype = label, color=age) +
  geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + 
  theme_classic(base_size = 13) +xlab("Glu.Cr") + ylab("Mean Best Error") + 
  labs(shape = "Hemisphere") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle(" DLPFC Glu~Mean Best Error ") + 
  scale_color_gradient(low="blue", high="red")

Glu_meanAbsBestErr1 <- lmer(data=beh_Glu_meanAbsBestErr, meanAbsBestErr ~ Glu.Cr+ sex + label + Delay + invage + (1|LunaID))
summary(Glu_meanAbsBestErr1)
Glu_meanAbsBestErr2 <- lmer(data=beh_Glu_meanAbsBestErr, meanAbsBestErr ~ Glu.Cr*label + sex + Delay + invage + (1|LunaID))
summary(Glu_meanAbsBestErr2)
Glu_meanAbsBestErr3 <- lmer(data=beh_Glu_meanAbsBestErr, meanAbsBestErr ~ Glu.Cr * invage + sex + label + Delay + (1|LunaID))
summary(Glu_meanAbsBestErr3)


# SD best error 
beh_Glu_SDAbsBestErr <- beh_Glu %>%
  mutate(zscore=scale(sdAbsBestErr, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(beh_Glu_SDAbsBestErr) + aes(y=sdAbsBestErr, x=Glu.Cr, linetype = label, color=age) +
  geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + 
  theme_classic(base_size = 13) +xlab("Glu.Cr") + ylab("SD in Mean Best Error") + 
  labs(shape = "Hemisphere") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("DLPFC Glu ~ Variability in Best Error") + 
  scale_color_gradient(low="blue", high="red")

Glu_sdAbsBestErr1 <- lmer(data=beh_Glu_SDAbsBestErr, sdAbsBestErr ~ Glu.Cr+ label + sex+  Delay + invage + (1|LunaID))
summary(Glu_sdAbsBestErr1)
Glu_sdAbsBestErr2 <- lmer(data=beh_Glu_SDAbsBestErr, sdAbsBestErr ~ Glu.Cr*label + sex+ Delay + invage + (1|LunaID))
summary(Glu_sdAbsBestErr2)
Glu_sdAbsBestErr3 <- lmer(data=beh_Glu_SDAbsBestErr, sdAbsBestErr ~ Glu.Cr*invage + sex+ label + Delay +  (1|LunaID))
summary(Glu_sdAbsBestErr3)



# mean Disp error 
beh_Glu_meanAbsDispErr <- beh_Glu %>%
  mutate(zscore=scale(meanAbsDispErr, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(beh_Glu_meanAbsDispErr) + aes(y=meanAbsDispErr, x=Glu.Cr, linetype = label, color=age) +
  geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + 
  theme_classic(base_size = 13) +xlab("Glu.Cr") + ylab("Mean Disp Error") + 
  labs(shape = "Hemisphere") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle(" DLPFC Glu~Mean Displacement Error ") + 
  scale_color_gradient(low="blue", high="red")

Glu_meanAbsDispErr1 <- lmer(data=beh_Glu_meanAbsDispErr, meanAbsDispErr ~ Glu.Cr+ sex + label + Delay + invage + (1|LunaID))
summary(Glu_meanAbsDispErr1)
Glu_meanAbsDispErr2 <- lmer(data=beh_Glu_meanAbsDispErr, meanAbsDispErr ~ Glu.Cr*label + sex + Delay + invage + (1|LunaID))
summary(Glu_meanAbsDispErr2)
Glu_meanAbsDispErr3 <- lmer(data=beh_Glu_meanAbsDispErr, meanAbsDispErr ~ Glu.Cr * invage + sex + label + Delay + (1|LunaID))
summary(Glu_meanAbsDispErr3)



# SD best error 
beh_Glu_SDAbsDispErr <- beh_Glu %>%
  mutate(zscore=scale(sdAbsDispErr, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(beh_Glu_SDAbsDispErr) + aes(y=sdAbsDispErr, x=Glu.Cr, linetype = label, color=age) +
  geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + 
  theme_classic(base_size = 13) +xlab("Glu.Cr") + ylab("SD in Mean Disp Error") + 
  labs(shape = "Hemisphere") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("DLPFC Glu ~ Variability in Disp Error") + 
  scale_color_gradient(low="blue", high="red")

Glu_sdAbsDispErr1 <- lmer(data=beh_Glu_SDAbsDispErr, sdAbsDispErr ~ Glu.Cr+ label + sex+  Delay + invage + (1|LunaID))
summary(Glu_sdAbsDispErr1)
Glu_sdAbsDispErr2 <- lmer(data=beh_Glu_SDAbsDispErr, sdAbsDispErr ~ Glu.Cr*label + sex+ Delay + invage + (1|LunaID))
summary(Glu_sdAbsDispErr2)
Glu_sdAbsDispErr3 <- lmer(data=beh_Glu_SDAbsDispErr, sdAbsDispErr ~ Glu.Cr*invage + sex+ label + Delay +  (1|LunaID))
summary(Glu_sdAbsDispErr3)

#### DLPFC GABA and MGS behavior ####
# merge GABA and subjData
beh_GABA <- merge(subjData, ROI910_GABA, by="LunaID")

# Mean MGS Latency

beh_GABA_Latency <- beh_GABA %>%
  mutate(zscore=scale(meanMGSLatency, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(beh_GABA_Latency) + aes(y=meanMGSLatency, x=GABA.Cr, linetype = label, color=age) +
  geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + 
  theme_classic(base_size = 13) +xlab("GABA.Cr") + ylab("mean MGS Latency") + 
  labs(shape = "Hemisphere") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("DLPFC GABA ~ Latency") + 
  scale_color_gradient(low="blue", high="red")

GABA_Latency_1 <- lmer(data=beh_GABA, meanMGSLatency ~ GABA.Cr + label + Delay + sex + invage + (1|LunaID))
summary(GABA_Latency_1)
GABA_Latency_2 <- lmer(data=beh_GABA_Latency, meanMGSLatency ~ GABA.Cr*label + Delay + sex + invage + (1|LunaID))
summary(GABA_Latency_2)
GABA_Latency_3 <- lmer(data=beh_GABA, meanMGSLatency ~ GABA.Cr * invage + sex + label + Delay + (1|LunaID))
summary(GABA_Latency_3)

# Latency variability
beh_GABA_LatencySD <- beh_GABA %>%
  mutate(zscore=scale(sdMGSLatency, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(beh_GABA_LatencySD) + aes(y=sdMGSLatency, x=GABA.Cr, linetype = label, color=age) +
  geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + 
  theme_classic(base_size = 13) +xlab("GABA.Cr") + ylab("SD MGS Latency") + 
  labs(shape = "Hemisphere") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("DLPFC GABA ~ Variability in Latency ") + 
  scale_color_gradient(low="blue", high="red")

GABA_Latency_Var1 <- lmer(data=beh_GABA_LatencySD, sdMGSLatency ~ GABA.Cr + sex + label + Delay + invage + (1|LunaID))
summary(GABA_Latency_Var1)
GABA_Latency_Var2 <- lmer(data=beh_GABA_LatencySD, sdMGSLatency ~ GABA.Cr*label + sex + Delay + invage + (1|LunaID))
summary(GABA_Latency_Var2)
GABA_Latency_Var3 <- lmer(data=beh_GABA_LatencySD, sdMGSLatency ~ GABA.Cr*invage + sex + label + Delay + (1|LunaID))
summary(GABA_Latency_Var3)


# mean Position Error
beh_GABA_meanAbsPosErr <- beh_GABA %>%
  mutate(zscore=scale(meanAbsPosErr, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(beh_GABA_meanAbsPosErr) + aes(y=meanAbsPosErr, x=GABA.Cr, linetype = label, color=age) +
  geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + 
  theme_classic(base_size = 13) +xlab("GABA.Cr") + ylab("Mean Position Error") + 
  labs(shape = "Hemisphere") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("DLPFC GABA ~ Mean Position Error") + 
  scale_color_gradient(low="blue", high="red")

GABA_meanAbsPosErr1 <- lmer(data=beh_GABA_meanAbsPosErr, meanAbsPosErr ~ GABA.Cr+label + sex+ Delay + invage + (1|LunaID))
summary(GABA_meanAbsPosErr1)
GABA_meanAbsPosErr2 <- lmer(data=beh_GABA_meanAbsPosErr, meanAbsPosErr ~ GABA.Cr*label + sex+Delay + invage + (1|LunaID))
summary(GABA_meanAbsPosErr2)
GABA_meanAbsPosErr3 <- lmer(data=beh_GABA_meanAbsPosErr, meanAbsPosErr ~ GABA.Cr* invage + sex+label + Delay +  (1|LunaID))
summary(GABA_meanAbsPosErr3)


# sd Position Error 
beh_GABA_sdAbsPosErr <- beh_GABA %>%
  mutate(zscore=scale(sdAbsPosErr, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(beh_GABA_sdAbsPosErr) + aes(y=sdAbsPosErr, x=GABA.Cr, linetype = label, color=age) +
  geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + 
  theme_classic(base_size = 13) +xlab("GABA.Cr") + ylab("SD Position Error") + 
  labs(shape = "Hemisphere") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("DLPFC GABA~Variability in Mean Position Error ") + 
  scale_color_gradient(low="blue", high="red")

GABA_sdAbsPosErr1 <- lmer(data=beh_GABA_sdAbsPosErr, sdAbsPosErr ~ GABA.Cr+ invage + sex + label + Delay + (1|LunaID))
summary(GABA_sdAbsPosErr1)
GABA_sdAbsPosErr2 <- lmer(data=beh_GABA_sdAbsPosErr, sdAbsPosErr ~ GABA.Cr* invage + sex + label + Delay + (1|LunaID))
summary(GABA_sdAbsPosErr2)
GABA_sdAbsPosErr3 <- lmer(data=beh_GABA_sdAbsPosErr, sdAbsPosErr ~ GABA.Cr * label + sex + invage +  Delay + (1|LunaID))
summary(GABA_sdAbsPosErr3)


# mean best error 
beh_GABA_meanAbsBestErr <- beh_GABA %>%
  mutate(zscore=scale(meanAbsBestErr, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(beh_GABA_meanAbsBestErr) + aes(y=meanAbsBestErr, x=GABA.Cr, linetype = label, color=age) +
  geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + 
  theme_classic(base_size = 13) +xlab("GABA.Cr") + ylab("Mean Best Error") + 
  labs(shape = "Hemisphere") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle(" DLPFC GABA~Mean Best Error ") + 
  scale_color_gradient(low="blue", high="red")

GABA_meanAbsBestErr1 <- lmer(data=beh_GABA_meanAbsBestErr, meanAbsBestErr ~ GABA.Cr+ sex + label + Delay + invage + (1|LunaID))
summary(GABA_meanAbsBestErr1)
GABA_meanAbsBestErr2 <- lmer(data=beh_GABA_meanAbsBestErr, meanAbsBestErr ~ GABA.Cr*label + sex + Delay + invage + (1|LunaID))
summary(GABA_meanAbsBestErr2)
GABA_meanAbsBestErr3 <- lmer(data=beh_GABA_meanAbsBestErr, meanAbsBestErr ~ GABA.Cr * invage + sex + label + Delay + (1|LunaID))
summary(GABA_meanAbsBestErr3)


# SD best error 
beh_GABA_SDAbsBestErr <- beh_GABA %>%
  mutate(zscore=scale(sdAbsBestErr, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(beh_GABA_SDAbsBestErr) + aes(y=sdAbsBestErr, x=GABA.Cr, linetype = label, color=age) +
  geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + 
  theme_classic(base_size = 13) +xlab("GABA.Cr") + ylab("SD in Mean Best Error") + 
  labs(shape = "Hemisphere") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("DLPFC GABA ~ Variability in Best Error") + 
  scale_color_gradient(low="blue", high="red")

GABA_sdAbsBestErr1 <- lmer(data=beh_GABA_SDAbsBestErr, sdAbsBestErr ~ GABA.Cr+ label + sex+  Delay + invage + (1|LunaID))
summary(GABA_sdAbsBestErr1)
GABA_sdAbsBestErr2 <- lmer(data=beh_GABA_SDAbsBestErr, sdAbsBestErr ~ GABA.Cr*label + sex+ Delay + invage + (1|LunaID))
summary(GABA_sdAbsBestErr2)
GABA_sdAbsBestErr3 <- lmer(data=beh_GABA_SDAbsBestErr, sdAbsBestErr ~ GABA.Cr*invage + sex+ label + Delay +  (1|LunaID))
summary(GABA_sdAbsBestErr3)


# mean Disp error 
beh_GABA_meanAbsDispErr <- beh_GABA %>%
  mutate(zscore=scale(meanAbsDispErr, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(beh_GABA_meanAbsDispErr) + aes(y=meanAbsDispErr, x=GABA.Cr, linetype = label, color=age) +
  geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + 
  theme_classic(base_size = 13) +xlab("GABA.Cr") + ylab("Mean Disp Error") + 
  labs(shape = "Hemisphere") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle(" DLPFC GABA~Mean Displacement Error ") + 
  scale_color_gradient(low="blue", high="red")

GABA_meanAbsDispErr1 <- lmer(data=beh_GABA_meanAbsDispErr, meanAbsDispErr ~ GABA.Cr+ sex + label + Delay + invage + (1|LunaID))
summary(GABA_meanAbsDispErr1)
GABA_meanAbsDispErr2 <- lmer(data=beh_GABA_meanAbsDispErr, meanAbsDispErr ~ GABA.Cr*label + sex + Delay + invage + (1|LunaID))
summary(GABA_meanAbsDispErr2)
GABA_meanAbsDispErr3 <- lmer(data=beh_GABA_meanAbsDispErr, meanAbsDispErr ~ GABA.Cr * invage + sex + label + Delay + (1|LunaID))
summary(GABA_meanAbsDispErr3)



# SD best error 
beh_GABA_SDAbsDispErr <- beh_GABA %>%
  mutate(zscore=scale(sdAbsDispErr, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(beh_GABA_SDAbsDispErr) + aes(y=sdAbsDispErr, x=GABA.Cr, linetype = label, color=age) +
  geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + 
  theme_classic(base_size = 13) +xlab("GABA.Cr") + ylab("SD in Mean Disp Error") + 
  labs(shape = "Hemisphere") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("DLPFC GABA ~ Variability in Disp Error") + 
  scale_color_gradient(low="blue", high="red")

GABA_sdAbsDispErr1 <- lmer(data=beh_GABA_SDAbsDispErr, sdAbsDispErr ~ GABA.Cr+ label + sex+  Delay + invage + (1|LunaID))
summary(GABA_sdAbsDispErr1)
GABA_sdAbsDispErr2 <- lmer(data=beh_GABA_SDAbsDispErr, sdAbsDispErr ~ GABA.Cr*label + sex+ Delay + invage + (1|LunaID))
summary(GABA_sdAbsDispErr2)
GABA_sdAbsDispErr3 <- lmer(data=beh_GABA_SDAbsDispErr, sdAbsDispErr ~ GABA.Cr*invage + sex+ label + Delay +  (1|LunaID))
summary(GABA_sdAbsDispErr3)


#### DLPFC Ratio and MGS Behavior ####
# merge ratio and subjData
beh_Ratio <- merge(subjData, ROI910_Ratio, by="LunaID")

# Latency
beh_ratio_Latency <- beh_Ratio %>%
  mutate(zscore=scale(meanMGSLatency, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(beh_ratio_Latency) + aes(y=meanMGSLatency, x=Ratio, linetype = label, color=age) +
  geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + 
  theme_classic(base_size = 13) +xlab("Glu/GABA") + ylab("mean MGS Latency") + 
  labs(shape = "Hemisphere") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("DLPFC Glu/GABA ~ Latency") + 
  scale_color_gradient(low="blue", high="red")

ratio_Latency_1 <- lmer(data=beh_ratio_Latency, meanMGSLatency ~ Ratio + label + Delay + sex + invage + (1|LunaID))
summary(ratio_Latency_1)
ratio_Latency_2 <- lmer(data=beh_ratio_Latency, meanMGSLatency ~ Ratio*label + Delay + sex + invage + (1|LunaID))
summary(ratio_Latency_2)
ratio_Latency_3 <- lmer(data=beh_ratio_Latency, meanMGSLatency ~ Ratio * invage + sex + label + Delay + (1|LunaID))
summary(ratio_Latency_3)


# Variability in Latency
beh_ratio_sdLatency <- beh_Ratio %>%
  mutate(zscore=scale(sdMGSLatency, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(beh_ratio_sdLatency) + aes(y=sdMGSLatency, x=Ratio, linetype = label, color=age) +
  geom_point() + geom_smooth(method="lm", formula = y~I(1/x), fullrange=T) + 
  theme_classic(base_size = 13) +xlab("Glu/GABA") + ylab("Variability in MGS Latency") + 
  labs(shape = "Hemisphere") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("DLPFC Glu/GABA ~ Variability Latency") + 
  scale_color_gradient(low="blue", high="red")

ratio_sdLatency_1 <- lmer(data=beh_ratio_sdLatency, sdMGSLatency ~ Ratio + label + Delay + sex + invage + (1|LunaID))
summary(ratio_sdLatency_1)
ratio_sdLatency_2 <- lmer(data=beh_ratio_sdLatency, sdMGSLatency ~ Ratio*label + Delay + sex + invage + (1|LunaID))
summary(ratio_sdLatency_2)
ratio_sdLatency_3 <- lmer(data=beh_ratio_sdLatency, sdMGSLatency ~ Ratio * invage + sex + label + Delay + (1|LunaID))
summary(ratio_sdLatency_3)


Ratio_meanAbsPosErr <- lmer(data=beh_Ratio, meanAbsPosErr ~ Ratio*label + Delay + invage + (1|LunaID))
summary(Ratio_meanAbsPosErr)

Ratio_sdAbsPosErr <- lmer(data=beh_Ratio, sdAbsPosErr ~ Ratio*label + Delay + invage + (1|LunaID))
summary(Ratio_sdAbsPosErr)

Ratio_meanAbsBestErr <- lmer(data=beh_Ratio, meanAbsBestErr ~ Ratio*label + Delay + invage + (1|LunaID))
summary(Ratio_meanAbsBestErr)

Ratio_sdAbsBestErr <- lmer(data=beh_Ratio, sdAbsBestErr ~ Ratio*label + Delay + invage + (1|LunaID))
summary(Ratio_sdAbsBestErr)

Ratio_meanAbsDispErr <- lmer(data=beh_Ratio, meanAbsDispErr ~ Ratio*label + Delay + invage + (1|LunaID))
summary(Ratio_meanAbsDispErr)

Ratio_sdAbsDispErr <- lmer(data=beh_Ratio, sdAbsDispErr ~ Ratio*label + Delay + invage + (1|LunaID))
summary(Ratio_sdAbsDispErr)


#### PCA ####

# Glutamate 
Glu_wide_PCA <- pivot_wider(MRS_glu, id_cols=ld8, names_from=label, values_from=Glu.Cr)
Glu_wide_PCA <- select(Glu_wide_PCA, -`R STS`, -`L STS`, -`R Thalamus`, -`R Caudate`, -`L Caudate`, -`R Posterior Insula`, -`L Posterior Insula`)

nb_glu_kfold <- estim_ncpPCA(Glu_wide_PCA %>% select(-ld8),method.cv = "Kfold", verbose = FALSE) 
nb_glu_kfold$ncp
nb_glu_kfold$ncp <- 2
plot(0:5, nb_glu_kfold$criterion, xlab = "nb dim", ylab = "MSEP")

res_comp_glu <- imputePCA(Glu_wide_PCA %>% select(-ld8), ncp = nb_glu_kfold$ncp) # iterativePCA algorithm

glu_pca <- PCA(res_comp_glu, ncp = nb_glu_kfold$ncp)
plot(glu_pca)
plot(glu_pca, choix="var")

Glu_wide_PCA$dim1 <- glu_pca$ind$coord[,1]
dim1_lai <- lm(data=Glu_wide_PCA, `MPFC` ~ dim1)
summary(dim1_lai)

ggplot(Glu_wide_PCA) + aes(y=dim1, x=`L Anterior Insula`) +
  geom_point() + geom_smooth(method="lm") + 
  theme_classic(base_size = 13) +xlab("L Anterior Insula") + ylab("dim1") + 
  theme(legend.key = element_rect(fill = "white", colour = "black"))

ages <- read.table("/Users/mariaperica/Desktop/Lab/Projects/2020_MRSMGS/all_demo.tsv", sep="\t")
names(ages) <- c('ld8','age','sex','vtype','study', 'badcol')
ages <- rbind(ages, c("11681_20180921", 14.24, "F", "Scan", "BrainMechR01"))
ages <- rbind(ages, c("11718_20190112", 13.33, "M", "Scan", "BrainMechR01"))
ages <- rbind(ages, c("11802_20190906", 21.72, "F", "Scan", "BrainMechR01"))
ages <- ages %>% filter(vtype == 'Scan')
ages <- ages %>% filter(study == 'BrainMechR01')
Glu_wide_PCA_age <- left_join(Glu_wide_PCA, ages %>% select(ld8, age))
Glu_wide_PCA_age$age <- as.numeric(Glu_wide_PCA_age$age)

ggplot(Glu_wide_PCA_age) + aes(y=dim1, x=age) +
  geom_point() + geom_smooth(method="lm") + 
  theme_classic(base_size = 13) +xlab("age") + ylab("dim1") + 
  theme(legend.key = element_rect(fill = "white", colour = "black"))
dim1_age <- lm(data=Glu_wide_PCA_age, age ~ dim1)
summary(dim1_age)

# what components load onto it
glu_pca$var$cor # L & R Ant Ins most strongly, but all highly do; for GABA it's weaker but L Ant Ins loads most strongly

# GABA
GABA_wide_PCA <- pivot_wider(MRS_GABA, id_cols=ld8, names_from=label, values_from=GABA.Cr)
GABA_wide_PCA <- select(GABA_wide_PCA, -`R STS`, -`L STS`, -`R Thalamus`, -`R Caudate`, -`L Caudate`, -`R Posterior Insula`, -`L Posterior Insula`)

nb_GABA_kfold <- estim_ncpPCA(GABA_wide_PCA %>% select(-ld8),method.cv = "Kfold", verbose = FALSE) 
nb_GABA_kfold$ncp
nb_GABA_kfold$ncp <- 2
plot(0:5, nb_GABA_kfold$criterion, xlab = "nb dim", ylab = "MSEP")

res_comp_GABA <- imputePCA(GABA_wide_PCA %>% select(-ld8), ncp = nb_GABA_kfold$ncp) # iterativePCA algorithm

GABA_pca <- PCA(res_comp_GABA, ncp = nb_GABA_kfold$ncp)
plot(GABA_pca)
plot(GABA_pca, choix="var")

GABA_wide_PCA$dim1 <- GABA_pca$ind$coord[,1]
dim1_lai <- lm(data=GABA_wide_PCA, `L Anterior Insula` ~ dim1)
summary(dim1_lai)

ggplot(GABA_wide_PCA) + aes(y=dim1, x=`L Anterior Insula`) +
  geom_point() + geom_smooth(method="lm") + 
  theme_classic(base_size = 13) +xlab("L Anterior Insula") + ylab("dim1") + 
  theme(legend.key = element_rect(fill = "white", colour = "black"))

GABA_wide_PCA_age <- left_join(GABA_wide_PCA, ages %>% select(ld8, age))
GABA_wide_PCA_age$age <- as.numeric(GABA_wide_PCA_age$age)

ggplot(GABA_wide_PCA_age) + aes(y=dim1, x=age) +
  geom_point() + geom_smooth(method="lm") + 
  theme_classic(base_size = 13) +xlab("age") + ylab("dim1") + 
  theme(legend.key = element_rect(fill = "white", colour = "black"))
dim1_age <- lm(data=GABA_wide_PCA_age, age ~ dim1)
summary(dim1_age)

# are the glu component and gaba component correlated
GABA_tomerge <- select(GABA_wide_PCA_age, ld8, dim1, age)
names(GABA_tomerge) <- c('ld8', 'GABA_comp', 'age')
Glu_tomerge <- select(Glu_wide_PCA_age, ld8, dim1)
names(Glu_tomerge) <- c('ld8', 'Glu_comp')
Glu_GABA_PCA <- merge(GABA_tomerge, Glu_tomerge, by="ld8")
Glu_GABA_PCA$ratio <- Glu_GABA_PCA$Glu_comp/Glu_GABA_PCA$GABA_comp
ggplot(Glu_GABA_PCA) + aes(y=ratio, x=age) +
  geom_point() + geom_smooth(method="loess") + 
  theme_classic(base_size = 13) +xlab("age") + ylab("Glu component/ GABA component ") + 
  theme(legend.key = element_rect(fill = "white", colour = "black"))
Glu_GABA_PCA <- Glu_GABA_PCA %>%
  mutate(zscore=scale(ratio, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

Glu_GABA_PCA %>% mutate(agegrp=cut(breaks=c(0,16,22,Inf), age)) %>% split(.$agegrp) %>% sapply(function(x) cor(x$Glu_comp, x$GABA_comp))
Glu_GABA_PCA %>% mutate(agegrp=cut(breaks=c(0,16,22,Inf), age)) %>% group_by(agegrp) %>% tally
Glu_GABA_PCA <- Glu_GABA_PCA %>% mutate(agegrp=cut(breaks=c(0,16,22,Inf), age))
ggplot(Glu_GABA_PCA) + aes(y=GABA_comp, x=Glu_comp) +
  geom_point() + geom_smooth(method="lm") + 
  theme_classic(base_size = 13) +xlab("Glu component" ) + ylab("GABA component") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("Components correlation by age group") +
  facet_wrap(~ agegrp)

# compare correlations of the PCA components 
cor_vals <- Glu_GABA_PCA %>%
  group_by(agegrp) %>%
  summarise(GabaGlu_r=cor(Glu_comp, GABA_comp), 
            GabaGlu_p=cor.test(Glu_comp, GABA_comp, method=c("pearson"), use = "complete.obs")$p.value, 
            GabaGlu_lb=cor.test(Glu_comp, GABA_comp, method=c("pearson"), use = "complete.obs", conf.level=.95)$conf.int[1], 
            GabaGlu_ub=cor.test(Glu_comp, GABA_comp, method=c("pearson"), use = "complete.obs", conf.level=.95)$conf.int[2], 
            n=n())

ggplot(cor_vals) +
  aes(x=agegrp, y=GabaGlu_r, fill=agegrp) +
  geom_bar(stat="identity") +
  theme_classic(base_size = 15) + labs(x='Age',y='GABA Glu Corr (r)') +
  scale_fill_brewer(palette = "viridis")

d_subset <- cor_vals %>% select(agegrp, r=GabaGlu_r, n)
d_pvals <- merge(d_subset,d_subset,by=NULL) %>% 
  mutate(pval=Vectorize(cocor::cocor.indep.groups)(r1.jk=r.x, r2.hm=r.y, n1=n.x, n2=n.y,
                                                   alternative="two.sided", alpha=0.05) %>% 
           sapply(function(x) x@fisher1925$p.value)
  )
p.adjust(d_pvals$pval, method="fdr") < .05
d_pvals %>% mutate(p_adjust = p.adjust(pval, method="fdr")) %>% filter(p_adjust < .05)


#### Glutamate PCA component and MGS Behavior ####
z_thres <- 3

Glu_wide_PCA_age <- Glu_wide_PCA_age %>% separate(ld8, into=c("LunaID", "ScanDate"), sep="_")
beh_GluPCA <- merge(subjData, Glu_wide_PCA_age, by="LunaID")
beh_GluPCA$invage <- 1/beh_GluPCA$age

# Mean MGS Latency

beh_GluPCA_Latency <- beh_GluPCA %>%
  mutate(zscore=scale(meanMGSLatency, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(beh_GluPCA_Latency) + aes(y=meanMGSLatency, x=dim1, color=age) +
  geom_point() + geom_smooth(method="loess") + 
  theme_classic(base_size = 13) +xlab("Glu Component") + ylab("mean MGS Latency") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("Glu Component ~ Latency") +
  scale_color_gradient(low="blue", high="red")

Glu_meanLatency_1 <- lmer(data=beh_GluPCA_Latency, meanMGSLatency ~ dim1+ Delay + invage + (1|LunaID))
summary(Glu_meanLatency_1)
Glu_meanLatency_2 <- lmer(data=beh_GluPCA_Latency, meanMGSLatency ~ dim1 * invage + Delay + (1|LunaID))
summary(Glu_meanLatency_2)


# sd MGS Latency

beh_GluPCA_sdLatency <- beh_GluPCA %>%
  mutate(zscore=scale(sdMGSLatency, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(beh_GluPCA_sdLatency) + aes(y=sdMGSLatency, x=dim1, color=age) +
  geom_point() + geom_smooth(method="lm") + 
  theme_classic(base_size = 13) +xlab("Glu Component") + ylab("sd MGS Latency") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("Glu Component ~ sd Latency") +
  scale_color_gradient(low="blue", high="red")

Glu_sdLatency_1 <- lmer(data=beh_GluPCA_sdLatency, sdMGSLatency ~ dim1+ Delay + invage + (1|LunaID))
summary(Glu_sdLatency_1)
Glu_sdLatency_2 <- lmer(data=beh_GluPCA_sdLatency, sdMGSLatency ~ dim1 * invage + Delay + (1|LunaID))
summary(Glu_sdLatency_2)

# mean Abs Pos Error

beh_GluPCA_MAbsPosError <- beh_GluPCA %>%
  mutate(zscore=scale(meanAbsPosErr, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(beh_GluPCA_MAbsPosError) + aes(y=meanAbsPosErr, x=dim1, color=age) +
  geom_point() + geom_smooth(method="loess") + 
  theme_classic(base_size = 13) +xlab("Glu Component") + ylab("mean Abs Pos Error") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("Glu Component ~ mean Abs Pos Error") +
  scale_color_gradient(low="blue", high="red")

Glu_MAbsPosError_1 <- lmer(data=beh_GluPCA_MAbsPosError, meanAbsPosErr ~ dim1+ Delay + invage + (1|LunaID))
summary(Glu_MAbsPosError_1)
Glu_MAbsPosError_2 <- lmer(data=beh_GluPCA_MAbsPosError, meanAbsPosErr ~ dim1 * invage + Delay + (1|LunaID))
summary(Glu_MAbsPosError_2)

# sd Abs Pos Error

beh_GluPCA_sdAbsPosError <- beh_GluPCA %>%
  mutate(zscore=scale(sdAbsPosErr, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(beh_GluPCA_sdAbsPosError) + aes(y=sdAbsPosErr, x=dim1, color=age) +
  geom_point() + geom_smooth(method="loess") + 
  theme_classic(base_size = 13) +xlab("Glu Component") + ylab("sd Abs Pos Error") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("Glu Component ~ sd Abs Pos Error")

Glu_sdAbsPosError_1 <- lmer(data=beh_GluPCA_sdAbsPosError, sdAbsPosErr ~ dim1+ Delay + invage + (1|LunaID))
summary(Glu_sdAbsPosError_1)
Glu_sdAbsPosError_2 <- lmer(data=beh_GluPCA_sdAbsPosError, sdAbsPosErr ~ dim1 * invage + Delay + (1|LunaID))
summary(Glu_sdAbsPosError_2)

# mean abs best error
beh_GluPCA_MAbsBestError <- beh_GluPCA %>%
  mutate(zscore=scale(meanAbsBestErr, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(beh_GluPCA_MAbsBestError) + aes(y=meanAbsBestErr, x=dim1, color=age) +
  geom_point() + geom_smooth(method="loess") + 
  theme_classic(base_size = 13) +xlab("Glu Component") + ylab("mean Abs Best Error") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("Glu Component ~ mean Abs Best Error") +
  scale_color_gradient(low="blue", high="red")

Glu_MAbsBestError_1 <- lmer(data=beh_GluPCA_MAbsBestError, meanAbsBestErr ~ dim1+ invage + Delay + (1|LunaID))
summary(Glu_MAbsBestError_1)
Glu_MAbsBestError_2 <- lmer(data=beh_GluPCA_MAbsBestError, meanAbsBestErr ~ dim1 * invage + Delay + (1|LunaID))
summary(Glu_MAbsBestError_2)

# sd Abs Best Error

beh_GluPCA_sdAbsBestError <- beh_GluPCA %>%
  mutate(zscore=scale(sdAbsBestErr, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(beh_GluPCA_sdAbsBestError) + aes(y=sdAbsBestErr, x=dim1, color=age) +
  geom_point() + geom_smooth(method="loess") + 
  theme_classic(base_size = 13) +xlab("Glu Component") + ylab("sd Abs Best Error") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("Glu Component ~ sd Abs Best Error") +
  scale_color_gradient(low="blue", high = "red")

Glu_sdAbsBestError_1 <- lmer(data=beh_GluPCA_sdAbsBestError, sdAbsBestErr ~ dim1+ Delay + invage + (1|LunaID))
summary(Glu_sdAbsBestError_1)
Glu_sdAbsBestError_2 <- lmer(data=beh_GluPCA_sdAbsBestError, sdAbsBestErr ~ dim1 * invage + Delay + (1|LunaID))
summary(Glu_sdAbsBestError_2)

# mean abs disp error
beh_GluPCA_MAbsDispError <- beh_GluPCA %>%
  mutate(zscore=scale(meanAbsDispErr, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(beh_GluPCA_MAbsDispError) + aes(y=meanAbsDispErr, x=dim1, color=age) +
  geom_point() + geom_smooth(method="loess") + 
  theme_classic(base_size = 13) +xlab("Glu Component") + ylab("mean Abs Disp Error") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("Glu Component ~ mean Abs Disp Error") +
  scale_color_gradient(low="blue", high="red")

Glu_MAbsDispError_1 <- lmer(data=beh_GluPCA_MAbsDispError, meanAbsDispErr ~ dim1+ Delay + invage + (1|LunaID))
summary(Glu_MAbsDispError_1)
Glu_MAbsDispError_2 <- lmer(data=beh_GluPCA_MAbsDispError, meanAbsDispErr ~ dim1 * invage + Delay + (1|LunaID))
summary(Glu_MAbsDispError_2)

# sd Abs Disp Error

beh_GluPCA_sdAbsDispError <- beh_GluPCA %>%
  mutate(zscore=scale(sdAbsDispErr, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(beh_GluPCA_sdAbsDispError) + aes(y=sdAbsDispErr, x=dim1, color=age) +
  geom_point() + geom_smooth(method="loess") + 
  theme_classic(base_size = 13) +xlab("Glu Component") + ylab("sd Abs Disp Error") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("Glu Component ~ sd Abs Disp Error") +
  scale_color_gradient(low="blue", high = "red")

Glu_sdAbsDispError_1 <- lmer(data=beh_GluPCA_sdAbsDispError, sdAbsDispErr ~ dim1+ Delay + invage + (1|LunaID))
summary(Glu_sdAbsDispError_1)
Glu_sdAbsDispError_2 <- lmer(data=beh_GluPCA_sdAbsDispError, sdAbsDispErr ~ dim1 * invage + Delay + (1|LunaID))
summary(Glu_sdAbsDispError_2)

# Mean VGS Latency

beh_GluPCA_VGSLatency <- beh_GluPCA %>%
  mutate(zscore=scale(meanVGSLatency, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(beh_GluPCA_VGSLatency) + aes(y=meanVGSLatency, x=dim1, color=age) +
  geom_point() + geom_smooth(method="loess") + 
  theme_classic(base_size = 13) +xlab("Glu Component") + ylab("mean VGS Latency") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("Glu Component ~ VGS Latency") +
  scale_color_gradient(low="blue", high="red")

Glu_meanLatency_1 <- lmer(data=beh_GluPCA_VGSLatency, meanVGSLatency ~ dim1+ Delay + invage + (1|LunaID))
summary(Glu_meanLatency_1)
Glu_meanLatency_2 <- lmer(data=beh_GluPCA_VGSLatency, meanVGSLatency ~ dim1 * invage + Delay + (1|LunaID))
summary(Glu_meanLatency_2)

#### GABA PCA Component and MGS Behavior ####
GABA_wide_PCA_age <- GABA_wide_PCA_age %>% separate(ld8, into=c("LunaID", "ScanDate"), sep="_")
beh_GABAPCA <- merge(subjData, GABA_wide_PCA_age, by="LunaID")
beh_GABAPCA$invage <- 1/beh_GABAPCA$age

# Mean MGS Latency

beh_GABAPCA_Latency <- beh_GABAPCA %>%
  mutate(zscore=scale(meanMGSLatency, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(beh_GABAPCA_Latency) + aes(y=meanMGSLatency, x=dim1, color=age) +
  geom_point() + geom_smooth(method="loess") + 
  theme_classic(base_size = 13) +xlab("GABA Component") + ylab("mean MGS Latency") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("GABA Component ~ Latency") +
  scale_color_gradient(low="blue", high="red")

GABA_meanLatency_1 <- lmer(data=beh_GABAPCA_Latency, meanMGSLatency ~ dim1+ Delay + invage + (1|LunaID))
summary(GABA_meanLatency_1)
GABA_meanLatency_2 <- lmer(data=beh_GABAPCA_Latency, meanMGSLatency ~ dim1 * invage + Delay + (1|LunaID))
summary(GABA_meanLatency_2)

# sd MGS Latency

beh_GABAPCA_sdLatency <- beh_GABAPCA %>%
  mutate(zscore=scale(sdMGSLatency, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(beh_GABAPCA_sdLatency) + aes(y=sdMGSLatency, x=dim1, color=age) +
  geom_point() + geom_smooth(method="loess") + 
  theme_classic(base_size = 13) +xlab("GABA Component") + ylab("sd MGS Latency") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("GABA Component ~ sd Latency") +
  scale_color_gradient(low="blue", high="red")

GABA_sdLatency_1 <- lmer(data=beh_GABAPCA_sdLatency, sdMGSLatency ~ dim1+ Delay + invage + (1|LunaID))
summary(GABA_sdLatency_1)
GABA_sdLatency_2 <- lmer(data=beh_GABAPCA_sdLatency, sdMGSLatency ~ dim1 * invage + Delay + (1|LunaID))
summary(GABA_sdLatency_2)

# mean Abs Pos Error

beh_GABAPCA_MAbsPosError <- beh_GABAPCA %>%
  mutate(zscore=scale(meanAbsPosErr, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(beh_GABAPCA_MAbsPosError) + aes(y=meanAbsPosErr, x=dim1, color=age) +
  geom_point() + geom_smooth(method="loess") + 
  theme_classic(base_size = 13) +xlab("GABA Component") + ylab("mean Abs Pos Error") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("GABA Component ~ mean Abs Pos Error") +
  scale_color_gradient(low="blue", high="red")

GABA_MAbsPosError_1 <- lmer(data=beh_GABAPCA_MAbsPosError, meanAbsPosErr ~ dim1+ Delay + invage + (1|LunaID))
summary(GABA_MAbsPosError_1)
GABA_MAbsPosError_2 <- lmer(data=beh_GABAPCA_MAbsPosError, meanAbsPosErr ~ dim1 * invage + Delay + (1|LunaID))
summary(GABA_MAbsPosError_2)

# sd Abs Pos Error

beh_GABAPCA_sdAbsPosError <- beh_GABAPCA %>%
  mutate(zscore=scale(sdAbsPosErr, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(beh_GABAPCA_sdAbsPosError) + aes(y=sdAbsPosErr, x=dim1, color=age) +
  geom_point() + geom_smooth(method="loess") + 
  theme_classic(base_size = 13) +xlab("GABA Component") + ylab("sd Abs Pos Error") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("GABA Component ~ sd Abs Pos Error") +
  scale_color_gradient(low="blue", high="red")

GABA_sdAbsPosError_1 <- lmer(data=beh_GABAPCA_sdAbsPosError, sdAbsPosErr ~ dim1+ Delay + invage + (1|LunaID))
summary(GABA_sdAbsPosError_1)
GABA_sdAbsPosError_2 <- lmer(data=beh_GABAPCA_sdAbsPosError, sdAbsPosErr ~ dim1 * invage + Delay + (1|LunaID))
summary(GABA_sdAbsPosError_2)

# mean abs best error
beh_GABAPCA_MAbsBestError <- beh_GABAPCA %>%
  mutate(zscore=scale(meanAbsBestErr, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(beh_GABAPCA_MAbsBestError) + aes(y=meanAbsBestErr, x=dim1, color=age) +
  geom_point() + geom_smooth(method="loess") + 
  theme_classic(base_size = 13) +xlab("GABA Component") + ylab("mean Abs Best Error") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("GABA Component ~ mean Abs Best Error") +
  scale_color_gradient(low="blue", high="red")

GABA_MAbsBestError_1 <- lmer(data=beh_GABAPCA_MAbsBestError, meanAbsBestErr ~ dim1+ Delay + invage + (1|LunaID))
summary(GABA_MAbsBestError_1)
GABA_MAbsBestError_2 <- lmer(data=beh_GABAPCA_MAbsBestError, meanAbsBestErr ~ dim1 * invage + Delay + (1|LunaID))
summary(GABA_MAbsBestError_2)

# sd Abs Best Error

beh_GABAPCA_sdAbsBestError <- beh_GABAPCA %>%
  mutate(zscore=scale(sdAbsBestErr, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(beh_GABAPCA_sdAbsBestError) + aes(y=sdAbsBestErr, x=dim1, color=age) +
  geom_point() + geom_smooth(method="loess") + 
  theme_classic(base_size = 13) +xlab("GABA Component") + ylab("sd Abs Best Error") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("GABA Component ~ sd Abs Best Error") +
  scale_color_gradient(low="blue", high = "red")

GABA_sdAbsBestError_1 <- lmer(data=beh_GABAPCA_sdAbsBestError, sdAbsBestErr ~ dim1+ Delay + invage + (1|LunaID))
summary(GABA_sdAbsBestError_1)
GABA_sdAbsBestError_2 <- lmer(data=beh_GABAPCA_sdAbsBestError, sdAbsBestErr ~ dim1 * invage + Delay + (1|LunaID))
summary(GABA_sdAbsBestError_2)

# mean abs disp error
beh_GABAPCA_MAbsDispError <- beh_GABAPCA %>%
  mutate(zscore=scale(meanAbsDispErr, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(beh_GABAPCA_MAbsDispError) + aes(y=meanAbsDispErr, x=dim1, color=age) +
  geom_point() + geom_smooth(method="loess") + 
  theme_classic(base_size = 13) +xlab("GABA Component") + ylab("mean Abs Disp Error") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("GABA Component ~ mean Abs Disp Error") +
  scale_color_gradient(low="blue", high="red")

GABA_MAbsDispError_1 <- lmer(data=beh_GABAPCA_MAbsDispError, meanAbsDispErr ~ dim1+ Delay + invage + (1|LunaID))
summary(GABA_MAbsDispError_1)
GABA_MAbsDispError_2 <- lmer(data=beh_GABAPCA_MAbsDispError, meanAbsDispErr ~ dim1 * invage + Delay + (1|LunaID))
summary(GABA_MAbsDispError_2)

# sd Abs Disp Error

beh_GABAPCA_sdAbsDispError <- beh_GABAPCA %>%
  mutate(zscore=scale(sdAbsDispErr, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(beh_GABAPCA_sdAbsDispError) + aes(y=sdAbsDispErr, x=dim1, color=age) +
  geom_point() + geom_smooth(method="loess") + 
  theme_classic(base_size = 13) +xlab("GABA Component") + ylab("sd Abs Disp Error") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("GABA Component ~ sd Abs Disp Error") +
  scale_color_gradient(low="blue", high = "red")

GABA_sdAbsDispError_1 <- lmer(data=beh_GABAPCA_sdAbsDispError, sdAbsDispErr ~ dim1+ Delay + invage + (1|LunaID))
summary(GABA_sdAbsDispError_1)
GABA_sdAbsDispError_2 <- lmer(data=beh_GABAPCA_sdAbsDispError, sdAbsDispErr ~ dim1 * invage + Delay + (1|LunaID))
summary(GABA_sdAbsDispError_2)

# Mean VGS Latency

beh_GABAPCA_VGSLatency <- beh_GABAPCA %>%
  mutate(zscore=scale(meanVGSLatency, center=T, scale=T)) %>%
  filter(abs(zscore) <= z_thres)

ggplot(beh_GABAPCA_VGSLatency) + aes(y=meanVGSLatency, x=dim1, color=age) +
  geom_point() + geom_smooth(method="loess") + 
  theme_classic(base_size = 13) +xlab("GABA Component") + ylab("mean VGS Latency") + 
  theme(legend.key = element_rect(fill = "white", colour = "black")) + 
  ggtitle("GABA Component ~ VGS Latency") +
  scale_color_gradient(low="blue", high="red")

GABA_meanLatency_1 <- lmer(data=beh_GABAPCA_VGSLatency, meanVGSLatency ~ dim1+ Delay + invage + (1|LunaID))
summary(GABA_meanLatency_1)
GABA_meanLatency_2 <- lmer(data=beh_GABAPCA_VGSLatency, meanVGSLatency ~ dim1 * invage + Delay + (1|LunaID))
summary(GABA_meanLatency_2)

