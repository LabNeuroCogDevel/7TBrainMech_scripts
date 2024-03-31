# Dissertation 7/24/23 M.I.P. ---- 

# 1.0 Load libraries ----
library(LNCDR)
library(tidyverse)
library(ggplot2)
library(lme4)
library(lmerTest)
library(corrplot)
library(ppcor)
select <- dplyr::select # force select to be the one you want (not from MASS)
library(interactions)
library(psych)
library(ggeffects)


# 2.0 Load data ----
# load in merge 7t 
merge7t <- read.csv('/Volumes/Hera/Projects/7TBrainMech/scripts/txt/merged_7t.csv')

# make smaller dataframe with only variables i need
merge7t <- merge7t %>%
  dplyr::select(lunaid, visitno, rest.age, sess.age, sex, rest.fd, 
         matches('sipfc.*_(Glu|GABA)_gamadj'),
         matches('sipfc.*_all_GMrat'), 
         matches('rest.hurst.*'),
         matches('ADI_*'))

# create age variables 
merge7t$invage <- 1/merge7t$sess.age
merge7t$quadage <- (merge7t$sess.age - mean(merge7t$sess.age, na.rm=T))^2

# remove bad value (checked lcmodel spectrum to confirm unreliable estimate)
is.na(merge7t$sipfc.MPFC_GABA_gamadj) <- with(merge7t, sipfc.MPFC_GABA_gamadj < 0.2)

# create glu/gaba ratio variables 
merge7t$sipfc.ACC_GluGABARat <- merge7t$sipfc.ACC_Glu_gamadj/merge7t$sipfc.ACC_GABA_gamadj
merge7t$sipfc.MPFC_GluGABARat <- merge7t$sipfc.MPFC_Glu_gamadj/merge7t$sipfc.MPFC_GABA_gamadj
merge7t$sipfc.RDLPFC_GluGABARat <- merge7t$sipfc.RDLPFC_Glu_gamadj/merge7t$sipfc.RDLPFC_GABA_gamadj
merge7t$sipfc.LDLPFC_GluGABARat <- merge7t$sipfc.LDLPFC_Glu_gamadj/merge7t$sipfc.LDLPFC_GABA_gamadj


#abs_scale <- function(x) abs(scale(x,center=T,scale=T))
#na_above <- function(z, x=z, thres=3) ifelse(z>thres,NA,x)
#na_z <- function(x) na_above(abs_scale(x), x)

#merge7t<- merge7t %>% mutate(across(matches("GluGABARat"), na_z))

# make lunaid a factor 
merge7t$lunaid <- as.factor(merge7t$lunaid)
merge7t$sex<- as.factor(merge7t$sex)
merge7t$ADI_NATRANK<- as.numeric(merge7t$ADI_NATRANK)

# create glu/gaba mismatch variable 
merge7t$sipfc.ACC_GluGABAMismatch<- abs(residuals(lm(data=merge7t, sipfc.ACC_Glu_gamadj ~ sipfc.ACC_GABA_gamadj, na.action=na.exclude)))
merge7t$sipfc.MPFC_GluGABAMismatch<- abs(residuals(lm(data=merge7t, sipfc.MPFC_Glu_gamadj ~ sipfc.MPFC_GABA_gamadj, na.action=na.exclude)))
merge7t$sipfc.RDLPFC_GluGABAMismatch<- abs(residuals(lm(data=merge7t, sipfc.RDLPFC_Glu_gamadj ~ sipfc.RDLPFC_GABA_gamadj, na.action=na.exclude)))
merge7t$sipfc.LDLPFC_GluGABAMismatch<- abs(residuals(lm(data=merge7t, sipfc.LDLPFC_Glu_gamadj ~ sipfc.LDLPFC_GABA_gamadj, na.action=na.exclude)))

# remove psych diagnosis people
merge7t <- merge7t %>% 
  filter(!lunaid %in% c("11646", "11659", "11800", "11653", "11690", "11812"))


# need to update this when new ADI data comes in and then also add antisaccade derived measures/error corrected trials
merge7t_cor <- merge7t %>%
  dplyr::select(invage, sipfc.RDLPFC_GABA_gamadj, sipfc.LDLPFC_GABA_gamadj, sipfc.RDLPFC_Glu_gamadj,
                sipfc.LDLPFC_Glu_gamadj, sipfc.ACC_GABA_gamadj, sipfc.ACC_Glu_gamadj,
                sipfc.MPFC_GABA_gamadj, sipfc.MPFC_Glu_gamadj, hurst_brns.ACC, hurst_brns.MPFC,
                hurst_brns.RDLPFC, hurst_brns.LDLPFC, matches('sipfc.*_GluGABARat'),
                matches('sipfc.*_GluGABAMismatch'), ADI_NATRANK, eeg.mgsLatency_DelayAll, eeg.mgsLatency_sd_DelayAll, eeg.BestError_DelayAll, eeg.BestError_sd_DelayAll)

merge7t_cor <- merge7t_cor %>% rename(Inverse_Age = invage, RDLPFC_GABA = sipfc.RDLPFC_GABA_gamadj, LDLPFC_GABA = sipfc.LDLPFC_GABA_gamadj, RDLPFC_Glu = sipfc.RDLPFC_Glu_gamadj, LDLPFC_Glu = sipfc.LDLPFC_Glu_gamadj, 
                                      ACC_GABA = sipfc.ACC_GABA_gamadj, ACC_Glu = sipfc.ACC_Glu_gamadj, mPFC_GABA = sipfc.MPFC_GABA_gamadj, mPFC_Glu = sipfc.MPFC_Glu_gamadj, ACC_hurst = hurst_brns.ACC, mPFC_hurst = hurst_brns.MPFC, RDLPFC_hurst = hurst_brns.RDLPFC,
                                      LDLPFC_hurst = hurst_brns.LDLPFC, LDLPFC_GluGABARatio = sipfc.LDLPFC_GluGABARat, RDLPFC_GluGABARatio = sipfc.RDLPFC_GluGABARat, ACC_GluGABARatio = sipfc.ACC_GluGABARat, mPFC_GluGABARatio = sipfc.MPFC_GluGABARat,
                                      LDPFC_GluGABAMismatch = sipfc.LDLPFC_GluGABAMismatch, RDLPFC_GluGABAMismatch = sipfc.RDLPFC_GluGABAMismatch, ACC_GluGABAMismatch = sipfc.ACC_GluGABAMismatch, mPFC_GluGABAMismatch = sipfc.MPFC_GluGABAMismatch, 
                                      ADI = ADI_NATRANK, MGS_Latency = eeg.mgsLatency_DelayAll, MGS_LatencySD = eeg.mgsLatency_sd_DelayAll, MGS_Accuracy = eeg.BestError_DelayAll, MGS_AccuracySD = eeg.BestError_sd_DelayAll)

cormat <- cor(merge7t_cor, use = "pairwise.complete.obs")
testRes <- cor.mtest(merge7t_cor, conf.level = 0.95)
corrplot(cormat, p.mat = testRes$p, sig.level = 0.05,  method = "color",
         insig = "label_sig", pch.col = "white")
corrplot(cormat,  method = "number")
# 3.0 Aim 1: Characterize normative E/I development ----

## 3.1 MRSI: Glu/GABA Ratio ----
glugaba <- c("#B887ADFF", "#635595FF", "#7D4F73FF", "#80CDC1FF", "#35978FFF", "#796D9DFF", "#088BBEFF", "#1BB6AFFF", "#B25D91FF", "#216F63FF")

# DLPFC both hemispheres
dlpfc<- merge7t %>% select(lunaid, visitno, sess.age, sex, sipfc.LDLPFC_all_GMrat, sipfc.RDLPFC_all_GMrat, matches('sipfc.RDLPFC_(Glu|GABA)_gamadj'), matches('sipfc.LDLPFC_(Glu|GABA)_gamadj'))
dlpfc_long <- dlpfc %>%
  pivot_longer(matches('sipfc')) %>% 
  separate(name,c('src','roi','met','measure')) %>% 
  pivot_wider(names_from=c('measure','met'),values_from='value')
dlpfc_long$GGRat<- dlpfc_long$gamadj_Glu/dlpfc_long$gamadj_GABA

#dlpfc_long<- dlpfc_long %>% mutate(across(matches("GGRat"), na_z))
dlpfc_long$invage <- 1/dlpfc_long$sess.age
dlpfc_long$quadage <- (dlpfc_long$sess.age - mean(dlpfc_long$sess.age, na.rm=T))^2

dlpfc_ggrat_lin <- lmer(data=dlpfc_long, GGRat~ sess.age + sex + roi + (1|lunaid))
summary(dlpfc_ggrat_lin)
ggplot(data=dlpfc_long) + aes(x=sess.age, y=GGRat, group=lunaid, roi, color = roi) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("DLPFC Glu/GABA Ratio") +
  geom_line(aes(group=paste(lunaid, roi))) 

dlpfc_ggrat_inv <- lmer(data=dlpfc_long, GGRat~ invage + sex  + roi + (1|lunaid))
summary(dlpfc_ggrat_inv)
ggplot(data=dlpfc_long) + aes(x=sess.age, y=GGRat, group=lunaid, roi, color = roi) + geom_point() + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL, fill=roi), alpha=0.2) +theme_classic(base_size=25) + xlab("Age") + ylab("Glu/GABA Ratio") +
  geom_line(aes(group=paste(lunaid, roi)), alpha=0.2) +
  theme(legend.title = element_blank(),
        legend.position = c(.85, .9)) + scale_color_manual(values = glugaba) + scale_fill_manual(values=glugaba)

ggsave("dlpfc_ggrat_age.tiff", width = 20, height = 20, units = "cm", dpi = 300)

dlpfc_ggrat_inv <- lmer(data=dlpfc_long, GGRat~ invage * roi + sex  + (1|lunaid))
summary(dlpfc_ggrat_inv)

# scaled model to find standardized effect sizes 
dlpfc_ggrat_inv<- lmer(data=dlpfc_long, scale(GGRat, center = T, scale = T)~ scale(invage, center=T, scale = T) + sex + roi + (1|lunaid))
summary(dlpfc_ggrat_inv)

dlpfc_ggrat_quad <- lmer(data=dlpfc_long, GGRat~ sess.age + quadage + sex  + roi + (1|lunaid))
summary(dlpfc_ggrat_quad)

AIC(dlpfc_ggrat_lin , dlpfc_ggrat_inv, dlpfc_ggrat_quad)

