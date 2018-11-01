#!/usr/bin/env Rscript

#install.packages("qualtRics")
library(qualtRics)

registerOptions(api_token='76qsEM2voOECkoYZHDjuZM1ASsuIeDpmmIZPeLPl',root_url='https://pitt.co1.qualtrics.com')
# allsurveys<-getSurveys() 
# allsurveys[ head(rev(order(allsurveys$lastModified) ),n=2),c('name','id') ]

# 'PET/fMRI Screening: Adults'
# adultScreen <- getSurvey('SV_1KPNjDDpbyRN7et', root_url='https://pitt.co1.qualtrics.com')

# SV_7Qf9MM8lTG7fB0p # Adult Male Battery
# SV_cBjZLr21bjgtt0V # Adult Female Battery
adult_M <- getSurvey('SV_7Qf9MM8lTG7fB0p', root_url='https://pitt.co1.qualtrics.com')
adult_F <- getSurvey('SV_cBjZLr21bjgtt0V', root_url='https://pitt.co1.qualtrics.com')



