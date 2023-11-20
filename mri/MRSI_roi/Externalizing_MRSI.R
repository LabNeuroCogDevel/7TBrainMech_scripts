merge7T <- read.csv('/Volumes/Hera/Projects/7TBrainMech/scripts/txt/merged_7t.csv')

#1.0 Externalizing ~ age and sex####
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

##1.1 YSR externalizing ~ age and sex####
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

##1.2 ASR externalizing ~ age and sex####
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


#2.0 Metabolites ~ externalizing####

##2.1 merge7T####
###a. NAA####
merge7T<- merge7T %>% 
  mutate(NAA_ACC_z=scale(sipfc.ACC_NAA_gamadj, center=T, scale=T),
         NAA_MPFC_z=scale(sipfc.MPFC_NAA_gamadj, center=T, scale=T),
         NAA_DLPFC_z=scale(sipfc.DLPFC_NAA_gamadj, center=T, scale=T),
         NAA_RDLPFC_z=scale(sipfc.RDLPFC_NAA_gamadj, center=T, scale=T),
         NAA_LDLPFC_z=scale(sipfc.LDLPFC_NAA_gamadj, center=T, scale=T),
         externalizing_probs_z=scale(sr.externalizing_probs_T, center=T, scale=T))

ext_NAA_ACC_z <- lmer(data=merge7T, externalizing_probs_z ~ NAA_ACC_z + sex + (1|lunaid))
summary(ext_NAA_ACC_z)
ext_NAA_MPFC_z <- lmer(data=merge7T, externalizing_probs_z ~ NAA_MPFC_z + sex + (1|lunaid))
summary(ext_NAA_MPFC_z)
ext_NAA_DLPFC_z <- lmer(data=merge7T, externalizing_probs_z ~ NAA_DLPFC_z + sex + (1|lunaid))
summary(ext_NAA_DLPFC_z)
ext_NAA_RDLPFC_z <- lmer(data=merge7T, externalizing_probs_z ~ NAA_RDLPFC_z + sex + (1|lunaid))
summary(ext_NAA_RDLPFC_z)
ext_NAA_LDLPFC_z <- lmer(data=merge7t, externalizing_probs_z ~ NAA_LDLPFC_z + sex + (1|lunaid))
summary(ext_NAA_LDLPFC_z)

#NAA ACC#
#sex#
ext_NAA_ACC <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.ACC_NAA_gamadj + sex + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.ACC_NAA_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA ACC") + ylab("Externalizing")
summary(ext_NAA_ACC)
#age#
ext_NAA_ACC_age <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.ACC_NAA_gamadj + rest.age + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.ACC_NAA_gamadj, y=sr.externalizing_probs_T) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("NAA ACC") + ylab("Externalizing")
summary(ext_NAA_ACC_age)
#age interaction#
ext_NAA_ACC_age_int <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.ACC_NAA_gamadj * rest.age + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.ACC_NAA_gamadj, y=sr.externalizing_probs_T) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("NAA ACC") + ylab("Externalizing")
summary(ext_NAA_ACC_age_int)

#NAA MPFC#
#sex#
ext_NAA_MPFC <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.MPFC_NAA_gamadj + sex + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.MPFC_NAA_gamadj,y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA MPFC") + ylab("Externalizing")
summary(ext_NAA_MPFC)
#age#
ext_NAA_MPFC_age <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.MPFC_NAA_gamadj + rest.age + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.MPFC_NAA_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA MPFC") + ylab("Externalizing")
summary(ext_NAA_MPFC_age)
#age interaction#
ext_NAA_MPFC_age_int <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.MPFC_NAA_gamadj * rest.age + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.MPFC_NAA_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA MPFC") + ylab("Externalizing")
summary(ext_NAA_MPFC_age_int)

