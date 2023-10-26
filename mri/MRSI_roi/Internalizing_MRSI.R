merge7T %>% select(sr.internalizing_probs_T,rest.age,sex,lunaid) %>% str
merge7T$sr.internalizing_probs_T <- as.numeric(merge7T$sr.internalizing_probs_T)

merge7t <- read.csv('/Volumes/Hera/Projects/7TBrainMech/scripts/txt/merged_7t.csv')

# remove eg. '-B' from asr/ysr _T values like '60-B', and make all columns numeric
merge7T <- merge7T %>% 
  mutate(across(matches('^sr.*T'), 
                function(x) gsub('-[A-Z]','',x) |>
                  as.numeric()))

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