# right dlpfc - roi 9
rdlpfc_ggrat_lin <- lmer(data=merge7t, sipfc.RDLPFC_GluGABARat~ sess.age + sex + sipfc.RDLPFC_all_GMrat + (1|lunaid))
summary(rdlpfc_ggrat_lin)
ggplot(data=merge7t) + aes(x=sess.age, y=sipfc.RDLPFC_GluGABARat, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("RDLPFC Glu/GABA Ratio") +
  geom_line() 

rdlpfc_ggrat_inv<- lmer(data=merge7t, sipfc.RDLPFC_GluGABARat~ invage + sex + sipfc.RDLPFC_all_GMrat + (1|lunaid))
summary(rdlpfc_ggrat_inv)
ggplot(data=merge7t) + aes(x=sess.age, y=sipfc.RDLPFC_GluGABARat, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("RDLPFC Glu/GABA Ratio") +
  geom_line() 

rdlpfc_ggrat_quad <- lmer(data=merge7t, sipfc.RDLPFC_GluGABARat~ sess.age + quadage + sex + sipfc.RDLPFC_all_GMrat + (1|lunaid))
summary(rdlpfc_ggrat_quad)

AIC(rdlpfc_ggrat_lin , rdlpfc_ggrat_inv, rdlpfc_ggrat_quad)

# left dlpfc - roi 10
ldlpfc_ggrat_lin <- lmer(data=merge7t, sipfc.LDLPFC_GluGABARat~ sess.age + sex + sipfc.LDLPFC_all_GMrat + (1|lunaid))
summary(ldlpfc_ggrat_lin)
ggplot(data=merge7t) + aes(x=sess.age, y=sipfc.LDLPFC_GluGABARat, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("LDLPFC Glu/GABA Ratio") +
  geom_line() 

ldlpfc_ggrat_inv<- lmer(data=merge7t, sipfc.LDLPFC_GluGABARat~ invage + sex + sipfc.LDLPFC_all_GMrat + (1|lunaid))
summary(ldlpfc_ggrat_inv)
ggplot(data=merge7t) + aes(x=sess.age, y=sipfc.LDLPFC_GluGABARat, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("LDLPFC Glu/GABA Ratio") +
  geom_line() 

ldlpfc_ggrat_quad <- lmer(data=merge7t, sipfc.LDLPFC_GluGABARat~ sess.age + quadage + sex + sipfc.LDLPFC_all_GMrat + (1|lunaid))
summary(ldlpfc_ggrat_quad)

AIC(ldlpfc_ggrat_lin , ldlpfc_ggrat_inv, ldlpfc_ggrat_quad)


# ACC
acc_ggrat_lin <- lmer(data=merge7t, sipfc.ACC_GluGABARat~ sess.age + sex + (1|lunaid))
summary(acc_ggrat_lin)
ggplot(data=merge7t) + aes(x=sess.age, y=sipfc.ACC_GluGABARat, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("ACC Glu/GABA Ratio") +
  geom_line() 

acc_ggrat_inv<- lmer(data=merge7t, sipfc.ACC_GluGABARat~ invage + sex + (1|lunaid))
summary(acc_ggrat_inv)
ggplot(data=merge7t) + aes(x=sess.age, y=sipfc.ACC_GluGABARat, group=lunaid) + geom_point(color=glugaba[1]) + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL), alpha=0.2, color=glugaba[1]) +theme_classic(base_size=25) + xlab("Age") + ylab("Glu/GABA Ratio") +
  geom_line(alpha=0.2) + scale_color_manual(values = glugaba) + scale_fill_manual(values=glugaba)

ggsave("acc_ggrat_age.tiff", width = 20, height = 20, units = "cm", dpi = 300)


acc_ggrat_quad <- lmer(data=merge7t, sipfc.ACC_GluGABARat~ sess.age + quadage + sex + (1|lunaid))
summary(acc_ggrat_quad)

AIC(acc_ggrat_lin , acc_ggrat_inv, acc_ggrat_quad)

# scaled model to find standardized effect sizes 
acc_ggrat_inv<- lmer(data=merge7t, scale(sipfc.ACC_GluGABARat, center = T, scale = T)~ scale(invage, center=T, scale = T) + sex + (1|lunaid))
summary(acc_ggrat_inv)

# age by sex interaction
acc_ggrat_inv<- lmer(data=merge7t, sipfc.ACC_GluGABARat~ invage * sex + (1|lunaid))
summary(acc_ggrat_inv)
ggplot(data=merge7t) + aes(x=sess.age, y=sipfc.ACC_GluGABARat, group=lunaid, color = sex) + geom_point() + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("ACC Glu/GABA Ratio") +
  geom_line() 

# MPFC
mpfc_ggrat_lin <- lmer(data=merge7t, sipfc.MPFC_GluGABARat~ sess.age + sex + (1|lunaid))
summary(mpfc_ggrat_lin)
ggplot(data=merge7t) + aes(x=sess.age, y=sipfc.MPFC_GluGABARat, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("MPFC Glu/GABA Ratio") +
  geom_line() 

mpfc_ggrat_inv<- lmer(data=merge7t, sipfc.MPFC_GluGABARat~ invage + sex +  (1|lunaid))
summary(mpfc_ggrat_inv)
ggplot(data=merge7t) + aes(x=sess.age, y=sipfc.MPFC_GluGABARat, group=lunaid) + geom_point(color=glugaba[1]) + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL), alpha=0.2, color=glugaba[1]) +theme_classic(base_size=25) + xlab("Age") + ylab("Glu/GABA Ratio") +
  geom_line(alpha=0.2) + scale_color_manual(values = glugaba) + scale_fill_manual(values=glugaba)
  geom_line() 


ggsave("mpfc_ggrat_age.tiff", width = 20, height = 20, units = "cm", dpi = 300)


mpfc_ggrat_inv<- lmer(data=merge7t, sipfc.MPFC_GluGABARat~ invage * sex +  (1|lunaid))
summary(mpfc_ggrat_inv)

mpfc_ggrat_quad <- lmer(data=merge7t, sipfc.MPFC_GluGABARat~ sess.age + quadage + sex +  (1|lunaid))
summary(mpfc_ggrat_quad)

AIC(mpfc_ggrat_lin, mpfc_ggrat_inv, mpfc_ggrat_quad)

# scaled model to find standardized effect sizes 
mpfc_ggrat_inv<- lmer(data=merge7t, scale(sipfc.MPFC_GluGABARat, center = T, scale = T)~ scale(invage, center=T, scale = T) + sex + (1|lunaid))
summary(mpfc_ggrat_inv)

# bonferroni correct p vals 
p_ratio <- c(0.11, 0.0011, 0.0000000695)
p.adjust(p_ratio, "bonferroni", n = length(p_ratio))

## 3.2 MRSI: Glu/GABA Mismatch ----
#merge7t$sipfc.RDLPFC_GluGABAMismatch<- abs(residuals(lm(data=merge7t, sipfc.RDLPFC_Glu_gamadj ~ sipfc.RDLPFC_GABA_gamadj, na.action=na.exclude)))

dlpfc_long$mismatch<- abs(residuals(lm(data= dlpfc_long, gamadj_Glu~gamadj_GABA, na.action = na.exclude)))

# dlpfc
dlpfc_mismatch_lin <- lmer(data=dlpfc_long, mismatch~ sess.age + sex  + roi + (1|lunaid))
summary(dlpfc_mismatch_lin)
ggplot(data=dlpfc_long) + aes(x=sess.age, y=mismatch, group=lunaid, roi, color = roi) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("DLPFC Glu/GABA Mismatch") +
  geom_line(aes(group=paste(lunaid, roi))) 

dlpfc_mismatch_inv <- lmer(data=dlpfc_long, mismatch~ invage + sex  + roi + (1|lunaid))
summary(dlpfc_mismatch_inv)
ggplot(data=dlpfc_long) + aes(x=sess.age, y=mismatch, group=lunaid, roi, color = roi) + geom_point() + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL, fill=roi), alpha=0.2) +theme_classic(base_size=25) + xlab("Age") + ylab("Glu/GABA Mismatch") +
  geom_line(aes(group=paste(lunaid, roi)), alpha=0.2) +
  theme(legend.title = element_blank(),
        legend.position = c(.85, .9)) + scale_color_manual(values = glugaba) + scale_fill_manual(values=glugaba)

ggsave("dlpfc_ggmis_age.tiff", width = 20, height = 20, units = "cm", dpi = 300)


dlpfc_mismatch_inv <- lmer(data=dlpfc_long, mismatch~ invage * roi + sex  + (1|lunaid))
summary(dlpfc_mismatch_inv)

# scaled model to find standardized effect sizes 
dlpfc_mismatch_inv<- lmer(data=dlpfc_long, scale(mismatch, center = T, scale = T)~ scale(invage, center=T, scale = T) * roi + sex + (1|lunaid))
summary(dlpfc_mismatch_inv)

dlpfc_mismatch_quad <- lmer(data=dlpfc_long, mismatch~ sess.age + quadage + sex  + roi + (1|lunaid))
summary(dlpfc_mismatch_quad)

AIC(dlpfc_mismatch_lin , dlpfc_mismatch_inv, dlpfc_mismatch_quad)


rdlpfc_mismatch_inv <- lmer(data=merge7t, scale(sipfc.RDLPFC_GluGABAMismatch, center = T, scale = T) ~ scale(invage, center = T, scale = T) + sex +(1|lunaid))
summary(rdlpfc_mismatch_inv)

ldlpfc_mismatch_inv <- lmer(data=merge7t, scale(sipfc.LDLPFC_GluGABAMismatch, center = T, scale = T) ~ scale(invage, center = T, scale = T) + sex +  (1|lunaid))
summary(ldlpfc_mismatch_inv)

# ACC
acc_mismatch_lin <- lmer(data=merge7t, sipfc.ACC_GluGABAMismatch~ sess.age + sex  + (1|lunaid))
summary(acc_mismatch_lin)
ggplot(data=merge7t) + aes(x=sess.age, y=sipfc.ACC_GluGABAMismatch, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("ACC Glu/GABA Mismatch") +
  geom_line() 

acc_mismatch_inv<- lmer(data=merge7t, sipfc.ACC_GluGABAMismatch~ invage + sex  + (1|lunaid))
summary(acc_mismatch_inv)
ggplot(data=merge7t) + aes(x=sess.age, y=sipfc.ACC_GluGABAMismatch, group=lunaid) + geom_point(color=glugaba[1]) + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL), color=glugaba[1], alpha=0.2) +theme_classic(base_size=25) + xlab("Age") + ylab("ACC Glu/GABA Mismatch") +
  geom_line(alpha=0.2) + scale_color_manual(values = glugaba) + scale_fill_manual(values=glugaba)

ggsave("acc_ggmis_age.tiff", width = 20, height = 20, units = "cm", dpi = 300)

# scaled model to find standardized effect sizes 
acc_mismatch_inv<- lmer(data=merge7t, scale(sipfc.ACC_GluGABAMismatch, center = T, scale = T)~ scale(invage, center=T, scale = T) + sex  + (1|lunaid))
summary(acc_mismatch_inv)

acc_mismatch_quad <- lmer(data=merge7t, sipfc.ACC_GluGABAMismatch~ sess.age + quadage + sex + (1|lunaid))
summary(acc_mismatch_quad)

AIC(acc_mismatch_lin , acc_mismatch_inv, acc_mismatch_quad)

# MPFC
mpfc_mismatch_lin <- lmer(data=merge7t, sipfc.MPFC_GluGABAMismatch~ sess.age + sex  + (1|lunaid))
summary(mpfc_mismatch_lin)
ggplot(data=merge7t) + aes(x=sess.age, y=sipfc.MPFC_GluGABAMismatch, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("MPFC Glu/GABA Mismatch") +
  geom_line() 

mpfc_mismatch_inv<- lmer(data=merge7t, sipfc.MPFC_GluGABAMismatch~ invage + sex  + (1|lunaid))
summary(mpfc_mismatch_inv)
ggplot(data=merge7t) + aes(x=sess.age, y=sipfc.MPFC_GluGABAMismatch, group=lunaid) + geom_point(color=glugaba[1]) + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL), color=glugaba[1], alpha=0.2) +theme_classic(base_size=25) + xlab("Age") + ylab("Glu/GABA Mismatch") +
  geom_line(alpha=0.2) + scale_color_manual(values = glugaba) + scale_fill_manual(values=glugaba)

ggsave("mpfc_ggmis_age.tiff", width = 20, height = 20, units = "cm", dpi = 300)

# scaled model to find standardized effect sizes 
mpfc_mismatch_inv<- lmer(data=merge7t, scale(sipfc.MPFC_GluGABAMismatch, center = T, scale = T)~ scale(invage, center=T, scale = T) + sex  + (1|lunaid))
summary(mpfc_mismatch_inv)

mpfc_mismatch_quad <- lmer(data=merge7t, sipfc.MPFC_GluGABAMismatch~ sess.age + quadage + sex  + (1|lunaid))
summary(mpfc_mismatch_quad)

AIC(mpfc_mismatch_lin , mpfc_mismatch_inv, mpfc_mismatch_quad)


## 3.3 Hurst ----

# DLPFC
# DLPFC both hemispheres
dlpfc_hurst<- merge7t %>% dplyr::select(lunaid, visitno, sess.age, sex, rest.hurst.RDLPFC , rest.hurst.LDLPFC, rest.fd)

dlpfc_long <- dlpfc_hurst %>%
  pivot_longer(cols = matches("rest\\.hurst\\.*"), names_to = "name", values_to = "value") %>%
  separate(name, into = c("scan", "parameter", "roi"), sep = "\\.")

dlpfc_long$invage <- 1/dlpfc_long$sess.age
dlpfc_long$quadage <- (dlpfc_long$sess.age - mean(dlpfc_long$sess.age, na.rm=T))^2