#NAA DLPFC#
#sex#
ext_NAA_DLPFC <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.DLPFC_NAA_gamadj + sex + (1|lunaid))
ggplot(data=merge7T)+aes(x=y=sipfc.DLPFC_NAA_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA DLPFC") + ylab("Externalizing")
summary(ext_NAA_DLPFC)
#age#
ext_NAA_DLPFC_age <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.DLPFC_NAA_gamadj + rest.age + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.DLPFC_NAA_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA DLPFC") + ylab("Externalizing")
summary(ext_NAA_DLPFC_age)
#age interaction#
ext_NAA_DLPFC_age_int <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.DLPFC_NAA_gamadj * rest.age + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.DLPFC_NAA_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA DLPFC") + ylab("Externalizing")
summary(ext_NAA_DLPFC_age_int)

#NAA RDLPFC#
#sex#
ext_NAA_RDLPFC <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.RDLPFC_NAA_gamadj + sex + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.RDLPFC_NAA_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA RDLPFC") + ylab("NAA Externalizing")
summary(ext_NAA_RDLPFC)
#age#
ext_NAA_RDLPFC_age <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.RDLPFC_NAA_gamadj + rest.age + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.RDLPFC_NAA_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA RDLPFC") + ylab("NAA Externalizing")
summary(ext_NAA_RDLPFC_age)
#age interaction#
ext_NAA_RDLPFC_age_int <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.RDLPFC_NAA_gamadj * rest.age + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.RDLPFC_NAA_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA RDLPFC") + ylab("NAA Externalizing")
summary(ext_NAA_RDLPFC_age_int)

#NAA LDLPFC#
#sex#
ext_NAA_LDLPFC <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.LDLPFC_NAA_gamadj + sex + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.LDLPFC_NAA_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA LDLPFC") + ylab("Externalizing")
summary(ext_NAA_LDLPFC)
#age#
ext_NAA_LDLPFC_age <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.LDLPFC_NAA_gamadj + rest.age + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.LDLPFC_NAA_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA LDLPFC") + ylab("Externalizing")
summary(ext_NAA_LDLPFC_age)
#age interaction#
ext_NAA_LDLPFC_age_int <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.LDLPFC_NAA_gamadj * rest.age + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.LDLPFC_NAA_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA LDLPFC") + ylab("Externalizing")
summary(ext_NAA_LDLPFC_age_int)

###b. mI####
data<- data %>% 
  mutate(mI_ACC_z=scale(sipfc.ACC_mI_gamadj, center=T, scale=T),
         mI_MPFC_z=scale(sipfc.MPFC_mI_gamadj, center=T, scale=T),
         mI_DLPFC_z=scale(sipfc.DLPFC_mI_gamadj, center=T, scale=T),
         mI_RDLPFC_z=scale(sipfc.RDLPFC_mI_gamadj, center=T, scale=T),
         mI_LDLPFC_z=scale(sipfc.LDLPFC_mI_gamadj, center=T, scale=T),
         externalizing_probs_z=scale(sr.externalizing_probs_T, center=T, scale=T))

ext_mI_ACC_z <- lmer(data=merge7T, externalizing_probs_z ~ mI_ACC_z + sex + (1|lunaid))
summary(ext_mI_ACC_z)
ext_mI_MPFC_z <- lmer(data=merge7T, externalizing_probs_z ~ mI_MPFC_z + sex + (1|lunaid))
summary(ext_mI_MPFC_z)
ext_mI_DLPFC_z <- lmer(data=merge7T, externalizing_probs_z ~ mI_DLPFC_z + sex + (1|lunaid))
summary(ext_mI_DLPFC_z)
ext_mI_RDLPFC_z <- lmer(data=merge7T, externalizing_probs_z ~ mI_RDLPFC_z + sex + (1|lunaid))
summary(ext_mI_RDLPFC_z)
ext_mI_LDLPFC_z <- lmer(data=merge7T, externalizing_probs_z ~ mI_LDLPFC_z + sex + (1|lunaid))
summary(ext_mI_LDLPFC_z)

#mI ACC#
#sex#
ext_mI_ACC <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.ACC_mI_gamadj + sex + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.ACC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("mI ACC") + ylab("Externalizing")
summary(ext_mI_ACC)
#age#
ext_mI_ACC_age <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.ACC_mI_gamadj + rest.age + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.ACC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("mI ACC") + ylab("Externalizing")
summary(ext_mI_ACC_age)
#age interaction
ext_mI_ACC_age_int <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.ACC_mI_gamadj * rest.age + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.ACC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("mI ACC") + ylab("Externalizing")
summary(ext_mI_ACC_age_int)

#mI MPFC#
#sex#
ext_mI_MPFC <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.MPFC_mI_gamadj + sex + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.MPFC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("mI MPFC") + ylab("Externalizing")
summary(ext_mI_MPFC)
#age#
ext_mI_MPFC_age <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.MPFC_mI_gamadj + rest.age + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.MPFC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("mI MPFC") + ylab("Externalizing")
summary(ext_mI_MPFC_age)
#age interaction#
ext_mI_MPFC_age_int <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.MPFC_mI_gamadj * rest.age + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.MPFC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("mI MPFC") + ylab("Externalizing")
summary(ext_mI_MPFC_age_int)

#mI DLPFC#
#sex#
ext_mI_DLPFC <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.DLPFC_mI_gamadj + sex + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.DLPFC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("mI DLPFC") + ylab("Externalizing")
summary(ext_mI_DLPFC)
#age#
ext_mI_DLPFC_age <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.DLPFC_mI_gamadj + rest.age + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.DLPFC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("mI DLPFC") + ylab("Externalizing")
summary(ext_mI_DLPFC_age)
#age interaction
ext_mI_DLPFC_age_int <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.DLPFC_mI_gamadj * rest.age + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.DLPFC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("mI DLPFC") + ylab("Externalizing")
summary(ext_mI_DLPFC_age_int)

#mI RDLPFC#
#sex#
ext_mI_RDLPFC <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.RDLPFC_mI_gamadj + sex + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.RDLPFC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("mI RDLPFC") + ylab("Externalizing")
summary(ext_mI_RDLPFC)
#age#
ext_mI_RDLPFC_age <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.RDLPFC_mI_gamadj + rest.age + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.RDLPFC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("mI RDLPFC") + ylab("Externalizing")
summary(ext_mI_RDLPFC_age)
#age interaction#
ext_mI_RDLPFC_age_int <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.RDLPFC_mI_gamadj * rest.age + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.RDLPFC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("mI RDLPFC") + ylab("Externalizing")
summary(ext_mI_RDLPFC_age_int)

#mI LDLPFC#
#sex#
ext_mI_LDLPFC <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.LDLPFC_mI_gamadj + sex + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.LDLPFC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("mI LDLPFC") + ylab("Externalizing")
summary(ext_mI_LDLPFC)
#age#
ext_mI_LDLPFC_age <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.LDLPFC_mI_gamadj + rest.age + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.LDLPFC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("mI LDLPFC") + ylab("Externalizing")
summary(ext_mI_LDLPFC_age)
#age interaction#
ext_mI_LDLPFC_age_int <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.LDLPFC_mI_gamadj * rest.age + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.LDLPFC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("mI LDLPFC") + ylab("Externalizing")
summary(ext_mI_LDLPFC_age_int)

###c. GSH####
data<- data %>% 
  mutate(GSH_ACC_z=scale(sipfc.ACC_GSH_gamadj, center=T, scale=T),
         GSH_MPFC_z=scale(sipfc.MPFC_GSH_gamadj, center=T, scale=T),
         GSH_DLPFC_z=scale(sipfc.DLPFC_GSH_gamadj, center=T, scale=T),
         GSH_RDLPFC_z=scale(sipfc.RDLPFC_GSH_gamadj, center=T, scale=T),
         GSH_LDLPFC_z=scale(sipfc.LDLPFC_GSH_gamadj, center=T, scale=T),
         externalizing_probs_z=scale(sr.externalizing_probs_T, center=T, scale=T))

ext_GSH_ACC_z <- lmer(data=merge7T, externalizing_probs_z ~ GSH_ACC_z + sex + (1|lunaid))
summary(ext_GSH_ACC_z)
ext_GSH_MPFC_z <- lmer(data=merge7T, externalizing_probs_z ~ GSH_MPFC_z + sex + (1|lunaid))
summary(ext_GSH_MPFC_z)
ext_GSH_DLPFC_z <- lmer(data=merge7T, externalizing_probs_z ~ GSH_DLPFC_z + sex + (1|lunaid))
summary(ext_GSH_DLPFC_z)
ext_GSH_RDLPFC_z <- lmer(data=merge7T, externalizing_probs_z ~ GSH_RDLPFC_z + sex + (1|lunaid))
summary(ext_GSH_RDLPFC_z)
ext_GSH_LDLPFC_z <- lmer(data=merge7T, externalizing_probs_z ~ GSH_LDLPFC_z + sex + (1|lunaid))
summary(ext_GSH_LDLPFC_z)

#GSH ACC#
#sex#
ext_GSH_ACC <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.ACC_GSH_gamadj + sex + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.ACC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("GSH ACC") + ylab("Externalizing")
summary(ext_GSH_ACC)
#age#
ext_GSH_ACC_age <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.ACC_GSH_gamadj + rest.age + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.ACC_GSH_gamadj, y=sr.externalizing_probs_T) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("GSH ACC") + ylab("Externalizing")
summary(ext_GSH_ACC_age)
#age interaction#
ext_GSH_ACC_age_int <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.ACC_GSH_gamadj * rest.age + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.ACC_GSH_gamadj, y=sr.externalizing_probs_T) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("GSH ACC") + ylab("Externalizing")
summary(ext_GSH_ACC_age_int)

