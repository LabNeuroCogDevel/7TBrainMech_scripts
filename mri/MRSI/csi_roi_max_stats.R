#### 02082019 ####
# Stats on GABA:Cre, Glu:Cre, and Cre with age and gender

#### Data Cleaning ####
library(tidyr)
library(tidyverse)
library(lubridate)
library(ggplot2)

csi_roi_max_values<-read.table("/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI/csi_roi_max_values.txt")
names(csi_roi_max_values) <-c("Subject","DOB","Gender", "ROI","measure", "value" )
csi_roi_max_values<-spread(csi_roi_max_values, measure, value)

# split up the ID to calculate the age 
splitID_csi_roi_max_values<-csi_roi_max_values %>% separate(Subject,c("id","vdate")) %>% 
  mutate(vdate=ymd(vdate), DOB = ymd(DOB), age = round((vdate - DOB)/365.25), digits=0)

# get rid of subjects with no values for Cre 
cre_vals <- splitID_csi_roi_max_values %>%
  filter(Cre!= 0) 

#make text file of missing subjects for Will
nocre <- subset(splitID_csi_roi_max_values, grepl("0", splitID_csi_roi_max_values$Cre))
nocre <- splitID_csi_roi_max_values %>% filter(splitID_csi_roi_max_values$Cre == 0)
subj_nocre <- unique(nocre$id)
write.table(subj_nocre, file="/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI/missing_subjects.txt", quote=FALSE, row.names=FALSE, col.names=FALSE)

# individual roi dataframes
#ROI 3 - left dlpfc
ldlpfc <- subset(cre_vals, cre_vals$ROI==3)

#ROI 4 - right dlpfc
rdlpfc <- subset(cre_vals, cre_vals$ROI==4)

#ROI 6 - ACC
acc <- subset(cre_vals, cre_vals$ROI==6)

#ROI 7 - thalamus
thalamus <- subset(cre_vals, cre_vals$ROI==7)

#### ROI3 ####

#lm is YVAR~XVAR
ldlpfc_Cre_age <- lm(Cre~age, data=ldlpfc)
summary(ldlpfc_Cre_age)
ggplot(ldlpfc, aes(x=age, y=Cre)) + geom_point()

ldlpfc_GABA_age <- lm(GABA_Cre~age, data=ldlpfc)
summary(ldlpfc_GABA_age)
ggplot(ldlpfc, aes(x=age, y=GABA_Cre)) + geom_point()

ldlpfc_Glu_age <- lm(Glu_Cre~age, data=ldlpfc)
summary(ldlpfc_Glu_age) 
ggplot(ldlpfc, aes(x=age, y=Glu_Cre)) + geom_point()

#### ROI4 ####
rdlpfc_Cre_age <- lm(Cre~age, data=rdlpfc)
summary(rdlpfc_Cre_age)
ggplot(rdlpfc, aes(x=age, y=Cre)) + geom_point()

rdlpfc_GABA_age <- lm(GABA_Cre~age, data=rdlpfc)
summary(rdlpfc_GABA_age)
ggplot(rdlpfc, aes(x=age, y=GABA_Cre)) + geom_point()

rdlpfc_Glu_age <- lm(Glu_Cre~age, data=rdlpfc)
summary(rdlpfc_Glu_age) 
ggplot(rdlpfc, aes(x=age, y=Glu_Cre)) + geom_point()

#### ROI 6 ####
acc_Cre_age <- lm(Cre~age, data=acc)
summary(acc_Cre_age)
ggplot(acc, aes(x=age, y=Cre)) + geom_point()

acc_GABA_age <- lm(GABA_Cre~age, data=acc)
summary(acc_GABA_age)
ggplot(acc, aes(x=age, y=GABA_Cre)) + geom_point()

acc_Glu_age <- lm(Glu_Cre~age, data=acc)
summary(acc_Glu_age) 
ggplot(acc, aes(x=age, y=Glu_Cre)) + geom_point()


#### ROI 7 ####
thal_Cre_age <- lm(Cre~age, data=thalamus)
summary(thal_Cre_age)
ggplot(thalamus, aes(x=age, y=Cre)) + geom_point()

thal_GABA_age <- lm(GABA_Cre~age, data=thalamus)
summary(thal_GABA_age)
ggplot(thalamus, aes(x=age, y=GABA_Cre)) + geom_point()

thal_Glu_age <- lm(Glu_Cre~age, data=thalamus)
summary(thal_Glu_age) 
ggplot(thalamus, aes(x=age, y=Glu_Cre)) + geom_point()