dlpfc_hurst_age <- lmer(data=dlpfc_long , value ~ sess.age + sex + rest.fd + roi + (1|lunaid))
summary(dlpfc_hurst_age)
ggplot(data=dlpfc_long ) + aes(x=sess.age, y=value, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("DLPFC Hurst") +
  geom_line(aes(group=paste(lunaid, roi)))

dlpfc_hurst_age <- lmer(data=dlpfc_long  %>% filter(rest.fd < 1), value ~ sess.age + sex + rest.fd + roi+ (1|lunaid))
summary(dlpfc_hurst_age)
ggplot(data=dlpfc_long  %>% filter(rest.fd < 1)) + aes(x=sess.age, y=value, group=lunaid, color=roi) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("DLPFC Hurst  fd < 1") +
  geom_line(aes(group=paste(lunaid, roi)))

dlpfc_hurst_invage <- lmer(data=dlpfc_long  %>% filter(rest.fd < 1), value ~ invage + roi + sex + rest.fd + (1|lunaid))
summary(dlpfc_hurst_invage)
ggplot(data=dlpfc_long  %>% filter(rest.fd < 1)) + aes(x=sess.age, y=value, group=lunaid, color = roi) + geom_point() + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("Hurst") +
  geom_line(aes(group=paste(lunaid, roi))) + theme(legend.position='none')
ggsave("DLPFC_Hurst_age.tiff", height=6, width=6, dpi=300)

dlpfc_hurst_quad <- lmer(data=dlpfc_long  %>% filter(rest.fd < 1), value ~ sess.age + quadage + sex + roi+ rest.fd + (1|lunaid))
summary(dlpfc_hurst_quad)

AIC(dlpfc_hurst_age , dlpfc_hurst_invage, dlpfc_hurst_quad)

dlpfc_hurst_invage <- lmer(data=dlpfc_long  %>% filter(rest.fd < 1), scale(value, center=T, scale=T) ~ scale(invage, center=T, scale=T) + sex + scale(rest.fd, center=T, scale=T) + roi + (1|lunaid))
summary(dlpfc_hurst_invage)

#right dlpfc 
rdlpfc_hurst_age <- lmer(data=merge7t, rest.hurst.RDLPFC ~ sess.age + sex + rest.fd + (1|lunaid))
summary(rdlpfc_hurst_age)
ggplot(data=merge7t) + aes(x=sess.age, y=rest.hurst.RDLPFC, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("R DLPFC Hurst BRNS") +
  geom_line() 

rdlpfc_hurst_age <- lmer(data=merge7t %>% filter(rest.fd < 1), rest.hurst.RDLPFC ~ sess.age + sex + rest.fd + (1|lunaid))
summary(rdlpfc_hurst_age)
ggplot(data=merge7t %>% filter(rest.fd < 1)) + aes(x=sess.age, y=rest.hurst.RDLPFC, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("R DLPFC Hurst BRNS fd < 1") +
  geom_line() 

rdlpfc_hurst_invage <- lmer(data=merge7t, rest.hurst.RDLPFC ~ invage + sex + rest.fd + (1|lunaid))
summary(rdlpfc_hurst_invage)

AIC(rdlpfc_hurst_age , rdlpfc_hurst_invage)

# ldlpfc
ldlpfc_hurst_age <- lmer(data=merge7t, rest.hurst.LDLPFC ~ sess.age + sex + rest.fd + (1|lunaid))
summary(ldlpfc_hurst_age)
ggplot(data=merge7t) + aes(x=sess.age, y=rest.hurst.LDLPFC, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("L DLPFC Hurst BRNS") +
  geom_line() 

ldlpfc_hurst_age <- lmer(data=merge7t %>% filter(rest.fd < 1), rest.hurst.LDLPFC ~ sess.age + sex + rest.fd + (1|lunaid))
summary(ldlpfc_hurst_age)
ggplot(data=merge7t %>% filter(rest.fd < 1)) + aes(x=sess.age, y=rest.hurst.LDLPFC, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("L DLPFC Hurst BRNS fd < 1") +
  geom_line() 

ldlpfc_hurst_invage <- lmer(data=merge7t, rest.hurst.LDLPFC ~ invage + sex + rest.fd + (1|lunaid))
summary(ldlpfc_hurst_invage)

AIC(ldlpfc_hurst_age , ldlpfc_hurst_invage)

# ACC
acc_hurst_age <- lmer(data=merge7t, rest.hurst.ACC ~ sess.age + sex + rest.fd + (1|lunaid))
summary(acc_hurst_age)
ggplot(data=merge7t) + aes(x=sess.age, y=rest.hurst.ACC, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("ACC Hurst") +
  geom_line() 

acc_hurst_age <- lmer(data=merge7t %>% filter(rest.fd < 1), rest.hurst.ACC ~ sess.age + sex + rest.fd + (1|lunaid))
summary(acc_hurst_age)
ggplot(data=merge7t %>% filter(rest.fd < 1)) + aes(x=sess.age, y=rest.hurst.ACC, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("ACC Hurst  fd < 1") +
  geom_line() 

acc_hurst_invage <- lmer(data=merge7t %>% filter(rest.fd < 1), rest.hurst.ACC ~ invage + sex + rest.fd + (1|lunaid))
summary(acc_hurst_invage)
ggplot(data=merge7t %>% filter(rest.fd < 1)) + aes(x=sess.age, y=rest.hurst.ACC, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("ACC Hurst  fd < 1") +
  geom_line() 

acc_hurst_quad <- lmer(data=merge7t %>% filter(rest.fd < 1), rest.hurst.ACC ~ sess.age + quadage + sex + rest.fd + (1|lunaid))
summary(acc_hurst_quad)

AIC(acc_hurst_age , acc_hurst_invage, acc_hurst_quad)

acc_hurst_ivage_scaled <- lmer(data=merge7t %>% filter(rest.fd < 1), scale(rest.hurst.ACC, center=T, scale=T) ~ scale(invage, center=T, scale=T) + sex + scale(rest.fd, center=T, scale=T) + (1|lunaid))
summary(acc_hurst_ivage_scaled)

# MPFC
mpfc_hurst_age <- lmer(data=merge7t %>% filter(rest.fd < 1), rest.hurst.MPFC ~ sess.age + sex + rest.fd + (1|lunaid))
summary(mpfc_hurst_age)
ggplot(data=merge7t %>% filter(rest.fd < 1)) + aes(x=sess.age, y=rest.hurst.MPFC, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("L DLPFC Hurst BRNS fd < 1") +
  geom_line() 

mpfc_hurst_invage <- lmer(data=merge7t %>% filter(rest.fd < 1), rest.hurst.MPFC ~ invage + sex + rest.fd + (1|lunaid))
summary(mpfc_hurst_invage)
ggplot(data=merge7t %>% filter(rest.fd < 1)) + aes(x=sess.age, y=rest.hurst.MPFC, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("MPFC Hurst  fd < 1") +
  geom_line() 

mpfc_hurst_quad <- lmer(data=merge7t %>% filter(rest.fd < 1), rest.hurst.MPFC ~ sess.age + quadage + sex + rest.fd + (1|lunaid))
summary(mpfc_hurst_quad)

AIC(mpfc_hurst_age , mpfc_hurst_invage, mpfc_hurst_quad)

mpfc_hurst_invage <- lmer(data=merge7t %>% filter(rest.fd < 1), scale(rest.hurst.MPFC, center=T, scale=T) ~ scale(invage, center=T, scale=T) + sex + scale(rest.fd, center=T, scale=T) + (1|lunaid))
summary(mpfc_hurst_invage)


# bonferroni correct p vals 
p_ratio <- c(0.37, 0.47, 0.0000000000217)
p.adjust(p_ratio, "bonferroni", n = length(p_ratio))

## 3.4 Glu and GABA ----
# ACC
# glu 
acc_glu_lin <- lmer(data=merge7t, sipfc.ACC_Glu_gamadj~ sess.age + sex + (1|lunaid))
summary(acc_glu_lin)
ggplot(data=merge7t) + aes(x=sess.age, y=sipfc.ACC_Glu_gamadj, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("ACC Glu") +
  geom_line() 

acc_glu_inv <- lmer(data=merge7t, sipfc.ACC_Glu_gamadj~ invage + sex + (1|lunaid))
summary(acc_glu_inv)
ggplot(data=merge7t) + aes(x=sess.age, y=sipfc.ACC_Glu_gamadj, group=lunaid) + geom_point(color=glugaba[1]) + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL), color=glugaba[1], alpha=0.2) +theme_classic(base_size=25) + xlab("Age") + ylab("Glutamate") +
  geom_line(alpha=0.2) + scale_color_manual(values = glugaba) + scale_fill_manual(values=glugaba)

ggsave("acc_glu_age.tiff", width = 20, height = 20, units = "cm", dpi = 300)


acc_glu_quad <- lmer(data=merge7t, sipfc.ACC_Glu_gamadj~ sess.age + quadage + sex + (1|lunaid))
summary(acc_glu_quad)

AIC(acc_glu_lin, acc_glu_inv, acc_glu_quad)

# scaled model to find standardized effect sizes 
acc_glu_inv<- lmer(data=merge7t, scale(sipfc.ACC_Glu_gamadj, center = T, scale = T)~ scale(invage, center=T, scale = T) + sex + (1|lunaid))
summary(acc_glu_inv)

# gaba 
acc_gaba_lin <- lmer(data=merge7t, sipfc.ACC_GABA_gamadj~ sess.age + sex + (1|lunaid))
summary(acc_gaba_lin)
ggplot(data=merge7t) + aes(x=sess.age, y=sipfc.ACC_GABA_gamadj, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("ACC GABA") +
  geom_line() 

acc_gaba_inv <- lmer(data=merge7t, sipfc.ACC_GABA_gamadj~ invage + sex  + (1|lunaid))
summary(acc_gaba_inv)
ggplot(data=merge7t) + aes(x=sess.age, y=sipfc.ACC_GABA_gamadj, group=lunaid, color =sex) + geom_point() + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("ACC GABA") +
  geom_line() 

ggplot(data=merge7t) + aes(x=sess.age, y=sipfc.ACC_GABA_gamadj, group=lunaid) + geom_point(color=glugaba[1]) + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL), color=glugaba[1], alpha=0.2) +theme_classic(base_size=25) + xlab("Age") + ylab("GABA") +
  geom_line(alpha=0.2) + scale_color_manual(values = glugaba) + scale_fill_manual(values=glugaba)

ggsave("acc_gaba_age.tiff", width = 20, height = 20, units = "cm", dpi = 300)


acc_gaba_quad <- lmer(data=merge7t, sipfc.ACC_GABA_gamadj~ sess.age + quadage + sex  + (1|lunaid))
summary(acc_gaba_quad)

AIC(acc_gaba_lin, acc_gaba_inv, acc_gaba_quad)

# scaled model to find standardized effect sizes 
acc_gaba_inv<- lmer(data=merge7t, scale(sipfc.ACC_GABA_gamadj, center = T, scale = T)~ scale(invage, center=T, scale = T) + sex  + (1|lunaid))
summary(acc_gaba_inv)

# MPFC
# glu 
mpfc_glu_lin <- lmer(data=merge7t, sipfc.MPFC_Glu_gamadj~ sess.age + sex + (1|lunaid))
summary(mpfc_glu_lin)
ggplot(data=merge7t) + aes(x=sess.age, y=sipfc.MPFC_Glu_gamadj, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("MPFC Glu") +
  geom_line() 

mpfc_glu_inv <- lmer(data=merge7t, sipfc.MPFC_Glu_gamadj~ invage + sex + (1|lunaid))
summary(mpfc_glu_inv)
ggplot(data=merge7t) + aes(x=sess.age, y=sipfc.MPFC_Glu_gamadj, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("MPFC Glu") +
  geom_line() 

ggplot(data=merge7t) + aes(x=sess.age, y=sipfc.MPFC_Glu_gamadj, group=lunaid) + geom_point(color=glugaba[1]) + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL), color=glugaba[1], alpha=0.2) +theme_classic(base_size=25) + xlab("Age") + ylab("Glutamate") +
  geom_line(alpha=0.2) + scale_color_manual(values = glugaba) + scale_fill_manual(values=glugaba)

ggsave("mpfc_glu_age.tiff", width = 20, height = 20, units = "cm", dpi = 300)


mpfc_glu_quad <- lmer(data=merge7t, sipfc.MPFC_Glu_gamadj~ sess.age + quadage + sex  + (1|lunaid))
summary(mpfc_glu_quad)

AIC(mpfc_glu_lin, mpfc_glu_inv, mpfc_glu_quad)

# scaled model to find standardized effect sizes 
MPFC_glu_inv<- lmer(data=merge7t, scale(sipfc.MPFC_Glu_gamadj, center = T, scale = T)~ scale(invage, center=T, scale = T) + sex + (1|lunaid))
summary(MPFC_glu_inv)

# gaba 
mpfc_gaba_lin <- lmer(data=merge7t, sipfc.MPFC_GABA_gamadj~ sess.age + sex + (1|lunaid))
summary(mpfc_gaba_lin)
ggplot(data=merge7t) + aes(x=sess.age, y=sipfc.MPFC_GABA_gamadj, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("MPFC GABA") +
  geom_line() 

mpfc_gaba_inv <- lmer(data=merge7t, sipfc.MPFC_GABA_gamadj~ invage + sex + (1|lunaid))
summary(mpfc_gaba_inv)
ggplot(data=merge7t) + aes(x=sess.age, y=sipfc.MPFC_GABA_gamadj, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("MPFC GABA") +
  geom_line() 

ggplot(data=merge7t) + aes(x=sess.age, y=sipfc.MPFC_GABA_gamadj, group=lunaid) + geom_point(color=glugaba[1]) + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL), color=glugaba[1], alpha=0.2) +theme_classic(base_size=25) + xlab("Age") + ylab("GABA") +
  geom_line(alpha=0.2) + scale_color_manual(values = glugaba) + scale_fill_manual(values=glugaba)

ggsave("mpfc_gaba_age.tiff", width = 20, height = 20, units = "cm", dpi = 300)


mpfc_gaba_quad <- lmer(data=merge7t, sipfc.MPFC_GABA_gamadj~ sess.age + quadage + sex +  (1|lunaid))
summary(mpfc_gaba_quad)

AIC(mpfc_gaba_lin, mpfc_gaba_inv, mpfc_gaba_quad)

# scaled model to find standardized effect sizes 
mpfc_gaba_inv<- lmer(data=merge7t, scale(sipfc.MPFC_GABA_gamadj, center = T, scale = T)~ scale(invage, center=T, scale = T) + sex + (1|lunaid))
summary(mpfc_gaba_inv)

# dlpfc
# gaba
dlpfc_gaba_lin <- lmer(data=dlpfc_long, gamadj_GABA~ sess.age + sex  + roi + (1|lunaid))
summary(dlpfc_gaba_lin)
ggplot(data=dlpfc_long) + aes(x=sess.age, y=gamadj_GABA, group=lunaid, roi, color = roi) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("DLPFC GABA") +
  geom_line(aes(group=paste(lunaid, roi))) 

dlpfc_gaba_inv <- lmer(data=dlpfc_long, gamadj_GABA~ invage + sex  + roi + (1|lunaid))
summary(dlpfc_gaba_inv)
ggplot(data=dlpfc_long) + aes(x=sess.age, y=gamadj_GABA, group=lunaid, roi, color = roi) + geom_point() + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("DLPFC GABA") +
  geom_line(aes(group=paste(lunaid, roi))) 

ggplot(data=dlpfc_long) + aes(x=sess.age, y=gamadj_GABA, group=lunaid, roi, color = roi) + geom_point() + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL, fill=roi), alpha=0.2) +theme_classic(base_size=25) + xlab("Age") + ylab("GABA") +
  geom_line(aes(group=paste(lunaid, roi)), alpha=0.2) +
  theme(legend.title = element_blank(),
        legend.position = c(.85, .9)) + scale_color_manual(values = glugaba) + scale_fill_manual(values=glugaba)

ggsave("dlpfc_gaba_age.tiff", width = 20, height = 20, units = "cm", dpi = 300)


dlpfc_gaba_inv <- lmer(data=dlpfc_long, gamadj_GABA~ invage * roi + sex  + (1|lunaid))
summary(dlpfc_gaba_inv)

dlpfc_gaba_quad <- lmer(data=dlpfc_long, gamadj_GABA~ sess.age + quadage + sex + roi  + (1|lunaid))
summary(dlpfc_gaba_quad)

AIC(dlpfc_gaba_lin, dlpfc_gaba_inv, dlpfc_gaba_quad)

# scaled model to find standardized effect sizes 
dlpfc_gaba_inv<- lmer(data=dlpfc_long, scale(gamadj_GABA, center = T, scale = T)~ scale(invage, center=T, scale = T) + sex + roi+ (1|lunaid))
summary(dlpfc_gaba_inv)

dlpfc_gaba_inv<- lmer(data=dlpfc_long, scale(gamadj_GABA, center = T, scale = T)~ scale(invage, center=T, scale = T) * roi + sex + (1|lunaid))
summary(dlpfc_gaba_inv)

# glu
dlpfc_glu_lin <- lmer(data=dlpfc_long, gamadj_Glu~ sess.age + sex  + roi + (1|lunaid))
summary(dlpfc_glu_lin)
ggplot(data=dlpfc_long) + aes(x=sess.age, y=gamadj_Glu, group=lunaid, roi, color = roi) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("DLPFC Glu") +
  geom_line(aes(group=paste(lunaid, roi))) 

dlpfc_glu_inv <- lmer(data=dlpfc_long, gamadj_Glu~ invage + sex  + roi + (1|lunaid))
summary(dlpfc_glu_inv)
ggplot(data=dlpfc_long) + aes(x=sess.age, y=gamadj_Glu, group=lunaid, roi, color = roi) + geom_point() + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("DLPFC Glu") +
  geom_line(aes(group=paste(lunaid, roi))) 

ggplot(data=dlpfc_long) + aes(x=sess.age, y=gamadj_Glu, group=lunaid, roi, color = roi) + geom_point() + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL, fill=roi), alpha=0.2) +theme_classic(base_size=25) + xlab("Age") + ylab("Glutamate") +
  geom_line(aes(group=paste(lunaid, roi)), alpha=0.2) +
  theme(legend.title = element_blank(),
        legend.position = c(.85, .9)) + scale_color_manual(values = glugaba) + scale_fill_manual(values=glugaba)

ggsave("dlpfc_glu_age.tiff", width = 20, height = 20, units = "cm", dpi = 300)


dlpfc_glu_inv <- lmer(data=dlpfc_long, gamadj_Glu~ invage * roi + sex  + (1|lunaid))
summary(dlpfc_glu_inv)

dlpfc_glu_quad <- lmer(data=dlpfc_long, gamadj_Glu~ sess.age + quadage + sex + roi  + (1|lunaid))
summary(dlpfc_glu_quad)

AIC(dlpfc_glu_lin, dlpfc_glu_inv, dlpfc_glu_quad)

rdlpfc_glu_inv <- lmer(data=merge7t, scale(sipfc.RDLPFC_Glu_gamadj, center = T, scale = T) ~ scale(invage, center = T, scale = T) + sex +(1|lunaid))
summary(rdlpfc_glu_inv)

ldlpfc_glu_inv <- lmer(data=merge7t, scale(sipfc.LDLPFC_Glu_gamadj, center = T, scale = T) ~ scale(invage, center = T, scale = T) + sex +  (1|lunaid))
summary(ldlpfc_glu_inv)

# scaled model to find standardized effect sizes 
dlpfc_glu_inv<- lmer(data=dlpfc_long, scale(gamadj_Glu, center = T, scale = T)~ scale(invage, center=T, scale = T) * sex + roi+ (1|lunaid))
summary(dlpfc_glu_inv)

dlpfc_glu_inv_int<- lmer(data=dlpfc_long, scale(gamadj_Glu, center = T, scale = T)~ scale(invage, center=T, scale = T) * roi + sex+  (1|lunaid))
summary(dlpfc_glu_inv_int)


## 3.5 MRSI and Hurst correlations ----
d <- merge7t %>% select(sess.age, rest.fd, lunaid, matches('sipfc|rest.hurst'))
d <- d %>% select(sess.age, rest.fd, lunaid, matches('DLPFC|MPFC|ACC'))
d <- d %>% select(-contains("GMrat"))
d <- d %>% rename_with(\(x) gsub('(hurst.*)','\\1_hurst',x))

## 3.5.1 simple cor
raw_cormat <- d %>% select(matches('sipfc|hurst')) %>% cor(use='pairwise.complete.obs')
corrplot(raw_cormat)
high_cor_idx <- which(abs(raw_cormat)>.3 & raw_cormat!=1, arr.ind=T)
high_cor <- tibble(
                  x=colnames(raw_cormat)[high_cor_idx[,1]],
                  y=rownames(raw_cormat)[high_cor_idx[,2]],
                  v=raw_cormat[high_cor_idx])

## 3.5.2 age regressed residual cor
long<- d %>% unique %>%
  pivot_longer(
    matches('rest.hurst.|sipfc'),
    names_to=c('measure','roi'), names_sep="\\.")


si_or_hurst <- function(measure, d) {
  if(measure[1]=='sipfc'){
    fml <- value~sess.age +(1|lunaid)
  } else {                                                         
    fml <- value ~ sess.age + rest.fd + (1|lunaid)
  }
  mdl  <- lmer(data=d, fml, na.action = na.exclude)
  # lmer residuals have name attribute. goes back into dplyr as list
  # tidyverse unlists as a character!?
  unname(residuals(mdl))
}

# confirm reshape and function does what we expect
res_example <- long %>% filter(grepl('hurst_b',measure), grepl('RDLPFC',roi)) %>%
                si_or_hurst('hurst',.)
res_example2 <- lmer(data=d,
                     hurst_brns.RDLPFC_hurst ~ sess.age + rest.fd + (1|lunaid),
                     na.action=na.exclude ) %>% residuals() %>% unname()
testthat::expect_equal(res_example,res_example2) # no error = success!


d_resid <- long %>% 
  group_by(measure, roi) %>% 
  # toggle lm based on what measure (hurst or sipfc) we are using  
  mutate(resid=si_or_hurst(measure, pick(everything())))

d_resid_wide <- d_resid %>%
   select(roi, resid, lunaid,sess.age, measure) %>%
   pivot_wider(names_from=roi, values_from=resid)


resid_nums_only <- d_resid_wide %>% ungroup %>% select(-lunaid,-measure)
# correlation table with residualized values 
resid_cmat <- cor(resid_nums_only, use='pairwise.complete.obs') # this creates correlation matrix table values
corrplot(resid_cmat, method = "number", order = "alphabet", type = "lower", sig.level = 0.05, insig='blank')

# TODO: "not enough finite obervations"
pvals <- cor.mtest(as.matrix(resid_nums_only), conf.level = 0.95, use='pairwise.complete.obs')
corrplot(resid_cmat) #, p.mat = pvals$p, method = "number", order = "alphabet", type = "lower", sig.level = 0.05, insig='blank')


# partial correlations

# sipfc columns like sipfc.roi_met
sipfc <- d  %>%                                                                                                             
  select(matches('sipfc'),lunaid,sess.age) %>%                                                                        
  pivot_longer(matches('^sipfc'),                                                                                             
               names_to=c("measure","roi","met"), names_sep="[._]", values_to="mrs_vals") 

# hurst coluns like hurst.roi_junk
hurst <- d %>%
  select(matches('hurst'),lunaid,sess.age) %>%
  pivot_longer(matches('hurst'), 
               names_to=c("method","measure", "roi"), names_sep="[._]", values_to="h_vals") 

# merge back together
hurst_sipfc <- merge(sipfc,hurst,by=c('lunaid','sess.age','roi'),all=T)

hurst_sipfc %>% 
  group_by(roi,met, junk) %>% 
  summarise(pc=tryCatch(
    pcor.test(sipfc,hurst,sess.age,method="pearson"),
    error=function(x)NA))

hurst_sipfc %>% 
  group_by(roi,met,junk) %>% 
  summarise(pc=pcor.test(sipfc,hurst,sess.age,method="pearson"), n=n())

hurst_sipfc %>% 
  filter(!is.na(sipfc),!is.na(hurst)) %>%
  group_by(roi,met,junk) %>% 
  summarise(pc=pcor.test(sipfc,hurst,sess.age), n=n())

# d %>% group_by(lunaid, sess.age) %>% 

with(merge7t %>% 
       dplyr::select(sipfc.ACC_GluGABARat, rest.hurst.ACC, invage) %>% 
       na.omit(),
     pcor.test(sipfc.ACC_GluGABARat, rest.hurst.ACC, invage, method="pearson")
     ) 

partial.r(merge7t, c('sipfc.ACC_Glu_gamadj', 'rest.hurst.ACC'), 'invage', use="complete.obs", method="pearson")

gaba_hurst <- hurst_sipfc %>% filter(met == 'GABA')
ggplot(data=gaba_hurst %>% filter(roi == 'ACC')) + aes(x=sipfc, y = hurst) + geom_point() + stat_smooth(method="lm") +
  xlab("GABA") + ylab("Hurst") + ggtitle("ACC GABA and Hurst")

ggplot(data=gaba_hurst %>% filter(roi == 'MPFC')) + aes(x=sipfc, y = hurst) + geom_point() + stat_smooth(method="lm") +
  xlab("GABA") + ylab("Hurst") + ggtitle("MPFC GABA and Hurst")

ggplot(data=gaba_hurst %>% filter(roi == 'RDLPFC')) + aes(x=sipfc, y = hurst) + geom_point() + stat_smooth(method="lm") +
  xlab("GABA") + ylab("Hurst") + ggtitle("RDLPFC GABA and Hurst")

ggplot(data=gaba_hurst %>% filter(roi == 'LDLPFC')) + aes(x=sipfc, y = hurst) + geom_point() + stat_smooth(method="lm") +
  xlab("GABA") + ylab("Hurst") + ggtitle("LDLPFC GABA and Hurst")

Glu_hurst <- hurst_sipfc %>% filter(met == 'Glu')
ggplot(data=Glu_hurst %>% filter(roi == 'ACC')) + aes(x=sipfc, y = hurst) + geom_point() + stat_smooth(method="lm") +
  xlab("Glu") + ylab("Hurst") + ggtitle("ACC Glu and Hurst")

ggplot(data=Glu_hurst %>% filter(roi == 'MPFC')) + aes(x=sipfc, y = hurst) + geom_point() + stat_smooth(method="lm") +
  xlab("Glu") + ylab("Hurst") + ggtitle("MPFC Glu and Hurst")

ggplot(data=Glu_hurst %>% filter(roi == 'RDLPFC')) + aes(x=sipfc, y = hurst) + geom_point() + stat_smooth(method="lm") +
  xlab("Glu") + ylab("Hurst") + ggtitle("RDLPFC Glu and Hurst")

ggplot(data=Glu_hurst %>% filter(roi == 'LDLPFC')) + aes(x=sipfc, y = hurst) + geom_point() + stat_smooth(method="lm") +
  xlab("Glu") + ylab("Hurst") + ggtitle("LDLPFC Glu and Hurst")

# 4.0 Aim 2: how neighborhood deprivation impacts developmental trajectories of E/I   ----

# remove participants who were out of the US for their adolescence bc no ADI info or declined to provide
merge7t <- merge7t %>% filter(!lunaid %in% c("11715", "11656", "11890", "11868", "11666", "11705", "11838", "11647"))

# count how many people we have ADI data for
merge7t %>% filter(!is.na(ADI_NATRANK)) %>% pull(lunaid) %>% unique() %>% length()

## 4.1 ADI and E/I; fixed effects ----

### 4.1.1 ADI and Glu GABA Ratio ----

# DLPFC
dlpfc<- merge7t %>% select(lunaid, visitno, sess.age, sex, ADI_NATRANK, sipfc.LDLPFC_all_GMrat, sipfc.RDLPFC_all_GMrat, matches('sipfc.RDLPFC_(Glu|GABA)_gamadj'), matches('sipfc.LDLPFC_(Glu|GABA)_gamadj'))
dlpfc_long <- dlpfc %>%
  pivot_longer(matches('sipfc')) %>% 
  separate(name,c('src','roi','met','measure')) %>% 
  pivot_wider(names_from=c('measure','met'),values_from='value')
dlpfc_long$GGRat<- dlpfc_long$gamadj_Glu/dlpfc_long$gamadj_GABA

dlpfc_long$invage <- 1/dlpfc_long$sess.age

dlpfc_ggrat_ADI <- lmer(data=dlpfc_long, GGRat~ invage + ADI_NATRANK + sex + roi + (1|lunaid))
summary(dlpfc_ggrat_ADI)
ggplot(data=dlpfc_long) + aes(x=ADI_NATRANK, y=GGRat, group=lunaid, roi, color = roi) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL)) +theme_classic(base_size=25) + xlab("ADI") + ylab("DLPFC Glu/GABA Ratio") +
  geom_line(aes(group=paste(lunaid, roi))) 

dlpfc_ggrat_ADI_int <- lmer(data=dlpfc_long, GGRat~ invage * ADI_NATRANK + sex + roi + (1|lunaid))
summary(dlpfc_ggrat_ADI_int)

dlpfc_ggrat_ADI_scaled <- lmer(data=dlpfc_long, scale(GGRat, center = T, scale = T) ~ scale(invage, center =T, scale = T) + scale(ADI_NATRANK, center=T, scale=T) + sex + roi + (1|lunaid))
summary(dlpfc_ggrat_ADI_scaled)

dlpfc_ggrat_ADI_scaled_int <- lmer(data=dlpfc_long, scale(GGRat, center = T, scale = T) ~ scale(invage, center =T, scale = T) * scale(ADI_NATRANK, center=T, scale=T) + sex + roi + (1|lunaid))
summary(dlpfc_ggrat_ADI_scaled_int)

# ACC
acc_ggrat_ADI<- lmer(data=merge7t, sipfc.ACC_GluGABARat~ invage + ADI_NATRANK + sex + (1|lunaid))
summary(acc_ggrat_ADI)

ggplot(data=merge7t) + aes(x=ADI_NATRANK, y=sipfc.ACC_GluGABARat, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL)) +theme_classic(base_size=25) + xlab("adi") + ylab("ACC Glu/GABA Ratio") +
  geom_line() 

acc_ggrat_ADI_int<- lmer(data=merge7t, sipfc.ACC_GluGABARat~ invage * ADI_NATRANK + sex + (1|lunaid))
summary(acc_ggrat_ADI_int)

# scaled model to find standardized effect sizes 
acc_ggrat_ADI_Scaled<- lmer(data=merge7t, scale(sipfc.ACC_GluGABARat, center = T, scale = T)~ scale(invage, center=T, scale = T) + scale(ADI_NATRANK, center = T, scale = T) + sex + (1|lunaid))
summary(acc_ggrat_ADI_Scaled)

acc_ggrat_ADI_Scaled_int<- lmer(data=merge7t, scale(sipfc.ACC_GluGABARat, center = T, scale = T)~ scale(invage, center=T, scale = T) * scale(ADI_NATRANK, center = T, scale = T) + sex + (1|lunaid))
summary(acc_ggrat_ADI_Scaled_int)

# MPFC 
mpfc_ggrat_ADI<- lmer(data=merge7t, sipfc.MPFC_GluGABARat~ invage + ADI_NATRANK + sex + (1|lunaid))
summary(mpfc_ggrat_ADI)
ggplot(data=merge7t) + aes(x=ADI_NATRANK, y=sipfc.MPFC_GluGABARat, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("MPFC Glu/GABA Ratio") +
  geom_line() 
# scaled model to find standardized effect sizes 
mpfc_ggrat_ADI_Scaled<- lmer(data=merge7t, scale(sipfc.MPFC_GluGABARat, center = T, scale = T)~ scale(invage, center=T, scale = T) + scale(ADI_NATRANK, center = T, scale = T) + sex + (1|lunaid))
summary(mpfc_ggrat_ADI_Scaled)


mpfc_ggrat_ADI_Scaled_int<- lmer(data=merge7t, scale(sipfc.MPFC_GluGABARat, center = T, scale = T)~ scale(invage, center=T, scale = T) * scale(ADI_NATRANK, center = T, scale = T) + sex + (1|lunaid))
summary(mpfc_ggrat_ADI_Scaled_int)

### 4.1.2 ADI and Glu/GABA Mismatch ----
# DLPFC
dlpfc_long$mismatch<- abs(residuals(lm(data= dlpfc_long, gamadj_Glu~gamadj_GABA, na.action = na.exclude)))

dlpfc_mismatch_ADI <- lmer(data=dlpfc_long, mismatch~ invage + ADI_NATRANK + sex + roi + (1|lunaid))
summary(dlpfc_mismatch_ADI)
ggplot(data=dlpfc_long) + aes(x=ADI_NATRANK, y=mismatch, group=lunaid, roi, color = roi) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL)) +theme_classic(base_size=25) + xlab("ADI") + ylab("DLPFC Glu/GABA Mismatch") +
  geom_line(aes(group=paste(lunaid, roi))) 