#GSH MPFC#
#sex#
ext_GSH_MPFC <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.MPFC_GSH_gamadj + sex + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.MPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("GSH MPFC") + ylab("Externalizing")
summary(ext_GSH_MPFC)
#age#
ext_GSH_MPFC_age <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.MPFC_GSH_gamadj + rest.age + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.MPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("GSH MPFC") + ylab("Externalizing")
summary(ext_GSH_MPFC_age)
#age interaction#
ext_GSH_MPFC_age_int <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.MPFC_GSH_gamadj * rest.age + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.MPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("GSH MPFC") + ylab("Externalizing")
summary(ext_GSH_MPFC_age_int)

#GSH DLPFC#
#sex#
ext_GSH_DLPFC <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.DLPFC_GSH_gamadj + sex + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.DLPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("GSH DLPFC") + ylab("Externalizing")
summary(ext_GSH_DLPFC)
#age#
ext_GSH_DLPFC_age <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.DLPFC_GSH_gamadj + rest.age + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.DLPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("GSH DLPFC") + ylab("Externalizing")
summary(ext_GSH_DLPFC_age)
#age interaction#
ext_GSH_DLPFC_age_int <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.DLPFC_GSH_gamadj * rest.age + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.DLPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("GSH DLPFC") + ylab("Externalizing")
summary(ext_GSH_DLPFC_age_int)

#GSH RDLPFC#
#sex#
ext_GSH_RDLPFC <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.RDLPFC_GSH_gamadj + sex + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.RDLPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("GSH RDLPFC") + ylab("Externalizing")
summary(ext_GSH_RDLPFC)
#age#
ext_GSH_RDLPFC_age <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.RDLPFC_GSH_gamadj + rest.age + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.RDLPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("GSH RDLPFC") + ylab("Externalizing")
summary(ext_GSH_RDLPFC_age)
#age interaction#
ext_GSH_RDLPFC_age_int <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.RDLPFC_GSH_gamadj * rest.age + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.RDLPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("GSH RDLPFC") + ylab("Externalizing")
summary(ext_GSH_RDLPFC_age_int)

#GSH LDLPFC#
#sex#
ext_GSH_LDLPFC <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.LDLPFC_GSH_gamadj + sex + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.LDLPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("GSH LDLPC") + ylab("Externalizing")
summary(ext_GSH_LDLPFC)
#age#
ext_GSH_LDLPFC_age <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.LDLPFC_GSH_gamadj + rest.age + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.LDLPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("GSH LDLPC") + ylab("Externalizing")
summary(ext_GSH_LDLPFC_age)
#age interaction#
ext_GSH_LDLPFC_age_int <- lmer(data=merge7T, sr.externalizing_probs_T ~ sipfc.LDLPFC_GSH_gamadj * rest.age + (1|lunaid))
ggplot(data=merge7T)+aes(x=sipfc.LDLPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("GSH LDLPC") + ylab("Externalizing")
summary(ext_GSH_LDLPFC_age_int)


##2.2 YSR####
###a. NAA####
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
#sex#
ext_NAA_ACC <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.ACC_NAA_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.ACC_NAA_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA ACC") + ylab("Externalizing")
summary(ext_NAA_ACC)
#age#
ext_NAA_ACC_age <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.ACC_NAA_gamadj + rest.age + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.ACC_NAA_gamadj, y=sr.externalizing_probs_T) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("NAA ACC") + ylab("Externalizing")
summary(ext_NAA_ACC_age)
#age interaction#
ext_NAA_ACC_age_int <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.ACC_NAA_gamadj * rest.age + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.ACC_NAA_gamadj, y=sr.externalizing_probs_T) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("NAA ACC") + ylab("Externalizing")
summary(ext_NAA_ACC_age_int)

