# Dissertation 7/24/23 M.I.P. ---- 

# 1.0 Load libraries ----
library(LNCDR)
library(tidyverse)
library(ggplot2)
library(lme4)
library(lmerTest)
library(corrplot)

# 2.0 Load data ----
# load in merge 7t 
merge7t <- read.csv('/Volumes/Hera/Projects/7TBrainMech/scripts/txt/merged_7t.csv')
# load in ADI data
ADI <- read.table('/home/maria/Desktop/Dissertation/Data/ADI.txt', header = TRUE)

# make smaller dataframe with only variables i need
merge7t <- merge7t %>%
  select(lunaid, visitno, rest.age, sess.age, sex, rest.fd, 
         matches('sipfc.*_(Glu|GABA)_gamadj'),
         matches('sipfc.*_all_GMrat'), 
         matches('hurst_*'))

# create age variables 
merge7t$invage <- 1/merge7t$sess.age
merge7t$quadage <- (merge7t$sess.age - mean(merge7t$sess.age, na.rm=T))^2

# create glu/gaba ratio variables 
merge7t$sipfc.ACC_GluGABARat <- merge7t$sipfc.ACC_Glu_gamadj/merge7t$sipfc.ACC_GABA_gamadj
merge7t$sipfc.MPFC_GluGABARat <- merge7t$sipfc.MPFC_Glu_gamadj/merge7t$sipfc.MPFC_GABA_gamadj
merge7t$sipfc.RDLPFC_GluGABARat <- merge7t$sipfc.RDLPFC_Glu_gamadj/merge7t$sipfc.RDLPFC_GABA_gamadj
merge7t$sipfc.LDLPFC_GluGABARat <- merge7t$sipfc.LDLPFC_Glu_gamadj/merge7t$sipfc.LDLPFC_GABA_gamadj

abs_scale <- function(x) abs(scale(x,center=T,scale=T))
na_above <- function(z, x=z, thres=3) ifelse(z>thres,NA,x)
na_z <- function(x) na_above(abs_scale(x), x)

merge7t<- merge7t %>% mutate(across(matches("GluGABARat"), na_z))

# make lunaid a factor 
merge7t$lunaid <- as.factor(merge7t$lunaid)
merge7t$sex<- as.factor(merge7t$sex)

# create glu/gaba mismatch variable 
merge7t$sipfc.ACC_GluGABAMismatch<- abs(residuals(lm(data=merge7t, sipfc.ACC_Glu_gamadj ~ sipfc.ACC_GABA_gamadj, na.action=na.exclude)))
merge7t$sipfc.MPFC_GluGABAMismatch<- abs(residuals(lm(data=merge7t, sipfc.MPFC_Glu_gamadj ~ sipfc.MPFC_GABA_gamadj, na.action=na.exclude)))
merge7t$sipfc.RDLPFC_GluGABAMismatch<- abs(residuals(lm(data=merge7t, sipfc.RDLPFC_Glu_gamadj ~ sipfc.RDLPFC_GABA_gamadj, na.action=na.exclude)))
merge7t$sipfc.LDLPFC_GluGABAMismatch<- abs(residuals(lm(data=merge7t, sipfc.LDLPFC_Glu_gamadj ~ sipfc.LDLPFC_GABA_gamadj, na.action=na.exclude)))

# demographics
temp <- dplyr::select(merge7t, rest.age, lunaid,visitno) #pull out id, age, visitnum
temp <- unique(temp) # should have one row per ID per visit
temp <- temp %>% drop_na(rest.age)
colnames(temp)[colnames(temp)=="lunaid"] <- "id" # the LNCD waterfall plot likes "id" and not "lunaid"
colnames(temp)[colnames(temp)=="rest.age"] <- "age" 
long_plot <- waterfall_plot(temp) #depending on whether you have LNCD package loaded in, you migh thave to go LNCDR::waterfall_plot
print(long_plot)

temp <- dplyr::select(merge7t, rest.age, lunaid,visitno, sex) #pull out id, age, visitnum
temp <- temp %>% drop_na(rest.age)
mean(temp$rest.age)
sd(temp$rest.age)

temp$sex <- as.factor(temp$sex)
temp <- temp %>% drop_na(rest.age)
temp %>% group_by(sex) %>% summarise(n=length(unique(lunaid)))