dlpfc_mismatch_ADI_scaled <- lmer(data=dlpfc_long, scale(mismatch, center = T, scale = T) ~ scale(invage, center =T, scale = T) + scale(ADI_NATRANK, center=T, scale=T) + sex + roi + (1|lunaid))
summary(dlpfc_mismatch_ADI_scaled)

dlpfc_mismatch_ADI_scaled_int <- lmer(data=dlpfc_long, scale(mismatch, center = T, scale = T) ~ scale(invage, center =T, scale = T) * scale(ADI_NATRANK, center=T, scale=T) + sex + roi + (1|lunaid))
summary(dlpfc_mismatch_ADI_scaled_int)

# ACC
acc_mismatch_ADI<- lmer(data=merge7t, sipfc.ACC_GluGABAMismatch~ invage + ADI_NATRANK + sex + (1|lunaid))
summary(acc_mismatch_ADI)
ggplot(data=merge7t) + aes(x=ADI_NATRANK, y=sipfc.ACC_GluGABAMismatch, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL)) +theme_classic(base_size=25) + xlab("ADI") + ylab("ACC Glu/GABA Mismatch") +
  geom_line() 
acc_mismatch_ADI_int<- lmer(data=merge7t, sipfc.ACC_GluGABAMismatch~ invage * ADI_NATRANK + sex + (1|lunaid))
summary(acc_mismatch_ADI_int)