#NAA MPFC#
#sex#
ext_NAA_MPFC <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.MPFC_NAA_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.MPFC_NAA_gamadj,y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA MPFC") + ylab("Externalizing")
summary(ext_NAA_MPFC)
#age#
ext_NAA_MPFC_age <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.MPFC_NAA_gamadj + rest.age + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.MPFC_NAA_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA MPFC") + ylab("Externalizing")
summary(ext_NAA_MPFC_age)
#age interaction#
ext_NAA_MPFC_age_int <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.MPFC_NAA_gamadj * rest.age + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.MPFC_NAA_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA MPFC") + ylab("Externalizing")
summary(ext_NAA_MPFC_age_int)

#NAA DLPFC#
#sex#
ext_NAA_DLPFC <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.DLPFC_NAA_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=y=sipfc.DLPFC_NAA_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA DLPFC") + ylab("Externalizing")
summary(ext_NAA_DLPFC)
#age#
ext_NAA_DLPFC_age <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.DLPFC_NAA_gamadj + rest.age + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.DLPFC_NAA_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA DLPFC") + ylab("Externalizing")
summary(ext_NAA_DLPFC_age)
#age interaction#
ext_NAA_DLPFC_age_int <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.DLPFC_NAA_gamadj * rest.age + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.DLPFC_NAA_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA DLPFC") + ylab("Externalizing")
summary(ext_NAA_DLPFC_age_int)

#NAA RDLPFC#
#sex#
ext_NAA_RDLPFC <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.RDLPFC_NAA_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.RDLPFC_NAA_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA RDLPFC") + ylab("NAA Externalizing")
summary(ext_NAA_RDLPFC)
#age#
ext_NAA_RDLPFC_age <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.RDLPFC_NAA_gamadj + rest.age + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.RDLPFC_NAA_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA RDLPFC") + ylab("NAA Externalizing")
summary(ext_NAA_RDLPFC_age)
#age interaction#
ext_NAA_RDLPFC_age_int <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.RDLPFC_NAA_gamadj * rest.age + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.RDLPFC_NAA_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA RDLPFC") + ylab("NAA Externalizing")
summary(ext_NAA_RDLPFC_age_int)

#NAA LDLPFC#
#sex#
ext_NAA_LDLPFC <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.LDLPFC_NAA_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.LDLPFC_NAA_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA LDLPFC") + ylab("Externalizing")
summary(ext_NAA_LDLPFC)
#age#
ext_NAA_LDLPFC_age <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.LDLPFC_NAA_gamadj + rest.age + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.LDLPFC_NAA_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA LDLPFC") + ylab("Externalizing")
summary(ext_NAA_LDLPFC_age)
#age interaction#
ext_NAA_LDLPFC_age_int <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.LDLPFC_NAA_gamadj * rest.age + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.LDLPFC_NAA_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA LDLPFC") + ylab("Externalizing")
summary(ext_NAA_LDLPFC_age_int)

###b. mI####
data<- data %>% 
  mutate(mI_ACC_z=scale(sipfc.ACC_mI_gamadj, center=T, scale=T),
         mI_MPFC_z=scale(sipfc.MPFC_mI_gamadj, center=T, scale=T),
         mI_DLPFC_z=scale(sipfc.DLPFC_mI_gamadj, center=T, scale=T),
         mI_RDLPFC_z=scale(sipfc.RDLPFC_mI_gamadj, center=T, scale=T),
         mI_LDLPFC_z=scale(sipfc.LDLPFC_mI_gamadj, center=T, scale=T),
         externalizing_probs_z=scale(sr.externalizing_probs_T, center=T, scale=T))

ext_mI_ACC_z <- lmer(data=YSR_data, externalizing_probs_z ~ mI_ACC_z + sex + (1|lunaid))
summary(ext_mI_ACC_z)
ext_mI_MPFC_z <- lmer(data=YSR_data, externalizing_probs_z ~ mI_MPFC_z + sex + (1|lunaid))
summary(ext_mI_MPFC_z)
ext_mI_DLPFC_z <- lmer(data=YSR_data, externalizing_probs_z ~ mI_DLPFC_z + sex + (1|lunaid))
summary(ext_mI_DLPFC_z)
ext_mI_RDLPFC_z <- lmer(data=YSR_data, externalizing_probs_z ~ mI_RDLPFC_z + sex + (1|lunaid))
summary(ext_mI_RDLPFC_z)
ext_mI_LDLPFC_z <- lmer(data=YSR_data, externalizing_probs_z ~ mI_LDLPFC_z + sex + (1|lunaid))
summary(ext_mI_LDLPFC_z)

#mI ACC#
#sex#
ext_mI_ACC <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.ACC_mI_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.ACC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("mI ACC") + ylab("Externalizing")
summary(ext_mI_ACC)
#age#
ext_mI_ACC_age <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.ACC_mI_gamadj + rest.age + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.ACC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("mI ACC") + ylab("Externalizing")
summary(ext_mI_ACC_age)
#age interaction
ext_mI_ACC_age_int <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.ACC_mI_gamadj * rest.age + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.ACC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("mI ACC") + ylab("Externalizing")
summary(ext_mI_ACC_age_int)