# 3.0 Aim 1: Characterize normative E/I development ----

## 3.1 MRSI: Glu/GABA Ratio ----

# DLPFC both hemispheres
dlpfc<- merge7t %>% select(lunaid, visitno, sess.age, sex, sipfc.LDLPFC_all_GMrat, sipfc.RDLPFC_all_GMrat, matches('sipfc.RDLPFC_(Glu|GABA)_gamadj'), matches('sipfc.LDLPFC_(Glu|GABA)_gamadj'))
dlpfc_long <- dlpfc %>%
  pivot_longer(matches('sipfc')) %>% 
  separate(name,c('src','roi','met','measure')) %>% 
  pivot_wider(names_from=c('measure','met'),values_from='value')
dlpfc_long$GGRat<- dlpfc_long$gamadj_Glu/dlpfc_long$gamadj_GABA

dlpfc_long<- dlpfc_long %>% mutate(across(matches("GGRat"), na_z))
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
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("DLPFC Glu/GABA Ratio") +
  geom_line(aes(group=paste(lunaid, roi))) 

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
ggplot(data=merge7t) + aes(x=sess.age, y=sipfc.ACC_GluGABARat, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("ACC Glu/GABA Ratio") +
  geom_line() 
# scaled model to find standardized effect sizes 
acc_ggrat_inv<- lmer(data=merge7t, scale(sipfc.ACC_GluGABARat, center = T, scale = T)~ scale(invage, center=T, scale = T) + sex + (1|lunaid))
summary(acc_ggrat_inv)

acc_ggrat_quad <- lmer(data=merge7t, sipfc.ACC_GluGABARat~ sess.age + quadage + sex + (1|lunaid))
summary(acc_ggrat_quad)

AIC(acc_ggrat_lin , acc_ggrat_inv, acc_ggrat_quad)

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
ggplot(data=merge7t) + aes(x=sess.age, y=sipfc.MPFC_GluGABARat, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("MPFC Glu/GABA Ratio") +
  geom_line() 

mpfc_ggrat_inv<- lmer(data=merge7t, sipfc.MPFC_GluGABARat~ invage * sex +  (1|lunaid))
summary(mpfc_ggrat_inv)

# scaled model to find standardized effect sizes 
mpfc_ggrat_inv<- lmer(data=merge7t, scale(sipfc.MPFC_GluGABARat, center = T, scale = T)~ scale(invage, center=T, scale = T) + sex + (1|lunaid))
summary(mpfc_ggrat_inv)

mpfc_ggrat_quad <- lmer(data=merge7t, sipfc.MPFC_GluGABARat~ sess.age + quadage + sex +  (1|lunaid))
summary(mpfc_ggrat_quad)

AIC(mpfc_ggrat_lin, mpfc_ggrat_inv, mpfc_ggrat_quad)

# bonferroni correct p vals 
p_ratio <- c(0.000013, 0.00028, 0.0035)
p.adjust(p_ratio, "bonferroni", n = length(p_ratio))

## 3.2 MRSI: Glu/GABA Mismatch ----
merge7t$sipfc.RDLPFC_GluGABAMismatch<- abs(residuals(lm(data=merge7t, sipfc.RDLPFC_Glu_gamadj ~ sipfc.RDLPFC_GABA_gamadj, na.action=na.exclude)))

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
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("DLPFC Glu/GABA Mismatch") +
  geom_line(aes(group=paste(lunaid, roi))) 

dlpfc_mismatch_inv <- lmer(data=dlpfc_long, mismatch~ invage * roi + sex  + (1|lunaid))
summary(dlpfc_mismatch_inv)

# scaled model to find standardized effect sizes 
dlpfc_mismatch_inv<- lmer(data=dlpfc_long, scale(mismatch, center = T, scale = T)~ scale(invage, center=T, scale = T) * roi + sex + (1|lunaid))
summary(dlpfc_mismatch_inv)

dlpfc_mismatch_quad <- lmer(data=dlpfc_long, mismatch~ sess.age + quadage + sex  + roi + (1|lunaid))
summary(dlpfc_mismatch_quad)

AIC(dlpfc_mismatch_lin , dlpfc_mismatch_inv, dlpfc_mismatch_quad)

# ACC
acc_mismatch_lin <- lmer(data=merge7t, sipfc.ACC_GluGABAMismatch~ sess.age + sex  + (1|lunaid))
summary(acc_mismatch_lin)
ggplot(data=merge7t) + aes(x=sess.age, y=sipfc.ACC_GluGABAMismatch, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("ACC Glu/GABA Mismatch") +
  geom_line() 

acc_mismatch_inv<- lmer(data=merge7t, sipfc.ACC_GluGABAMismatch~ invage + sex  + (1|lunaid))
summary(acc_mismatch_inv)
ggplot(data=merge7t) + aes(x=sess.age, y=sipfc.ACC_GluGABAMismatch, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("ACC Glu/GABA Mismatch") +
  geom_line() 
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
ggplot(data=merge7t) + aes(x=sess.age, y=sipfc.MPFC_GluGABAMismatch, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("MPFC Glu/GABA Mismatch") +
  geom_line() 
# scaled model to find standardized effect sizes 
mpfc_mismatch_inv<- lmer(data=merge7t, scale(sipfc.MPFC_GluGABAMismatch, center = T, scale = T)~ scale(invage, center=T, scale = T) + sex  + (1|lunaid))
summary(mpfc_mismatch_inv)

mpfc_mismatch_quad <- lmer(data=merge7t, sipfc.MPFC_GluGABAMismatch~ sess.age + quadage + sex  + (1|lunaid))
summary(mpfc_mismatch_quad)

AIC(mpfc_mismatch_lin , mpfc_mismatch_inv, mpfc_mismatch_quad)


## 3.3 Hurst ----

# DLPFC
# DLPFC both hemispheres
dlpfc_hurst<- merge7t %>% select(lunaid, visitno, sess.age, sex, hurst_brns.RDLPFC , hurst_brns.LDLPFC, rest.fd)
dlpfc_long <- dlpfc_hurst %>%
  pivot_longer(matches('hurst_brns')) %>% 
  separate(name,c("method","preproc","roi"), sep='[._]')
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
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("DLPFC Hurst  fd < 1") +
  geom_line(aes(group=paste(lunaid, roi)))


dlpfc_hurst_quad <- lmer(data=dlpfc_long  %>% filter(rest.fd < 1), value ~ sess.age + quadage + sex + roi+ rest.fd + (1|lunaid))
summary(dlpfc_hurst_quad)

AIC(dlpfc_hurst_age , dlpfc_hurst_invage, dlpfc_hurst_quad)

dlpfc_hurst_invage <- lmer(data=dlpfc_long  %>% filter(rest.fd < 1), scale(value, center=T, scale=T) ~ scale(invage, center=T, scale=T) + sex + scale(rest.fd, center=T, scale=T) + roi + (1|lunaid))
summary(dlpfc_hurst_invage)

#right dlpfc 
rdlpfc_hurst_age <- lmer(data=merge7t, hurst_brns.RDLPFC ~ sess.age + sex + rest.fd + (1|lunaid))
summary(rdlpfc_hurst_age)
ggplot(data=merge7t) + aes(x=sess.age, y=hurst_brns.RDLPFC, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("R DLPFC Hurst BRNS") +
  geom_line() 

rdlpfc_hurst_age <- lmer(data=merge7t %>% filter(rest.fd < 1), hurst_brns.RDLPFC ~ sess.age + sex + rest.fd + (1|lunaid))
summary(rdlpfc_hurst_age)
ggplot(data=merge7t %>% filter(rest.fd < 1)) + aes(x=sess.age, y=hurst_brns.RDLPFC, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("R DLPFC Hurst BRNS fd < 1") +
  geom_line() 

rdlpfc_hurst_invage <- lmer(data=merge7t, hurst_brns.RDLPFC ~ invage + sex + rest.fd + (1|lunaid))
summary(rdlpfc_hurst_invage)

AIC(rdlpfc_hurst_age , rdlpfc_hurst_invage)

# ldlpfc
ldlpfc_hurst_age <- lmer(data=merge7t, hurst_brns.LDLPFC ~ sess.age + sex + rest.fd + (1|lunaid))
summary(ldlpfc_hurst_age)
ggplot(data=merge7t) + aes(x=sess.age, y=hurst_brns.LDLPFC, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("L DLPFC Hurst BRNS") +
  geom_line() 

ldlpfc_hurst_age <- lmer(data=merge7t %>% filter(rest.fd < 1), hurst_brns.LDLPFC ~ sess.age + sex + rest.fd + (1|lunaid))
summary(ldlpfc_hurst_age)
ggplot(data=merge7t %>% filter(rest.fd < 1)) + aes(x=sess.age, y=hurst_brns.LDLPFC, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("L DLPFC Hurst BRNS fd < 1") +
  geom_line() 

ldlpfc_hurst_invage <- lmer(data=merge7t, hurst_brns.LDLPFC ~ invage + sex + rest.fd + (1|lunaid))
summary(ldlpfc_hurst_invage)

AIC(ldlpfc_hurst_age , ldlpfc_hurst_invage)

# ACC
acc_hurst_age <- lmer(data=merge7t, hurst_brns.ACC ~ sess.age + sex + rest.fd + (1|lunaid))
summary(acc_hurst_age)
ggplot(data=merge7t) + aes(x=sess.age, y=hurst_brns.ACC, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("ACC Hurst") +
  geom_line() 

acc_hurst_age <- lmer(data=merge7t %>% filter(rest.fd < 1), hurst_brns.ACC ~ sess.age + sex + rest.fd + (1|lunaid))
summary(acc_hurst_age)
ggplot(data=merge7t %>% filter(rest.fd < 1)) + aes(x=sess.age, y=hurst_brns.ACC, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("ACC Hurst  fd < 1") +
  geom_line() 

acc_hurst_invage <- lmer(data=merge7t %>% filter(rest.fd < 1), hurst_brns.ACC ~ invage + sex + rest.fd + (1|lunaid))
summary(acc_hurst_invage)
ggplot(data=merge7t %>% filter(rest.fd < 1)) + aes(x=sess.age, y=hurst_brns.ACC, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("ACC Hurst  fd < 1") +
  geom_line() 

acc_hurst_quad <- lmer(data=merge7t %>% filter(rest.fd < 1), hurst_brns.ACC ~ sess.age + quadage + sex + rest.fd + (1|lunaid))
summary(acc_hurst_quad)

AIC(acc_hurst_age , acc_hurst_invage, acc_hurst_quad)

acc_hurst_invage <- lmer(data=merge7t %>% filter(rest.fd < 1), scale(hurst_brns.ACC, center=T, scale=T) ~ scale(invage, center=T, scale=T) + sex + scale(rest.fd, center=T, scale=T) + (1|lunaid))
summary(acc_hurst_invage)

# MPFC
mpfc_hurst_age <- lmer(data=merge7t, hurst_brns.MPFC ~ sess.age + sex + rest.fd + (1|lunaid))
summary(mpfc_hurst_age)
ggplot(data=merge7t) + aes(x=sess.age, y=hurst_brns.MPFC, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("L DLPFC Hurst BRNS") +
  geom_line() 

mpfc_hurst_age <- lmer(data=merge7t %>% filter(rest.fd < 1), hurst_brns.MPFC ~ sess.age + sex + rest.fd + (1|lunaid))
summary(mpfc_hurst_age)
ggplot(data=merge7t %>% filter(rest.fd < 1)) + aes(x=sess.age, y=hurst_brns.MPFC, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("L DLPFC Hurst BRNS fd < 1") +
  geom_line() 

mpfc_hurst_invage <- lmer(data=merge7t %>% filter(rest.fd < 1), hurst_brns.MPFC ~ invage + sex + rest.fd + (1|lunaid))
summary(mpfc_hurst_invage)
ggplot(data=merge7t %>% filter(rest.fd < 1)) + aes(x=sess.age, y=hurst_brns.MPFC, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("MPFC Hurst  fd < 1") +
  geom_line() 

mpfc_hurst_quad <- lmer(data=merge7t %>% filter(rest.fd < 1), hurst_brns.MPFC ~ sess.age + quadage + sex + rest.fd + (1|lunaid))
summary(mpfc_hurst_quad)

AIC(mpfc_hurst_age , mpfc_hurst_invage, mpfc_hurst_quad)

mpfc_hurst_invage <- lmer(data=merge7t %>% filter(rest.fd < 1), scale(hurst_brns.MPFC, center=T, scale=T) ~ scale(invage, center=T, scale=T) + sex + scale(rest.fd, center=T, scale=T) + (1|lunaid))
summary(mpfc_hurst_invage)


## 3.4 Glu and GABA post-hoc ----
# ACC
# glu 
acc_glu_lin <- lmer(data=merge7t, sipfc.ACC_Glu_gamadj~ sess.age + sex + (1|lunaid))
summary(acc_glu_lin)
ggplot(data=merge7t) + aes(x=sess.age, y=sipfc.ACC_Glu_gamadj, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("ACC Glu") +
  geom_line() 

acc_glu_inv <- lmer(data=merge7t, sipfc.ACC_Glu_gamadj~ invage + sex + (1|lunaid))
summary(acc_glu_inv)
ggplot(data=merge7t) + aes(x=sess.age, y=sipfc.ACC_Glu_gamadj, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("ACC Glu/GABA Ratio") +
  geom_line() 

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

acc_gaba_quad <- lmer(data=merge7t, sipfc.ACC_GABA_gamadj~ sess.age + quadage + sex  + (1|lunaid))
summary(acc_gaba_quad)

AIC(acc_gaba_lin, acc_gaba_inv, acc_gaba_quad)

# scaled model to find standardized effect sizes 
acc_gaba_inv<- lmer(data=merge7t, scale(sipfc.ACC_GABA_gamadj, center = T, scale = T)~ scale(invage, center=T, scale = T) + sex  + (1|lunaid))
summary(acc_gaba_inv)

acc_gaba_inv<- lmer(data=merge7t, scale(sipfc.ACC_GABA_gamadj, center = T, scale = T)~ scale(invage, center=T, scale = T) * sex  + (1|lunaid))
summary(acc_gaba_inv)

# follow up age by sex interaction
acc_gaba_invF<- lmer(data=merge7t %>% filter(sex=="F"), scale(sipfc.ACC_GABA_gamadj, center = T, scale = T)~ scale(invage, center=T, scale = T) + (1|lunaid))
summary(acc_gaba_invF)

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

dlpfc_glu_inv <- lmer(data=dlpfc_long, gamadj_Glu~ invage * roi + sex  + (1|lunaid))
summary(dlpfc_glu_inv)

dlpfc_glu_quad <- lmer(data=dlpfc_long, gamadj_Glu~ sess.age + quadage + sex + roi  + (1|lunaid))
summary(dlpfc_glu_quad)

AIC(dlpfc_glu_lin, dlpfc_glu_inv, dlpfc_glu_quad)

rdlpfc_glu_inv <- lmer(data=merge7t, sipfc.RDLPFC_Glu_gamadj ~ invage + sex +(1|lunaid))
summary(rdlpfc_glu_inv)

ldlpfc_glu_inv <- lmer(data=merge7t, sipfc.LDLPFC_Glu_gamadj ~ invage + sex +  (1|lunaid))
summary(ldlpfc_glu_inv)

# scaled model to find standardized effect sizes 
dlpfc_glu_inv<- lmer(data=dlpfc_long, scale(gamadj_Glu, center = T, scale = T)~ scale(invage, center=T, scale = T) + sex + roi+ (1|lunaid))
summary(dlpfc_glu_inv)

dlpfc_glu_inv_int<- lmer(data=dlpfc_long, scale(gamadj_Glu, center = T, scale = T)~ scale(invage, center=T, scale = T) * roi + sex+  (1|lunaid))
summary(dlpfc_glu_inv_int)


## 3.5 MRSI and Hurst correlations ----
d <- merge7t %>% select(sess.age, rest.fd, lunaid, matches('sipfc|hurst_brns'))
d <- d %>% select(sess.age, rest.fd, lunaid, matches('DLPFC|MPFC|ACC'))
d <- d %>% select(-contains("GMrat"))
d <- d %>% rename_with(\(x) gsub('(hurst.*)','\\1_hurst',x))

## 3.5.1 simple cor
raw_cormat <- d %>% select(matches('sipfc|hurst')) %>% cor(use='pairwise.complete.obs')
corrplot(raw_cormat)

## 3.5.2 age regressed residual cor
long<- d %>% unique %>%
  pivot_longer(
    matches('hurst|sipfc'),
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