# scaled model to find standardized effect sizes 
acc_mismatch_ADI_Scaled<- lmer(data=merge7t, scale(sipfc.ACC_GluGABAMismatch, center = T, scale = T)~ scale(invage, center=T, scale = T) + scale(ADI_NATRANK, center = T, scale = T) + sex + (1|lunaid))
summary(acc_mismatch_ADI_Scaled)
acc_mismatch_ADI_Scaled_int<- lmer(data=merge7t, scale(sipfc.ACC_GluGABAMismatch, center = T, scale = T)~ scale(invage, center=T, scale = T)* scale(ADI_NATRANK, center = T, scale = T) + sex + (1|lunaid))
summary(acc_mismatch_ADI_Scaled_int) # sig

ggplot(data=merge7t%>% filter(!is.na(sess.age))) + aes(x=ADI_NATRANK, y=sipfc.ACC_GluGABAMismatch, group=lunaid, color=sess.age<15) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL), alpha=0.2) +theme_classic(base_size=25) + xlab("ADI") + ylab("ACC Glu/GABA Mismatch") +
  geom_line(alpha=0.2) 

jn <- johnson_neyman(model=acc_mismatch_ADI_int, pred =ADI_NATRANK, modx = invage)

ggplot(data = jn$cbands %>% mutate(age = 1/invage) %>% filter(age < 34), 
       aes(x=age, y = `Slope of ADI_NATRANK`, ymin=Lower, ymax=Upper, fill=Significance)) +
  geom_ribbon(alpha=0.2) +
  geom_line(aes(group=NA)) + 
  geom_abline(slope=0, intercept=0, linetype=2) +
  theme_bw() + coord_cartesian(xlim=c(10,34))

ggplot(data = jn$cbands %>% 
         mutate(age = 1/invage,
       label=ifelse(Significance == 'Significant', 'p < 0.05', 'ns'))%>% filter(age < 34), 
       aes(x=age, y = `Slope of ADI_NATRANK`, ymin=Lower, ymax=Upper, fill=label)) +
  geom_ribbon(alpha=0.2) +
  geom_line() + 
  geom_abline(slope=0, intercept=0, linetype=2) +
  coord_cartesian(xlim=c(10,30)) +
  theme_bw() +
  theme(legend.title = element_blank(),
        legend.position = c(.8, .2)) +
  ylab ("Slope of ADI") + xlab("Age")

ggsave("acc_adi_ggmis_age_int_jn.tiff", width = 20, height = 20, units = "cm", dpi = 300)

acc <- c( "#FAA4A4", "#46BFD7" )

ggplot(data = merge7t %>% filter(!is.na(sess.age)) %>%
         mutate(Age = ifelse(sess.age > 14.8, "Over 15", "Under 15") ), 
       aes(x=ADI_NATRANK, y = sipfc.ACC_GluGABAMismatch, group=lunaid, color=Age)) +
  geom_point() +
  stat_smooth(method="lm", alpha=0.2, aes(group=NULL, fill=Age)) +
  ylab ("Glu/GABA Mismatch") + xlab("ADI") + 
  theme_classic(base_size=25) + 
 theme(legend.position = c(.85, .9)) +
  scale_color_manual(values = acc) + 
  scale_fill_manual(values=acc)

ggsave("acc_adi_ggmis_age_int_agegroup.tiff", width = 20, height = 20, units = "cm", dpi = 300)

fakedata<- data.frame(age=seq(10,30)) %>% 
  merge(.,data.frame(ADI_NATRANK=seq(0,100, by=20))) %>% 
  mutate(roi='ACC', sex='F', lunaid='11323', invage=1/age)

fakedata$xmismatch <- predict(acc_mismatch_ADI_int, fakedata)
ggplot(data=fakedata %>% mutate(ADI=ADI_NATRANK)) +aes(x=age, y=xmismatch, color=ADI, group=ADI) + 
  geom_line() +
  ylab ("Glu/GABA Mismatch") + xlab("Age") + 
  theme_classic(base_size=20) + 
  theme(legend.position = c(.9, .7))

ggsave("acc_adi_ggmis_age_int_predict.tiff", width = 20, height = 20, units = "cm", dpi = 300)


# MPFC 
mpfc_mismatch_ADI<- lmer(data=merge7t, sipfc.MPFC_GluGABAMismatch~ invage + ADI_NATRANK + sex + (1|lunaid))
summary(mpfc_mismatch_ADI)
ggplot(data=merge7t) + aes(x=ADI_NATRANK, y=sipfc.MPFC_GluGABAMismatch, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL)) +theme_classic(base_size=25) + xlab("ADI") + ylab("MPFC Glu/GABA Mismatch") +
  geom_line() 
mpfc_mismatch_ADI_int<- lmer(data=merge7t, sipfc.MPFC_GluGABAMismatch~ invage * ADI_NATRANK + sex + (1|lunaid))
summary(mpfc_mismatch_ADI_int)

# scaled model to find standardized effect sizes 
mpfc_mismatch_ADI_Scaled<- lmer(data=merge7t, scale(sipfc.MPFC_GluGABAMismatch, center = T, scale = T)~ scale(invage, center=T, scale = T) + scale(ADI_NATRANK, center = T, scale = T) + sex + (1|lunaid))
summary(mpfc_mismatch_ADI_Scaled)

mpfc_mismatch_ADI_Scaled_int<- lmer(data=merge7t, scale(sipfc.MPFC_GluGABAMismatch, center = T, scale = T)~ scale(invage, center=T, scale = T) * scale(ADI_NATRANK, center = T, scale = T) + sex + (1|lunaid))
summary(mpfc_mismatch_ADI_Scaled_int)

jn2 <- johnson_neyman(model=mpfc_mismatch_ADI_int, pred =ADI_NATRANK, modx = invage)

mpfc <- c( "#46BFD7", "#FAA4A4" )


ggplot(data = jn2$cbands %>% 
         mutate(age = 1/invage,
                label=ifelse(Significance == 'Significant', 'p < 0.05', 'ns'))%>% filter(age < 34), 
       aes(x=age, y = `Slope of ADI_NATRANK`, ymin=Lower, ymax=Upper, fill=label)) +
  geom_ribbon(alpha=0.2) +
  geom_line() + 
  geom_abline(slope=0, intercept=0, linetype=2) +
  coord_cartesian(xlim=c(10,30)) +
  theme_bw() +
  theme(legend.title = element_blank(),
        legend.position = c(.8, .8)) +
  xlab("Age") + ylab("Slope of ADI")

ggsave("mpfc_adi_ggmis_age_int_jn.tiff", width = 20, height = 20, units = "cm", dpi = 300)


ggplot(data = merge7t %>% filter(!is.na(sess.age)) %>%
         mutate(Age = ifelse(sess.age > 22, "Over 22", "Under 22") ), 
       aes(x=ADI_NATRANK, y = sipfc.MPFC_GluGABAMismatch, group=lunaid, color=Age)) +
  geom_point() +
  stat_smooth(method="lm", alpha=0.2, aes(group=NULL, fill=Age)) +
  ylab ("Glu/GABA Mismatch") + xlab("ADI") + 
  theme_classic(base_size=25) + 
  theme(legend.position = c(.85, .9)) +
  scale_color_manual(values = mpfc) + 
  scale_fill_manual(values=mpfc)

ggsave("MPFC_adi_ggmis_age_int_agegroup.tiff", width = 20, height = 20, units = "cm", dpi = 300)

fakedata<- data.frame(age=seq(10,30)) %>% 
  merge(.,data.frame(ADI_NATRANK=seq(0,100, by=20))) %>% 
  mutate(roi='MPFC', sex='F', lunaid='11323', invage=1/age)

fakedata$xmismatch <- predict(mpfc_mismatch_ADI_int, fakedata)
ggplot(data=fakedata %>% mutate(ADI=ADI_NATRANK)) +aes(x=age, y=xmismatch, color=ADI, group=ADI) + 
  geom_line() +
  ylab ("Glu/GABA Mismatch") + xlab("Age") + 
  theme_classic(base_size=20) + 
  theme(legend.position = c(.9, .7))

ggsave("MPFC_adi_ggmis_age_int_predict.tiff", width = 20, height = 20, units = "cm", dpi = 300)



### 4.1.3 ADI and Hurst ----

#dlpfc
dlpfc_hurst<- merge7t %>% dplyr::select(lunaid, visitno, sess.age, sex, rest.hurst.RDLPFC , rest.hurst.LDLPFC, rest.fd, ADI_NATRANK)

dlpfc_long <- dlpfc_hurst %>%
  pivot_longer(cols = matches("rest\\.hurst\\.*"), names_to = "name", values_to = "value") %>%
  separate(name, into = c("scan", "parameter", "roi"), sep = "\\.")

dlpfc_long$invage <- 1/dlpfc_long$sess.age
dlpfc_long$quadage <- (dlpfc_long$sess.age - mean(dlpfc_long$sess.age, na.rm=T))^2

dlpfc_hurst_ADI <- lmer(data=dlpfc_long, value~ invage + ADI_NATRANK + sex + roi + rest.fd + (1|lunaid))
summary(dlpfc_hurst_ADI)
ggplot(data=dlpfc_long) + aes(x=ADI_NATRANK, y=value, group=lunaid, roi, color = roi) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL)) +theme_classic(base_size=25) + xlab("ADI") + ylab("DLPFC Hurst") +
  geom_line(aes(group=paste(lunaid, roi))) 

dlpfc_hurst_ADI_scaled <- lmer(data=dlpfc_long, scale(value, center = T, scale = T) ~ scale(invage, center =T, scale = T) + scale(ADI_NATRANK, center=T, scale=T) + sex + roi + scale(rest.fd, center=T, scale=T) +(1|lunaid))
summary(dlpfc_hurst_ADI_scaled)

# ACC
acc_hurst_ADI<- lmer(data=merge7t, rest.hurst.ACC ~ invage + ADI_NATRANK + rest.fd + sex + (1|lunaid))
summary(acc_hurst_ADI)
ggplot(data=merge7t) + aes(x=ADI_NATRANK, y=rest.hurst.ACC, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL)) +theme_classic(base_size=25) + xlab("ADI") + ylab("ACC Hurst") +
  geom_line() 
# scaled model to find standardized effect sizes 
acc_hurst_ADI_Scaled<- lmer(data=merge7t, scale(rest.hurst.ACC, center = T, scale = T)~ scale(invage, center=T, scale = T) + scale(ADI_NATRANK, center = T, scale = T) + scale(rest.fd, center=T, scale=T) + sex + (1|lunaid))
summary(acc_hurst_ADI_Scaled)

# MPFC 
mpfc_hurst_ADI<- lmer(data=merge7t, rest.hurst.MPFC~ invage + ADI_NATRANK + sex + rest.fd + (1|lunaid))
summary(mpfc_hurst_ADI)
ggplot(data=merge7t) + aes(x=ADI_NATRANK, y=rest.hurst.MPFC, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL)) +theme_classic(base_size=25) + xlab("ADI") + ylab("MPFC Hurst") +
  geom_line() 
# scaled model to find standardized effect sizes 
mpfc_hurst_ADI_Scaled<- lmer(data=merge7t, scale(rest.hurst.MPFC, center = T, scale = T)~ scale(invage, center=T, scale = T) + scale(ADI_NATRANK, center = T, scale = T) + scale(rest.fd, center=T, scale=T) + sex + (1|lunaid))
summary(mpfc_hurst_ADI_Scaled)