#mI MPFC#
#sex#
ext_mI_MPFC <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.MPFC_mI_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.MPFC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("mI MPFC") + ylab("Externalizing")
summary(ext_mI_MPFC)
#age#
ext_mI_MPFC_age <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.MPFC_mI_gamadj + rest.age + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.MPFC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("mI MPFC") + ylab("Externalizing")
summary(ext_mI_MPFC_age)
#age interaction#
ext_mI_MPFC_age_int <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.MPFC_mI_gamadj * rest.age + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.MPFC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("mI MPFC") + ylab("Externalizing")
summary(ext_mI_MPFC_age_int)

#mI DLPFC#
#sex#
ext_mI_DLPFC <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.DLPFC_mI_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.DLPFC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("mI DLPFC") + ylab("Externalizing")
summary(ext_mI_DLPFC)
#age#
ext_mI_DLPFC_age <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.DLPFC_mI_gamadj + rest.age + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.DLPFC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("mI DLPFC") + ylab("Externalizing")
summary(ext_mI_DLPFC_age)
#age interaction
ext_mI_DLPFC_age_int <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.DLPFC_mI_gamadj * rest.age + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.DLPFC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("mI DLPFC") + ylab("Externalizing")
summary(ext_mI_DLPFC_age_int)

#mI RDLPFC#
#sex#
ext_mI_RDLPFC <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.RDLPFC_mI_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.RDLPFC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("mI RDLPFC") + ylab("Externalizing")
summary(ext_mI_RDLPFC)
#age#
ext_mI_RDLPFC_age <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.RDLPFC_mI_gamadj + rest.age + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.RDLPFC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("mI RDLPFC") + ylab("Externalizing")
summary(ext_mI_RDLPFC_age)
#age interaction#
ext_mI_RDLPFC_age_int <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.RDLPFC_mI_gamadj * rest.age + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.RDLPFC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("mI RDLPFC") + ylab("Externalizing")
summary(ext_mI_RDLPFC_age_int)

#mI LDLPFC#
#sex#
ext_mI_LDLPFC <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.LDLPFC_mI_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.LDLPFC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("mI LDLPFC") + ylab("Externalizing")
summary(ext_mI_LDLPFC)
#age#
ext_mI_LDLPFC_age <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.LDLPFC_mI_gamadj + rest.age + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.LDLPFC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("mI LDLPFC") + ylab("Externalizing")
summary(ext_mI_LDLPFC_age)
#age interaction#
ext_mI_LDLPFC_age_int <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.LDLPFC_mI_gamadj * rest.age + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.LDLPFC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("mI LDLPFC") + ylab("Externalizing")
summary(ext_mI_LDLPFC_age_int)

###c. GSH####
data<- data %>% 
  mutate(GSH_ACC_z=scale(sipfc.ACC_GSH_gamadj, center=T, scale=T),
         GSH_MPFC_z=scale(sipfc.MPFC_GSH_gamadj, center=T, scale=T),
         GSH_DLPFC_z=scale(sipfc.DLPFC_GSH_gamadj, center=T, scale=T),
         GSH_RDLPFC_z=scale(sipfc.RDLPFC_GSH_gamadj, center=T, scale=T),
         GSH_LDLPFC_z=scale(sipfc.LDLPFC_GSH_gamadj, center=T, scale=T),
         externalizing_probs_z=scale(sr.externalizing_probs_T, center=T, scale=T))

ext_GSH_ACC_z <- lmer(data=YSR_data, externalizing_probs_z ~ GSH_ACC_z + sex + (1|lunaid))
summary(ext_GSH_ACC_z)
ext_GSH_MPFC_z <- lmer(data=YSR_data, externalizing_probs_z ~ GSH_MPFC_z + sex + (1|lunaid))
summary(ext_GSH_MPFC_z)
ext_GSH_DLPFC_z <- lmer(data=YSR_data, externalizing_probs_z ~ GSH_DLPFC_z + sex + (1|lunaid))
summary(ext_GSH_DLPFC_z)
ext_GSH_RDLPFC_z <- lmer(data=YSR_data, externalizing_probs_z ~ GSH_RDLPFC_z + sex + (1|lunaid))
summary(ext_GSH_RDLPFC_z)
ext_GSH_LDLPFC_z <- lmer(data=YSR_data, externalizing_probs_z ~ GSH_LDLPFC_z + sex + (1|lunaid))
summary(ext_GSH_LDLPFC_z)

#GSH ACC#
#sex#
ext_GSH_ACC <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.ACC_GSH_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.ACC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("GSH ACC") + ylab("Externalizing")
summary(ext_GSH_ACC)
#age#
ext_GSH_ACC_age <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.ACC_GSH_gamadj + rest.age + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.ACC_GSH_gamadj, y=sr.externalizing_probs_T) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("GSH ACC") + ylab("Externalizing")
summary(ext_GSH_ACC_age)
#age interaction#
ext_GSH_ACC_age_int <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.ACC_GSH_gamadj * rest.age + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.ACC_GSH_gamadj, y=sr.externalizing_probs_T) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("GSH ACC") + ylab("Externalizing")
summary(ext_GSH_ACC_age_int)

#GSH MPFC#
#sex#
ext_GSH_MPFC <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.MPFC_GSH_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.MPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("GSH MPFC") + ylab("Externalizing")
summary(ext_GSH_MPFC)
#age#
ext_GSH_MPFC_age <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.MPFC_GSH_gamadj + rest.age + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.MPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("GSH MPFC") + ylab("Externalizing")
summary(ext_GSH_MPFC_age)
#age interaction#
ext_GSH_MPFC_age_int <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.MPFC_GSH_gamadj * rest.age + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.MPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("GSH MPFC") + ylab("Externalizing")
summary(ext_GSH_MPFC_age_int)

