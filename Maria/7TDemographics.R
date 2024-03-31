# 7T demographics

library(tidyverse)
library(ggplot2)
library(LNCDR)

merge7t <- read.csv('/Volumes/Hera/Projects/7TBrainMech/scripts/txt/merged_7t.csv')

# sample size & waterfal plot

temp <- dplyr::select(merge7t, sess.age, lunaid,visitno) #pull out id, age, visitnum
temp <- unique(temp) # should have one row per ID per visit
temp <- temp %>% drop_na(sess.age)
colnames(temp)[colnames(temp)=="lunaid"] <- "id" # the LNCD waterfall plot likes "id" and not "lunaid"
colnames(temp)[colnames(temp)=="sess.age"] <- "age" 
long_plot <- waterfall_plot(temp) #depending on whether you have LNCD package loaded in, you migh thave to go LNCDR::waterfall_plot
print(long_plot)

temp <- dplyr::select(merge7t, sess.age, lunaid,visitno, sex) #pull out id, age, visitnum
temp <- temp %>% drop_na(sess.age)
mean(temp$sess.age)
sd(temp$sess.age)

# n M/F
temp$sex <- as.factor(temp$sex)
temp %>% group_by(sex) %>% summarise(n=length(unique(lunaid)))

# ethnicity

# income 