## 4.2 ADI and E/I; linear interaction w/ post-hoc J-N plots ----

### 4.2.1 - Glu/GABA Ratio & ADI interaction ----

# dlpfc
dlpfc<- merge7t %>% select(lunaid, visitno, sess.age, sex, ADI_NATRANK, sipfc.LDLPFC_all_GMrat, sipfc.RDLPFC_all_GMrat, matches('sipfc.RDLPFC_(Glu|GABA)_gamadj'), matches('sipfc.LDLPFC_(Glu|GABA)_gamadj'))
dlpfc_long <- dlpfc %>%
  pivot_longer(matches('sipfc')) %>% 
  separate(name,c('src','roi','met','measure')) %>% 
  pivot_wider(names_from=c('measure','met'),values_from='value')
dlpfc_long$GGRat<- dlpfc_long$gamadj_Glu/dlpfc_long$gamadj_GABA

dlpfc_long<- dlpfc_long %>% mutate(across(matches("GGRat"), na_z))
dlpfc_long$invage <- 1/dlpfc_long$sess.age

dlpfc_ggrat_ADI_int <- lmer(data=dlpfc_long, GGRat~ invage * ADI_NATRANK + sex + roi + (1|lunaid))
summary(dlpfc_ggrat_ADI_int)

# ACC
acc_ggrat_ADI_int<- lmer(data=merge7t, sipfc.ACC_GluGABARat~ invage * ADI_NATRANK + sex + (1|lunaid))
summary(acc_ggrat_ADI_int)
ggplot(data=merge7t) + aes(x=ADI_NATRANK, y=sipfc.ACC_GluGABARat, group=lunaid, color = sess.age < 18) + geom_point() + 
  stat_smooth(method="lm",aes(group=NULL)) +theme_classic(base_size=25) + xlab("adi") + ylab("ACC Glu/GABA Ratio") +
  geom_line() 