#GSH DLPFC#
#sex#
ext_GSH_DLPFC <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.DLPFC_GSH_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.DLPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("GSH DLPFC") + ylab("Externalizing")
summary(ext_GSH_DLPFC)
#age#
ext_GSH_DLPFC_age <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.DLPFC_GSH_gamadj + rest.age + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.DLPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("GSH DLPFC") + ylab("Externalizing")
summary(ext_GSH_DLPFC_age)
#age interaction#
ext_GSH_DLPFC_age_int <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.DLPFC_GSH_gamadj * rest.age + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.DLPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("GSH DLPFC") + ylab("Externalizing")
summary(ext_GSH_DLPFC_age_int)

#GSH RDLPFC#
#sex#
ext_GSH_RDLPFC <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.RDLPFC_GSH_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.RDLPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("GSH RDLPFC") + ylab("Externalizing")
summary(ext_GSH_RDLPFC)
#age#
ext_GSH_RDLPFC_age <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.RDLPFC_GSH_gamadj + rest.age + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.RDLPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("GSH RDLPFC") + ylab("Externalizing")
summary(ext_GSH_RDLPFC_age)
#age interaction#
ext_GSH_RDLPFC_age_int <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.RDLPFC_GSH_gamadj * rest.age + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.RDLPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("GSH RDLPFC") + ylab("Externalizing")
summary(ext_GSH_RDLPFC_age_int)

#GSH LDLPFC#
#sex#
ext_GSH_LDLPFC <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.LDLPFC_GSH_gamadj + sex + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.LDLPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("GSH LDLPC") + ylab("Externalizing")
summary(ext_GSH_LDLPFC)
#age#
ext_GSH_LDLPFC_age <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.LDLPFC_GSH_gamadj + rest.age + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.LDLPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("GSH LDLPC") + ylab("Externalizing")
summary(ext_GSH_LDLPFC_age)
#age interaction#
ext_GSH_LDLPFC_age_int <- lmer(data=YSR_data, sr.externalizing_probs_T ~ sipfc.LDLPFC_GSH_gamadj * rest.age + (1|lunaid))
ggplot(data=YSR_data)+aes(x=sipfc.LDLPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("GSH LDLPC") + ylab("Externalizing")
summary(ext_GSH_LDLPFC_age_int)


##2.3 ASR####
###a. NAA####
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
#sex#
ext_NAA_ACC <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.ACC_NAA_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.ACC_NAA_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA ACC") + ylab("Externalizing")
summary(ext_NAA_ACC)
#age#
ext_NAA_ACC_age <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.ACC_NAA_gamadj + rest.age + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.ACC_NAA_gamadj, y=sr.externalizing_probs_T) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("NAA ACC") + ylab("Externalizing")
summary(ext_NAA_ACC_age)
#age interaction#
ext_NAA_ACC_age_int <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.ACC_NAA_gamadj * rest.age + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.ACC_NAA_gamadj, y=sr.externalizing_probs_T) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("NAA ACC") + ylab("Externalizing")
summary(ext_NAA_ACC_age_int)

#NAA MPFC#
#sex#
ext_NAA_MPFC <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.MPFC_NAA_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.MPFC_NAA_gamadj,y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA MPFC") + ylab("Externalizing")
summary(ext_NAA_MPFC)
#age#
ext_NAA_MPFC_age <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.MPFC_NAA_gamadj + rest.age + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.MPFC_NAA_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA MPFC") + ylab("Externalizing")
summary(ext_NAA_MPFC_age)
#age interaction#
ext_NAA_MPFC_age_int <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.MPFC_NAA_gamadj * rest.age + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.MPFC_NAA_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA MPFC") + ylab("Externalizing")
summary(ext_NAA_MPFC_age_int)

#NAA DLPFC#
#sex#
ext_NAA_DLPFC <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.DLPFC_NAA_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=y=sipfc.DLPFC_NAA_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA DLPFC") + ylab("Externalizing")
summary(ext_NAA_DLPFC)
#age#
ext_NAA_DLPFC_age <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.DLPFC_NAA_gamadj + rest.age + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.DLPFC_NAA_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA DLPFC") + ylab("Externalizing")
summary(ext_NAA_DLPFC_age)
#age interaction#
ext_NAA_DLPFC_age_int <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.DLPFC_NAA_gamadj * rest.age + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.DLPFC_NAA_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA DLPFC") + ylab("Externalizing")
summary(ext_NAA_DLPFC_age_int)

#NAA RDLPFC#
#sex#
ext_NAA_RDLPFC <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.RDLPFC_NAA_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.RDLPFC_NAA_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA RDLPFC") + ylab("NAA Externalizing")
summary(ext_NAA_RDLPFC)
#age#
ext_NAA_RDLPFC_age <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.RDLPFC_NAA_gamadj + rest.age + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.RDLPFC_NAA_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA RDLPFC") + ylab("NAA Externalizing")
summary(ext_NAA_RDLPFC_age)
#age interaction#
ext_NAA_RDLPFC_age_int <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.RDLPFC_NAA_gamadj * rest.age + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.RDLPFC_NAA_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA RDLPFC") + ylab("NAA Externalizing")
summary(ext_NAA_RDLPFC_age_int)