ggplot(data=merge7t %>% filter(!is.na(ADI_NATRANK))) + aes(x=sess.age, y=sipfc.ACC_GluGABARat, group=lunaid, color = ADI_NATRANK < 50) + geom_point() + 
  stat_smooth(method="lm",aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("ACC Glu/GABA Ratio") +
  geom_line() 


# MPFC
mpfc_ggrat_ADI_int<- lmer(data=merge7t, sipfc.MPFC_GluGABARat~ invage * ADI_NATRANK + sex + (1|lunaid))
summary(mpfc_ggrat_ADI_int)


### 4.2.2 - Glu/GABA Mismatch & ADI interaction ----
#dlpfc
dlpfc_long$mismatch<- abs(residuals(lm(data= dlpfc_long, gamadj_Glu~gamadj_GABA, na.action = na.exclude)))

dlpfc_mismatch_ADI_int <- lmer(data=dlpfc_long, mismatch~ invage * ADI_NATRANK + sex + roi + (1|lunaid))
summary(dlpfc_mismatch_ADI_int)

# acc
acc_mismatch_ADI_int<- lmer(data=merge7t, sipfc.ACC_GluGABAMismatch~ invage * ADI_NATRANK + sex + (1|lunaid))
summary(acc_mismatch_ADI_int)

# mpfc 
mpfc_mismatch_ADI_int <- lmer(data=merge7t, sipfc.MPFC_GluGABAMismatch~ invage * ADI_NATRANK + sex + (1|lunaid))
summary(mpfc_mismatch_ADI_int)

### 4.2.3 - Hurst & ADI interaction ----

#dlpfc
dlpfc_hurst_ADI_int <- lmer(data=dlpfc_long, value~ invage * ADI_NATRANK + sex + roi + rest.fd + (1|lunaid))
summary(dlpfc_hurst_ADI_int)

dlpfc_hurst_ADI_int_scaled <- lmer(data=dlpfc_long, scale(value, center = T, scale = T) ~ scale(invage, center =T, scale = T) * scale(ADI_NATRANK, center=T, scale=T) + sex + roi + scale(rest.fd, center=T, scale=T) +(1|lunaid))
summary(dlpfc_hurst_ADI_int_scaled)

jn <- johnson_neyman(model=dlpfc_hurst_ADI_int, pred =ADI_NATRANK, modx = invage)

ggplot(data = jn$cbands %>% 
         mutate(age = 1/invage,
                label=ifelse(Significance == 'Significant', 'p < 0.05', 'ns')), 
       aes(x=age, y = `Slope of ADI_NATRANK`, ymin=Lower, ymax=Upper, fill=label)) +
  geom_ribbon(alpha=0.2) +
  geom_line(aes(group=NA)) + 
  geom_abline(slope=0, intercept=0, linetype=2) +
  coord_cartesian(xlim=c(10,30)) +
  theme_bw() +
  theme(legend.title = element_blank(),
        legend.position = c(.8, .2)) +
  ylab ("Slope of ADI") + xlab("Age")

#ggsave("acc_adi_ggmis_age_int_jn.tiff", width = 20, height = 20, units = "cm", dpi = 300)

#acc <- c( "#FAA4A4", "#46BFD7" )

#ggplot(data = merge7t %>% filter(!is.na(sess.age)) %>%
#         mutate(Age = ifelse(sess.age > 14.8, "Over 15", "Under 15") ), 
#       aes(x=ADI_NATRANK, y = sipfc.ACC_GluGABAMismatch, group=lunaid, color=Age)) +
#  geom_point() +
#  stat_smooth(method="lm", alpha=0.2, aes(group=NULL, fill=Age)) +
#  ylab ("Glu/GABA Mismatch") + xlab("ADI") + 
#  theme_classic(base_size=25) + 
#  theme(legend.position = c(.85, .9)) +
#  scale_color_manual(values = acc) + 
#  scale_fill_manual(values=acc)

#ggsave("acc_adi_ggmis_age_int_agegroup.tiff", width = 20, height = 20, units = "cm", dpi = 300)

#fakedata<- data.frame(age=seq(10,30)) %>% 
#  merge(.,data.frame(ADI_NATRANK=seq(0,100, by=20))) %>% 
#  mutate(roi='ACC', sex='F', lunaid='11323', invage=1/age)

#fakedata$xmismatch <- predict(acc_mismatch_ADI_int, fakedata)
#ggplot(data=fakedata %>% mutate(ADI=ADI_NATRANK)) +aes(x=age, y=xmismatch, color=ADI, group=ADI) + 
#  geom_line() +
#  ylab ("Glu/GABA Mismatch") + xlab("Age") + 
#  theme_classic(base_size=20) + 
#  theme(legend.position = c(.9, .7))

#ggsave("acc_adi_ggmis_age_int_predict.tiff", width = 20, height = 20, units = "cm", dpi = 300)


# acc
acc_hurst_ADI_int<- lmer(data=merge7t, rest.hurst.ACC ~ invage * ADI_NATRANK + sex + rest.fd + (1|lunaid))
summary(acc_hurst_ADI_int)

acc_hurst_ADI_int_scaled<- lmer(data=merge7t, scale(rest.hurst.ACC, center = T, scale = T) ~ scale(invage, center = T, scale = T) * scale(ADI_NATRANK, center = T, scale = T) + sex + scale(rest.fd, center = T, scale = T) + (1|lunaid))
summary(acc_hurst_ADI_int_scaled)


# mpfc
mpfc_hurst_ADI_int<- lmer(data=merge7t, rest.hurst.MPFC ~ invage * ADI_NATRANK + sex + rest.fd + (1|lunaid))
summary(mpfc_hurst_ADI_int)
mpfc_hurst_ADI_int_scaled<- lmer(data=merge7t, scale(rest.hurst.MPFC, center = T, scale = T) ~ scale(invage, center = T, scale = T) * scale(ADI_NATRANK, center = T, scale = T) + sex + scale(rest.fd, center = T, scale = T) + (1|lunaid))
summary(mpfc_hurst_ADI_int_scaled)


## 4.3 ADI and E/I; if no linear interaction, threshold effect & sensitivity analysis ----
merge7t$ADI_group <- ifelse(merge7t$ADI_NATRANK > 70, 1, 0) # vary this cutoff and then run the respective model

### 4.3.1 ADI and Glu GABA ratio threshold ----
# DLPFC
dlpfc<- merge7t %>% select(lunaid, visitno, sess.age, sex, ADI_group, sipfc.LDLPFC_all_GMrat, sipfc.RDLPFC_all_GMrat, matches('sipfc.RDLPFC_(Glu|GABA)_gamadj'), matches('sipfc.LDLPFC_(Glu|GABA)_gamadj'))
dlpfc_long <- dlpfc %>%
  pivot_longer(matches('sipfc')) %>% 
  separate(name,c('src','roi','met','measure')) %>% 
  pivot_wider(names_from=c('measure','met'),values_from='value')
dlpfc_long$GGRat<- dlpfc_long$gamadj_Glu/dlpfc_long$gamadj_GABA

dlpfc_long$invage <- 1/dlpfc_long$sess.age

dlpfc_ggrat_ADI50_int <- lmer(data=dlpfc_long %>% filter(ADI_group ==1), GGRat~ invage * ADI_group + sex + roi + (1|lunaid))
summary(dlpfc_ggrat_ADI50_int)

dlpfc_ggrat_ADI50_int <- lmer(data=dlpfc_long, GGRat~ invage * ADI_group + sex + roi + (1|lunaid))
summary(dlpfc_ggrat_ADI50_int)

dlpfc_ggrat_ADI60_int <- lmer(data=dlpfc_long, GGRat~ invage * ADI_group + sex + roi + (1|lunaid))
summary(dlpfc_ggrat_ADI60_int)

dlpfc_ggrat_ADI60_int <- lmer(data=dlpfc_long%>% filter(ADI_group ==1), GGRat~ invage * ADI_group + sex + roi + (1|lunaid))
summary(dlpfc_ggrat_ADI60_int)

dlpfc_ggrat_ADI70_int <- lmer(data=dlpfc_long%>% filter(ADI_group ==1), GGRat~ invage * ADI_group + sex + roi + (1|lunaid))
summary(dlpfc_ggrat_ADI70_int)


# to get the f value for the ADI_group interaction term in the model
anova(dlpfc_ggrat_ADI50_int)
anova(dlpfc_ggrat_ADI60_int)
anova(dlpfc_ggrat_ADI70_int)

# make those values into a list and plot them to see how robust it is to changes


# ACC
acc_ggrat_ADI50_int<- lmer(data=merge7t, sipfc.ACC_GluGABARat~ invage * ADI_group + sex + (1|lunaid))
summary(acc_ggrat_ADI50_int)

acc_ggrat_ADI50_int<- lmer(data=merge7t%>% filter(ADI_group ==1), sipfc.ACC_GluGABARat~ invage * ADI_group + sex + (1|lunaid))
summary(acc_ggrat_ADI50_int)


acc_ggrat_ADI60_int<- lmer(data=merge7t, sipfc.ACC_GluGABARat~ invage * ADI_group + sex + (1|lunaid))
summary(acc_ggrat_ADI60_int)

acc_ggrat_ADI60_int<- lmer(data=merge7t %>% filter(ADI_group ==1), sipfc.ACC_GluGABARat~ invage * ADI_group + sex + (1|lunaid))
summary(acc_ggrat_ADI60_int)

acc_ggrat_ADI70_int<- lmer(data=merge7t, sipfc.ACC_GluGABARat~ invage * ADI_group + sex + (1|lunaid))
summary(acc_ggrat_ADI70_int)

acc_ggrat_ADI70_int<- lmer(data=merge7t%>% filter(ADI_group ==1), sipfc.ACC_GluGABARat~ invage * ADI_group + sex + (1|lunaid))
summary(acc_ggrat_ADI70_int)

# to get the f value for the ADI_group interaction term in the model
anova(acc_ggrat_ADI50_int)
anova(acc_ggrat_ADI60_int)
anova(acc_ggrat_ADI70_int)


# MPFC
mpfc_ggrat_ADI50_int<- lmer(data=merge7t, sipfc.MPFC_GluGABARat~ invage * ADI_group + sex + (1|lunaid))
summary(mpfc_ggrat_ADI50_int)

mpfc_ggrat_ADI50_int<- lmer(data=merge7t%>% filter(ADI_group ==1), sipfc.MPFC_GluGABARat~ invage * ADI_group + sex + (1|lunaid))
summary(mpfc_ggrat_ADI50_int)

mpfc_ggrat_ADI60_int<- lmer(data=merge7t, sipfc.MPFC_GluGABARat~ invage * ADI_group + sex + (1|lunaid))
summary(mpfc_ggrat_ADI60_int)

mpfc_ggrat_ADI60_int<- lmer(data=merge7t%>% filter(ADI_group ==1), sipfc.MPFC_GluGABARat~ invage * ADI_group + sex + (1|lunaid))
summary(mpfc_ggrat_ADI60_int)

mpfc_ggrat_ADI70_int<- lmer(data=merge7t, sipfc.MPFC_GluGABARat~ invage * ADI_group + sex + (1|lunaid))
summary(mpfc_ggrat_ADI70_int)

mpfc_ggrat_ADI70_int<- lmer(data=merge7t%>% filter(ADI_group ==1), sipfc.MPFC_GluGABARat~ invage * ADI_group + sex + (1|lunaid))
summary(mpfc_ggrat_ADI70_int)

# to get the f value for the ADI_group interaction term in the model
anova(mpfc_ggrat_ADI50_int)
anova(mpfc_ggrat_ADI60_int)
anova(mpfc_ggrat_ADI70_int)


### 4.3.2 ADI and Glu GABA mismatch threshold ----
merge7t$ADI_group <- ifelse(merge7t$ADI_NATRANK > 70, 1, 0) # vary this cutoff and then run the respective model

# DLPFC
dlpfc<- merge7t %>% select(lunaid, visitno, sess.age, sex, ADI_group, sipfc.LDLPFC_all_GMrat, sipfc.RDLPFC_all_GMrat, matches('sipfc.RDLPFC_(Glu|GABA)_gamadj'), matches('sipfc.LDLPFC_(Glu|GABA)_gamadj'))
dlpfc_long <- dlpfc %>%
  pivot_longer(matches('sipfc')) %>% 
  separate(name,c('src','roi','met','measure')) %>% 
  pivot_wider(names_from=c('measure','met'),values_from='value')

dlpfc_long$invage <- 1/dlpfc_long$sess.age

#dlpfc
dlpfc_long$mismatch<- abs(residuals(lm(data= dlpfc_long, gamadj_Glu~gamadj_GABA, na.action = na.exclude)))

dlpfc_mismatch_ADI50_int <- lmer(data=dlpfc_long, mismatch~ invage * ADI_group + sex + roi + (1|lunaid))
summary(dlpfc_mismatch_ADI50_int)

dlpfc_mismatch_ADI60_int <- lmer(data=dlpfc_long, mismatch~ invage * ADI_group + sex + roi + (1|lunaid))
summary(dlpfc_mismatch_ADI60_int)

dlpfc_mismatch_ADI70_int <- lmer(data=dlpfc_long, mismatch~ invage * ADI_group + sex + roi + (1|lunaid))
summary(dlpfc_mismatch_ADI70_int)

# to get the f value for the ADI_group interaction term in the model
anova(dlpfc_mismatch_ADI50_int)
anova(dlpfc_mismatch_ADI60_int)
anova(dlpfc_mismatch_ADI70_int)


### 4.3.3 ADI and Hurst ratio threshold ----
# note: skip over this bc there is a linear interaction for dlpfc
dlpfc_hurst_group<- merge7t %>% dplyr::select(lunaid, visitno, sess.age, sex, ADI_group, hurst_brns.RDLPFC , hurst_brns.LDLPFC, rest.fd)
dlpfc_long <- dlpfc_hurst_group %>%
  pivot_longer(matches('hurst_brns')) %>% 
  separate(name,c("method","preproc","roi"), sep='[._]')
dlpfc_long$invage <- 1/dlpfc_long$sess.age

dlpfc_hurst_ADIgroup50_int <- lmer(data=dlpfc_long, value~ invage * ADI_group + sex + roi + (1|lunaid))
summary(dlpfc_hurst_ADIgroup50_int)

dlpfc_hurst_ADIgroup60_int <- lmer(data=dlpfc_long, value~ invage * ADI_group + sex + roi + (1|lunaid))
summary(dlpfc_hurst_ADIgroup60_int)

dlpfc_hurst_ADIgroup70_int <- lmer(data=dlpfc_long, value~ invage * ADI_group + sex + roi + (1|lunaid))
summary(dlpfc_hurst_ADIgroup70_int)

# to get the f value for the ADI_group interaction term in the model
anova(dlpfc_hurst_ADIgroup60_int)

# acc
acc_hurst_ADIgroup_int50<- lmer(data=merge7t, rest.hurst.ACC ~ invage * ADI_group + sex + (1|lunaid))
summary(acc_hurst_ADIgroup_int50)

acc_hurst_ADIgroup_int60<- lmer(data=merge7t, rest.hurst.ACC ~ invage * ADI_group + sex + (1|lunaid))
summary(acc_hurst_ADIgroup_int60)

acc_hurst_ADIgroup_int70<- lmer(data=merge7t %>% filter(ADI_NATRANK>70), rest.hurst.ACC ~ invage * ADI_group + sex + (1|lunaid))
summary(acc_hurst_ADIgroup_int70)

# to get the f value for the ADI_group interaction term in the model
anova(acc_hurst_ADIgroup_int70)


# mpfc
mpfc_hurst_ADIgroup_int50<- lmer(data=merge7t %>% filter(ADI_NATRANK>50), rest.hurst.MPFC ~ invage * ADI_group + sex + (1|lunaid))
summary(mpfc_hurst_ADIgroup_int50)
anova(mpfc_hurst_ADIgroup_int50)

mpfc_hurst_ADIgroup_int60<- lmer(data=merge7t %>% filter(ADI_NATRANK>60), rest.hurst.MPFC ~ invage * ADI_group + sex + (1|lunaid))
summary(mpfc_hurst_ADIgroup_int60)
anova(mpfc_hurst_ADIgroup_int60)

mpfc_hurst_ADIgroup_int70<- lmer(data=merge7t, rest.hurst.MPFC ~ invage * ADI_group + sex + (1|lunaid))
summary(mpfc_hurst_ADIgroup_int70)
anova(mpfc_hurst_ADIgroup_int70)

# 5.0 Aim 3: how neighborhood deprivation impacts the relationship between E/I and cognitive development across adolescence ----

merge7t <- read.csv('/Volumes/Hera/Projects/7TBrainMech/scripts/txt/merged_7t.csv')

# make smaller dataframe with only variables i need
merge7t <- merge7t %>%
  dplyr::select(lunaid, visitno, rest.age, sess.age, rest.date, behave.date, sex, rest.fd, 
                matches('sipfc.*_(Glu|GABA)_gamadj'),
                matches('sipfc.*_all_GMrat'), 
                matches('rest.hurst.*'),
                matches('ADI_*'), 
                matches('mgsLatency_*'),
                matches('BestError_*'), 
                matches('AntiET.'))

# create age variables 
merge7t$invage <- 1/merge7t$sess.age

# remove bad value (checked lcmodel spectrum to confirm unreliable estimate)
is.na(merge7t$sipfc.MPFC_GABA_gamadj) <- with(merge7t, sipfc.MPFC_GABA_gamadj < 0.2)

# make lunaid a factor 
merge7t$lunaid <- as.factor(merge7t$lunaid)
merge7t$sex<- as.factor(merge7t$sex)
merge7t$ADI_NATRANK<- as.numeric(merge7t$ADI_NATRANK)

# remove psych diagnosis people
merge7t <- merge7t %>% 
  filter(!lunaid %in% c("11646", "11659", "11800", "11653", "11690", "11812"))


#prep just the rest/hurst data
rest.hurst <-  merge7t %>%
  select(lunaid, visitno, sess.age, invage, rest.fd, rest.date,
         matches('rest.hurst.*'))

# prep just the mrsi data
sipfc <- merge7t %>%
  select(lunaid, visitno, sess.age, invage, rest.fd, 
         matches('sipfc.*_(Glu|GABA)_gamadj'),
         matches('sipfc.*_all_GMrat'))

# create glu/gaba ratio variables 
sipfc$sipfc.ACC_GluGABARat <- sipfc$sipfc.ACC_Glu_gamadj/sipfc$sipfc.ACC_GABA_gamadj
sipfc$sipfc.MPFC_GluGABARat <- sipfc$sipfc.MPFC_Glu_gamadj/sipfc$sipfc.MPFC_GABA_gamadj
sipfc$sipfc.RDLPFC_GluGABARat <- sipfc$sipfc.RDLPFC_Glu_gamadj/sipfc$sipfc.RDLPFC_GABA_gamadj
sipfc$sipfc.LDLPFC_GluGABARat <- sipfc$sipfc.LDLPFC_Glu_gamadj/sipfc$sipfc.LDLPFC_GABA_gamadj

# create glu/gaba mismatch variable 
sipfc$sipfc.ACC_GluGABAMismatch<- abs(residuals(lm(data=sipfc, sipfc.ACC_Glu_gamadj ~ sipfc.ACC_GABA_gamadj, na.action=na.exclude)))
sipfc$sipfc.MPFC_GluGABAMismatch<- abs(residuals(lm(data=sipfc, sipfc.MPFC_Glu_gamadj ~ sipfc.MPFC_GABA_gamadj, na.action=na.exclude)))
sipfc$sipfc.RDLPFC_GluGABAMismatch<- abs(residuals(lm(data=sipfc, sipfc.RDLPFC_Glu_gamadj ~ sipfc.RDLPFC_GABA_gamadj, na.action=na.exclude)))
sipfc$sipfc.LDLPFC_GluGABAMismatch<- abs(residuals(lm(data=sipfc, sipfc.LDLPFC_Glu_gamadj ~ sipfc.LDLPFC_GABA_gamadj, na.action=na.exclude)))

#prep just the behavior data
behavior <-  merge7t %>%
  select(lunaid, visitno, sess.age, invage, sex, behave.date, rest.date,
         matches('mgsLatency_*'), 
         matches('BestError_*'), 
         matches('AntiET.')) %>% filter(visitno <3) 

behavior <- behavior %>%
        filter(!is.na(rest.date)) 

behavior$antiET.PctCorr <- behavior$antiET.Cor/(behavior$antiET.Cor + behavior$antiET.ErrCor + behavior$antiET.Err)

per_visits_df <- behavior %>% 
  # create diff column for every variable of interest: v2 - v1
  mutate(across(matches('eeg|anti|age'), function(x) lead(x) - x, .names="{.col}_diff")) %>% 
  # keep only baseline
  filter(visitno==min(visitno))

beh_diffs <- behavior %>% 
  group_by(lunaid) %>% 
  arrange(visitno) %>% # make sure we're sorted so diff makes sense
  transmute(visit=visitno, # keep around, anything not created by transmute will be discarded
            across(matches('eeg|anti'), function(x) lead(x) -x , .names="{.col}_diff")) %>%
  # lead(x) will be "val@row2, NA", don't need the NA rows. and don't want visit in the final merge
  filter(visit==1) %>% select(-visit) 

beh_diffs_m <- merge(behavior, beh_diffs, by="lunaid")

## 5.1 Aim 3A: E/I and cognition ----

# DLPFC Hurst
rest.hurst <- rest.hurst %>% filter( !is.na(rest.fd)) # grab people who have brain data; na on fd means na on rest.date/having data
dlpfc.hurst<- rest.hurst %>% dplyr::select(lunaid, visitno, rest.fd, rest.hurst.RDLPFC, rest.hurst.LDLPFC)

# resid fd first
# resid fd out of hurst values first to simplify later models
resfd <- function(d,incol) residuals(lm(data=d%>%mutate(col=incol), col~rest.fd,na.action=na.exclude))

rest.hurst_res <- dlpfc.hurst %>% 
  
  # residilize each hurst columns separately
  # results wil be same nrows as data (NAs where there is no data to model)
  mutate(across(matches('hurst'), \(col) resfd(pick(everything()), col)))

# calc mean and laterality of fd resid values
rest.hurst_res$Hmean <- (rest.hurst_res$rest.hurst.RDLPFC + rest.hurst_res$rest.hurst.LDLPFC)/2
rest.hurst_res$Lat <- (rest.hurst_res$rest.hurst.RDLPFC - rest.hurst_res$rest.hurst.LDLPFC)/2


# now calculate the difference score using fd residualized values
rest.hurst_diff <- rest.hurst_res %>% 
  
  # diff across sessions: make 'husrt.rest.ROI_diff' columns for each roi (and only within each lunaid) 
  group_by(lunaid) %>% 
  mutate(across(matches('Hmean|Lat'), function(x) x-lead(x), .names = "{.col}_diff")) %>% 
  
  # only 1 row per lunaid, pick row ranked first (whatever visit has data)
  filter(rank(visitno)<2)

scale_vec <- function(x) as.vector(scale(x, scale=T, center=T))

rest.hurst_centered <- rest.hurst_diff %>% 
  ungroup %>%
  mutate(across(starts_with('Hmean'), scale_vec, .names = "{.col}_cent"))

# merge hurst and behavior
hurst.behavior <- merge(rest.hurst_centered, per_visits_df, by="lunaid", all=T)

# DLPFC Hurst

dlpfc_mgsacc <- lm(data=hurst.behavior, scale(eeg.BestError_DelayAll_diff, center=T, scale=T) ~  Hmean_cent+ Hmean_diff_cent + scale(invage, center=T, scale=T) + scale(Lat_diff, center=T, scale=T))
summary(dlpfc_mgsacc)
count(dlpfc_mgsacc$model)

dlpfc_mgsaccsd <- lm(data=hurst.behavior, scale(eeg.BestError_sd_DelayAll_diff, center=T, scale=T) ~  Hmean_cent+ Hmean_diff_cent + scale(invage, center=T, scale=T) + scale(Lat_diff, center=T, scale=T))
summary(dlpfc_mgsaccsd)
count(dlpfc_mgsaccsd$model)

dlpfc_mgslat <- lm(data=hurst.behavior, scale(eeg.mgsLatency_DelayAll_diff, center=T, scale=T) ~  Hmean_cent+ Hmean_diff_cent + scale(invage, center=T, scale=T) + scale(Lat_diff, center=T, scale=T))
summary(dlpfc_mgslat)
count(dlpfc_mgslat$model)

dlpfc_mgslatsd <- lm(data=hurst.behavior, scale(eeg.mgsLatency_sd_DelayAll_diff, center=T, scale=T) ~  Hmean_cent+ Hmean_diff_cent + scale(invage, center=T, scale=T) + scale(Lat_diff, center=T, scale=T))
summary(dlpfc_mgslatsd)
count(dlpfc_mgslatsd$model)

dlpfc_anticor <- lm(data=hurst.behavior, scale(antiET.cor.lat_diff, center=T, scale=T) ~  Hmean_cent+ Hmean_diff_cent + scale(invage, center=T, scale=T) + scale(Lat_diff, center=T, scale=T))
summary(dlpfc_anticor)
count(dlpfc_anticor$model)

dlpfc_pcor <- lm(data=hurst.behavior, scale(antiET.PctCorr_diff, center=T, scale=T) ~  Hmean_cent+ Hmean_diff_cent + scale(invage, center=T, scale=T) + scale(Lat_diff, center=T, scale=T))
summary(dlpfc_pcor)
count(dlpfc_pcor$model)

# DLPFC MRSI

dlpfc_sipfc <- sipfc %>% dplyr::select(lunaid, visitno, invage, sipfc.RDLPFC_GluGABAMismatch, sipfc.LDLPFC_GluGABAMismatch, sipfc.RDLPFC_GluGABARat, sipfc.LDLPFC_GluGABARat)

dlpfc_sipfc$meanGGRat <- (dlpfc_sipfc$sipfc.RDLPFC_GluGABARat + dlpfc_sipfc$sipfc.LDLPFC_GluGABARat)/2
dlpfc_sipfc$LatRat <- (dlpfc_sipfc$sipfc.RDLPFC_GluGABARat - dlpfc_sipfc$sipfc.LDLPFC_GluGABARat)/2

dlpfc_sipfc$meanMismatch <- (dlpfc_sipfc$sipfc.RDLPFC_GluGABAMismatch + dlpfc_sipfc$sipfc.LDLPFC_GluGABAMismatch)/2
dlpfc_sipfc$LatMis <- (dlpfc_sipfc$sipfc.RDLPFC_GluGABAMismatch - dlpfc_sipfc$sipfc.LDLPFC_GluGABAMismatch)/2


dlpfc_wide <- dlpfc_sipfc %>% pivot_wider(id_cols='lunaid', names_from='visitno', values_from=-any_of(c('lunaid','visitno')))
dlpfc_wide <- dlpfc_wide %>% mutate(haveboth = ifelse(!is.na(meanMismatch_1) & !is.na(meanMismatch_2), T, F))
sum(dlpfc_wide$haveboth)

dlpfc_wide <- dlpfc_wide %>% mutate(havebothv1 = ifelse(!is.na(sipfc.LDLPFC_GluGABAMismatch_1) & !is.na(sipfc.LDLPFC_GluGABAMismatch_2), T, F))
sum(dlpfc_wide$havebothv1)

dlpfc_wide <- dlpfc_wide %>% mutate(havebothv2 = ifelse(!is.na(sipfc.RDLPFC_GluGABAMismatch_2) & !is.na(sipfc.RDLPFC_GluGABAMismatch_2), T, F))
sum(dlpfc_wide$havebothv2)




# something is going wrong here


# now calculate the difference score
sipfc_diff <- dlpfc_sipfc %>% 
    group_by(lunaid) %>% 
  mutate(across(matches('meanMismatch|LatMis'), function(x) x-lead(x), .names = "{.col}_diff")) %>% 
    filter(rank(visitno)<2)

sipfc_diff %>%  ungroup %>% count(meanMismatch_diff) %>% View
scale_vec <- function(x) as.vector(scale(x, scale=T, center=T))

sipfc_centered <- sipfc_diff %>% 
  ungroup %>%
  mutate(across(starts_with('mean'), scale_vec, .names = "{.col}_cent"))

# merge sipfc and behavior
sipfc.behavior <- merge(sipfc_centered, per_visits_df, by="lunaid", all=T)



#### 5.1.1 - Cog and Hurst -----

# baseline timepoint 1 is called e.g., rest.hurst.ACC. Delta t1 to t2 is called rest.hurst.ACC_diff
# want to create new grand mean centered variables for both baseline and change

# model is cog_diff ~ rest.hurst.ACC_1 + rest.hurst.ACC_diff + invage_1

# MGS models - accuracy (eeg.BestError_DelayAll, eeg.BestError_sd_DelayAll) and latency (eeg.mgsLatency_DelayAll, eeg.mgsLatency_sd_DelayAll)

diffscore_effects <- ggpredict(diffscore, 
                               terms = c("rest.hurst.ACC_cent", "rest.hurst.ACC_diff_cent"))
diffscore_effects %>% plot()

# ACC Hurst
acch_mgsacc <- lm(data=hurst.behavior, eeg.BestError_DelayAll_diff ~  rest.hurst.ACC_cent+ rest.hurst.ACC_diff_cent + invage.y)
summary(acch_mgsacc)

acch_mgsacc <- lm(data=hurst.behavior, scale(eeg.BestError_DelayAll_diff, scale=T, center=T) ~  rest.hurst.ACC_cent+ rest.hurst.ACC_diff_cent + scale(invage.y, scale=T, center=T))
summary(acch_mgsacc)

acch_mgsaccsd <- lm(data=hurst.behavior, eeg.BestError_sd_DelayAll_diff ~  rest.hurst.ACC_cent+ rest.hurst.ACC_diff_cent + invage.y)
summary(acch_mgsaccsd)

acch_mgsaccsd <- lm(data=hurst.behavior, scale(eeg.BestError_sd_DelayAll_diff, scale=T, center=T) ~  rest.hurst.ACC_cent+ rest.hurst.ACC_diff_cent + scale(invage.y, scale=T, center=T))
summary(acch_mgsaccsd)

acch_mgslat <- lm(data=hurst.behavior, eeg.mgsLatency_DelayAll_diff ~  rest.hurst.ACC_cent + rest.hurst.ACC_diff_cent + invage.y)
summary(acch_mgslat)

acch_mgslat <- lm(data=hurst.behavior, scale(eeg.mgsLatency_DelayAll_diff, scale=T, center=T) ~  rest.hurst.ACC_cent+ rest.hurst.ACC_diff_cent + scale(invage.y, scale=T, center=T))
summary(acch_mgslat)
count(acch_mgslat$model)

acch_mgslatsd <- lm(data=hurst.behavior, scale(eeg.mgsLatency_sd_DelayAll_diff, scale=T, center=T) ~  rest.hurst.ACC_cent + rest.hurst.ACC_diff_cent + scale(invage.y, scale=T, center=T))
summary(acch_mgslatsd)
count(acch_mgslatsd$model)

acch_anticorlat <- lm(data=hurst.behavior, scale(antiET.cor.lat_diff, scale=T, center=T) ~  rest.hurst.ACC_cent + rest.hurst.ACC_diff_cent + scale(invage.y, scale=T, center=T))
summary(acch_anticorlat)
count(acch_anticorlat$model)

acch_antipctcorr <- lm(data=hurst.behavior, scale(antiET.PctCorr_diff, scale=T, center=T) ~  rest.hurst.ACC_cent + rest.hurst.ACC_diff_cent + scale(invage.y, scale=T, center=T))
summary(acch_antipctcorr)
count(acch_antipctcorr$model)


#### 5.1.2 - Cog and Glu/GABA Ratio ----

#### 5.1.3 Cog and Glu/GABA Mismatch ----

#dlpfc -- something going wrong here! need to fix tomorrow. we have 44 visit 2 meanMismatches but for some reason it's not figuring that out and I end up with 17
sipfc <- sipfc %>% dplyr::select(lunaid, visitno, meanMismatch, LatMis)

# now calculate the difference score
sipfc_diff <- sipfc %>% 
  
  # diff across sessions: make 'husrt.rest.ROI_diff' columns for each roi (and only within each lunaid) 
  group_by(lunaid) %>% 
  mutate(across(matches('meanMismatch|LatMis'), function(x) x-lead(x), .names = "{.col}_diff")) %>% 
  
  # only 1 row per lunaid, pick row ranked first (whatever visit has data)
  filter(rank(visitno)<2)

scale_vec <- function(x) as.vector(scale(x, scale=T, center=T))

sipfc_centered <- sipfc_diff %>% 
  ungroup %>%
  mutate(across(starts_with('mean'), scale_vec, .names = "{.col}_cent"))

# merge sipfc and behavior
sipfc.behavior <- merge(sipfc_centered, per_visits_df, by="lunaid", all=T)

# for all other rois -- calculate the difference score
sipfc_diff <- sipfc %>% 
  
  # diff across sessions: make 'husrt.rest.ROI_diff' columns for each roi (and only within each lunaid) 
  group_by(lunaid) %>% 
  mutate(across(matches('*_GluGABAMismatch'), function(x) x-lead(x), .names = "{.col}_diff")) %>% 
  
  # only 1 row per lunaid, pick row ranked first (whatever visit has data)
  filter(rank(visitno)<2)

scale_vec <- function(x) as.vector(scale(x, scale=T, center=T))

sipfc_centered <- sipfc_diff %>% 
  ungroup %>%
  mutate(across(starts_with('sipfc.'), scale_vec, .names = "{.col}_cent"))

# merge sipfc and behavior
sipfc.behavior <- merge(sipfc_centered, per_visits_df, by="lunaid", all=T)

# testing
rdlpfcmrs_mgsacc <- lm(data=sipfc.behavior, scale(eeg.BestError_DelayAll_diff, scale=T, center=T) ~  sipfc.RDLPFC_GluGABAMismatch_cent+ sipfc.RDLPFC_GluGABAMismatch_diff_cent + scale(invage.y, center = T, scale = T))
summary(rdlpfcmrs_mgsacc)
count(rdlpfcmrs_mgsacc$model)

ldlpfcmrs_mgsacc <- lm(data=sipfc.behavior, scale(eeg.BestError_DelayAll_diff, scale=T, center=T) ~  sipfc.LDLPFC_GluGABAMismatch_cent+ sipfc.LDLPFC_GluGABAMismatch_diff_cent + scale(invage.y, center = T, scale = T))
summary(ldlpfcmrs_mgsacc)
count(ldlpfcmrs_mgsacc$model)




# ACC MRSI Mismatch
accmrs_mgsacc <- lm(data=sipfc.behavior, scale(eeg.BestError_DelayAll_diff, scale=T, center=T) ~  sipfc.ACC_GluGABAMismatch_cent+ sipfc.ACC_GluGABAMismatch_diff_cent + scale(invage.y, center = T, scale = T))
summary(accmrs_mgsacc)
count(accmrs_mgsacc$model)

accmrs_mgsaccsd <- lm(data=sipfc.behavior, scale(eeg.BestError_sd_DelayAll_diff, scale=T, center=T) ~  sipfc.ACC_GluGABAMismatch_cent+ sipfc.ACC_GluGABAMismatch_diff_cent + scale(invage.y, center = T, scale = T))
summary(accmrs_mgsaccsd)
count(accmrs_mgsaccsd$model)

accmrs_mgslat <- lm(data=sipfc.behavior, scale(eeg.mgsLatency_DelayAll, scale=T, center=T) ~  sipfc.ACC_GluGABAMismatch_cent+ sipfc.ACC_GluGABAMismatch_diff_cent + scale(invage.y, center = T, scale = T))
summary(accmrs_mgslat)
count(accmrs_mgslat$model)

accmrs_mgslatsd <- lm(data=sipfc.behavior, scale(eeg.mgsLatency_sd_DelayAll, scale=T, center=T) ~  sipfc.ACC_GluGABAMismatch_cent+ sipfc.ACC_GluGABAMismatch_diff_cent + scale(invage.y, center = T, scale = T))
summary(accmrs_mgslatsd)
count(accmrs_mgslatsd$model)

accmrs_anticorlat <- lm(data=sipfc.behavior, scale(antiET.cor.lat_diff, scale=T, center=T) ~  sipfc.ACC_GluGABAMismatch_cent + sipfc.ACC_GluGABAMismatch_diff_cent + scale(invage.y, scale=T, center=T))
summary(accmrs_anticorlat)
count(accmrs_anticorlat$model)

accmrs_antipctcorr <- lm(data=sipfc.behavior, scale(antiET.PctCorr_diff, scale=T, center=T) ~  sipfc.ACC_GluGABAMismatch_cent + sipfc.ACC_GluGABAMismatch_diff_cent + scale(invage.y, scale=T, center=T))
summary(accmrs_antipctcorr)
count(accmrs_antipctcorr$model)

# mPFC MRSI Mismatch
MPFCmrs_mgsacc <- lm(data=sipfc.behavior, scale(eeg.BestError_DelayAll_diff, scale=T, center=T) ~  sipfc.MPFC_GluGABAMismatch_cent+ sipfc.MPFC_GluGABAMismatch_diff_cent + scale(invage.y, center = T, scale = T))
summary(MPFCmrs_mgsacc)
count(MPFCmrs_mgsacc$model)

MPFCmrs_mgsaccsd <- lm(data=sipfc.behavior, scale(eeg.BestError_sd_DelayAll_diff, scale=T, center=T) ~  sipfc.MPFC_GluGABAMismatch_cent+ sipfc.MPFC_GluGABAMismatch_diff_cent + scale(invage.y, center = T, scale = T))
summary(MPFCmrs_mgsaccsd)
count(MPFCmrs_mgsaccsd$model)

MPFCmrs_mgslat <- lm(data=sipfc.behavior, scale(eeg.mgsLatency_DelayAll, scale=T, center=T) ~  sipfc.MPFC_GluGABAMismatch_cent+ sipfc.MPFC_GluGABAMismatch_diff_cent + scale(invage.y, center = T, scale = T))
summary(MPFCmrs_mgslat)
count(MPFCmrs_mgslat$model)

MPFCmrs_mgslatsd <- lm(data=sipfc.behavior, scale(eeg.mgsLatency_sd_DelayAll, scale=T, center=T) ~  sipfc.MPFC_GluGABAMismatch_cent+ sipfc.MPFC_GluGABAMismatch_diff_cent + scale(invage.y, center = T, scale = T))
summary(MPFCmrs_mgslatsd)
count(MPFCmrs_mgslatsd$model)

MPFCmrs_anticorlat <- lm(data=sipfc.behavior, scale(antiET.cor.lat_diff, scale=T, center=T) ~  sipfc.MPFC_GluGABAMismatch_cent + sipfc.MPFC_GluGABAMismatch_diff_cent + scale(invage.y, scale=T, center=T))
summary(MPFCmrs_anticorlat)
count(MPFCmrs_anticorlat$model)

MPFCmrs_antipctcorr <- lm(data=sipfc.behavior, scale(antiET.PctCorr_diff, scale=T, center=T) ~  sipfc.MPFC_GluGABAMismatch_cent + sipfc.MPFC_GluGABAMismatch_diff_cent + scale(invage.y, scale=T, center=T))
summary(MPFCmrs_antipctcorr)
count(MPFCmrs_antipctcorr$model)

# DLPFC Mismatch
dlpfcmrs_mgsacc <- lm(data=sipfc.behavior, scale(eeg.BestError_DelayAll_diff, scale=T, center=T) ~  meanMismatch_cent + meanMismatch_diff_cent + scale(invage.y, center = T, scale = T) + scale(LatMis_diff, center=T, scale=T))
summary(dlpfcmrs_mgsacc)
count(dlpfcmrs_mgsacc$model)


## 5.2 Aim 3B: ADI and E/I and cognition ----