#NAA LDLPFC#
#sex#
ext_NAA_LDLPFC <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.LDLPFC_NAA_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.LDLPFC_NAA_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA LDLPFC") + ylab("Externalizing")
summary(ext_NAA_LDLPFC)
#age#
ext_NAA_LDLPFC_age <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.LDLPFC_NAA_gamadj + rest.age + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.LDLPFC_NAA_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA LDLPFC") + ylab("Externalizing")
summary(ext_NAA_LDLPFC_age)
#age interaction#
ext_NAA_LDLPFC_age_int <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.LDLPFC_NAA_gamadj * rest.age + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.LDLPFC_NAA_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("NAA LDLPFC") + ylab("Externalizing")
summary(ext_NAA_LDLPFC_age_int)

###b. mI####
ASR_data<- ASR_data %>% 
  mutate(mI_ACC_z=scale(sipfc.ACC_mI_gamadj, center=T, scale=T),
         mI_MPFC_z=scale(sipfc.MPFC_mI_gamadj, center=T, scale=T),
         mI_DLPFC_z=scale(sipfc.DLPFC_mI_gamadj, center=T, scale=T),
         mI_RDLPFC_z=scale(sipfc.RDLPFC_mI_gamadj, center=T, scale=T),
         mI_LDLPFC_z=scale(sipfc.LDLPFC_mI_gamadj, center=T, scale=T),
         externalizing_probs_z=scale(sr.externalizing_probs_T, center=T, scale=T))

ext_mI_ACC_z <- lmer(data=ASR_data, externalizing_probs_z ~ mI_ACC_z + sex + (1|lunaid))
summary(ext_mI_ACC_z)
ext_mI_MPFC_z <- lmer(data=ASR_data, externalizing_probs_z ~ mI_MPFC_z + sex + (1|lunaid))
summary(ext_mI_MPFC_z)
ext_mI_DLPFC_z <- lmer(data=ASR_data, externalizing_probs_z ~ mI_DLPFC_z + sex + (1|lunaid))
summary(ext_mI_DLPFC_z)
ext_mI_RDLPFC_z <- lmer(data=ASR_data, externalizing_probs_z ~ mI_RDLPFC_z + sex + (1|lunaid))
summary(ext_mI_RDLPFC_z)
ext_mI_LDLPFC_z <- lmer(data=ASR_data, externalizing_probs_z ~ mI_LDLPFC_z + sex + (1|lunaid))
summary(ext_mI_LDLPFC_z)

#mI ACC#
#sex#
ext_mI_ACC <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.ACC_mI_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.ACC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("mI ACC") + ylab("Externalizing")
summary(ext_mI_ACC)
#age#
ext_mI_ACC_age <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.ACC_mI_gamadj + rest.age + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.ACC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("mI ACC") + ylab("Externalizing")
summary(ext_mI_ACC_age)
#age interaction
ext_mI_ACC_age_int <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.ACC_mI_gamadj * rest.age + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.ACC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("mI ACC") + ylab("Externalizing")
summary(ext_mI_ACC_age_int)

#mI MPFC#
#sex#
ext_mI_MPFC <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.MPFC_mI_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.MPFC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("mI MPFC") + ylab("Externalizing")
summary(ext_mI_MPFC)
#age#
ext_mI_MPFC_age <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.MPFC_mI_gamadj + rest.age + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.MPFC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("mI MPFC") + ylab("Externalizing")
summary(ext_mI_MPFC_age)
#age interaction#
ext_mI_MPFC_age_int <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.MPFC_mI_gamadj * rest.age + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.MPFC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("mI MPFC") + ylab("Externalizing")
summary(ext_mI_MPFC_age_int)

#mI DLPFC#
#sex#
ext_mI_DLPFC <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.DLPFC_mI_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.DLPFC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("mI DLPFC") + ylab("Externalizing")
summary(ext_mI_DLPFC)
#age#
ext_mI_DLPFC_age <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.DLPFC_mI_gamadj + rest.age + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.DLPFC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("mI DLPFC") + ylab("Externalizing")
summary(ext_mI_DLPFC_age)
#age interaction
ext_mI_DLPFC_age_int <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.DLPFC_mI_gamadj * rest.age + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.DLPFC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("mI DLPFC") + ylab("Externalizing")
summary(ext_mI_DLPFC_age_int)

#mI RDLPFC#
#sex#
ext_mI_RDLPFC <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.RDLPFC_mI_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.RDLPFC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("mI RDLPFC") + ylab("Externalizing")
summary(ext_mI_RDLPFC)
#age#
ext_mI_RDLPFC_age <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.RDLPFC_mI_gamadj + rest.age + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.RDLPFC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("mI RDLPFC") + ylab("Externalizing")
summary(ext_mI_RDLPFC_age)
#age interaction#
ext_mI_RDLPFC_age_int <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.RDLPFC_mI_gamadj * rest.age + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.RDLPFC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("mI RDLPFC") + ylab("Externalizing")
summary(ext_mI_RDLPFC_age_int)

#mI LDLPFC#
#sex#
ext_mI_LDLPFC <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.LDLPFC_mI_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.LDLPFC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("mI LDLPFC") + ylab("Externalizing")
summary(ext_mI_LDLPFC)
#age#
ext_mI_LDLPFC_age <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.LDLPFC_mI_gamadj + rest.age + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.LDLPFC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("mI LDLPFC") + ylab("Externalizing")
summary(ext_mI_LDLPFC_age)
#age interaction#
ext_mI_LDLPFC_age_int <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.LDLPFC_mI_gamadj * rest.age + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.LDLPFC_mI_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("mI LDLPFC") + ylab("Externalizing")
summary(ext_mI_LDLPFC_age_int)

###c. GSH####
ASR_data<- ASR_data %>% 
  mutate(GSH_ACC_z=scale(sipfc.ACC_GSH_gamadj, center=T, scale=T),
         GSH_MPFC_z=scale(sipfc.MPFC_GSH_gamadj, center=T, scale=T),
         GSH_DLPFC_z=scale(sipfc.DLPFC_GSH_gamadj, center=T, scale=T),
         GSH_RDLPFC_z=scale(sipfc.RDLPFC_GSH_gamadj, center=T, scale=T),
         GSH_LDLPFC_z=scale(sipfc.LDLPFC_GSH_gamadj, center=T, scale=T),
         externalizing_probs_z=scale(sr.externalizing_probs_T, center=T, scale=T))

ext_GSH_ACC_z <- lmer(data=ASR_data, externalizing_probs_z ~ GSH_ACC_z + sex + (1|lunaid))
summary(ext_GSH_ACC_z)
ext_GSH_MPFC_z <- lmer(data=ASR_data, externalizing_probs_z ~ GSH_MPFC_z + sex + (1|lunaid))
summary(ext_GSH_MPFC_z)
ext_GSH_DLPFC_z <- lmer(data=ASR_data, externalizing_probs_z ~ GSH_DLPFC_z + sex + (1|lunaid))
summary(ext_GSH_DLPFC_z)
ext_GSH_RDLPFC_z <- lmer(data=ASR_data, externalizing_probs_z ~ GSH_RDLPFC_z + sex + (1|lunaid))
summary(ext_GSH_RDLPFC_z)
ext_GSH_LDLPFC_z <- lmer(data=ASR_data, externalizing_probs_z ~ GSH_LDLPFC_z + sex + (1|lunaid))
summary(ext_GSH_LDLPFC_z)

#GSH ACC#
#sex#
ext_GSH_ACC <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.ACC_GSH_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.ACC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("GSH ACC") + ylab("Externalizing")
summary(ext_GSH_ACC)
#age#
ext_GSH_ACC_age <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.ACC_GSH_gamadj + rest.age + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.ACC_GSH_gamadj, y=sr.externalizing_probs_T) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("GSH ACC") + ylab("Externalizing")
summary(ext_GSH_ACC_age)
#age interaction#
ext_GSH_ACC_age_int <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.ACC_GSH_gamadj * rest.age + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.ACC_GSH_gamadj, y=sr.externalizing_probs_T) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("GSH ACC") + ylab("Externalizing")
summary(ext_GSH_ACC_age_int)

#GSH MPFC#
#sex#
ext_GSH_MPFC <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.MPFC_GSH_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.MPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("GSH MPFC") + ylab("Externalizing")
summary(ext_GSH_MPFC)
#age#
ext_GSH_MPFC_age <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.MPFC_GSH_gamadj + rest.age + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.MPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("GSH MPFC") + ylab("Externalizing")
summary(ext_GSH_MPFC_age)
#age interaction#
ext_GSH_MPFC_age_int <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.MPFC_GSH_gamadj * rest.age + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.MPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("GSH MPFC") + ylab("Externalizing")
summary(ext_GSH_MPFC_age_int)

#GSH DLPFC#
#sex#
ext_GSH_DLPFC <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.DLPFC_GSH_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.DLPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("GSH DLPFC") + ylab("Externalizing")
summary(ext_GSH_DLPFC)
#age#
ext_GSH_DLPFC_age <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.DLPFC_GSH_gamadj + rest.age + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.DLPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("GSH DLPFC") + ylab("Externalizing")
summary(ext_GSH_DLPFC_age)
#age interaction#
ext_GSH_DLPFC_age_int <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.DLPFC_GSH_gamadj * rest.age + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.DLPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("GSH DLPFC") + ylab("Externalizing")
summary(ext_GSH_DLPFC_age_int)

#GSH RDLPFC#
#sex#
ext_GSH_RDLPFC <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.RDLPFC_GSH_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.RDLPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("GSH RDLPFC") + ylab("Externalizing")
summary(ext_GSH_RDLPFC)
#age#
ext_GSH_RDLPFC_age <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.RDLPFC_GSH_gamadj + rest.age + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.RDLPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("GSH RDLPFC") + ylab("Externalizing")
summary(ext_GSH_RDLPFC_age)
#age interaction#
ext_GSH_RDLPFC_age_int <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.RDLPFC_GSH_gamadj * rest.age + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.RDLPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth(method = lm) + theme_classic(base_size=15) + xlab("GSH RDLPFC") + ylab("Externalizing")
summary(ext_GSH_RDLPFC_age_int)

#GSH LDLPFC#
#sex#
ext_GSH_LDLPFC <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.LDLPFC_GSH_gamadj + sex + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.LDLPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("GSH LDLPC") + ylab("Externalizing")
summary(ext_GSH_LDLPFC)
#age#
ext_GSH_LDLPFC_age <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.LDLPFC_GSH_gamadj + rest.age + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.LDLPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("GSH LDLPC") + ylab("Externalizing")
summary(ext_GSH_LDLPFC_age)
#age interaction#
ext_GSH_LDLPFC_age_int <- lmer(data=ASR_data, sr.externalizing_probs_T ~ sipfc.LDLPFC_GSH_gamadj * rest.age + (1|lunaid))
ggplot(data=ASR_data)+aes(x=sipfc.LDLPFC_GSH_gamadj, y=sr.externalizing_probs_T, color=sex) +geom_point() + stat_smooth() + theme_classic(base_size=15) + xlab("GSH LDLPC") + ylab("Externalizing")
summary(ext_GSH_LDLPFC_age_int)
