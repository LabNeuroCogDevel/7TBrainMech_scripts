merge7t <- read.csv('H:/Projects/7TBrainMech/scripts/txt/merged_7t.csv')
# make smaller dataframe with only variables i need
merge7t <- merge7t %>%
  dplyr::select(lunaid, visitno, rest.age, sess.age, sex, rest.fd, 
                matches('sipfc.*_(Glu|GABA)_gamadj'),
                matches('sipfc.*_all_GMrat'), 
                matches('rest.hurst.*'),
                matches('ADI_*'), 
                matches('mgsLatency_*'),
                matches('BestError_*'), 
                matches('AntiET.'))

#Checking out variables
psych::describe(merge7t)

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
  select(lunaid, visitno, sess.age, invage, rest.fd, 
         matches('rest.hurst.*'))

#prep just the behavior data
behavior <-  merge7t %>%
  select(lunaid, visitno, sess.age, invage, sex,
         matches('mgsLatency_*'), 
         matches('BestError_*'), 
         matches('AntiET.')) %>% filter(visitno <3)

rest.hurst <- rest.hurst %>% filter( !is.na(rest.fd)) # grab people who have brain data; na on fd means na on rest.date/having data

# resid fd out of hurst values first to simplify later models
resfd <- function(d,incol) residuals(lm(data=d%>%mutate(col=incol), col~rest.fd,na.action=na.exclude))

rest.hurst_res <- rest.hurst %>% 
  
  # residilize each hurst columns separately
  # results wil be same nrows as data (NAs where there is no data to model)
  mutate(across(matches('hurst'), \(col) resfd(pick(everything()), col)))

# now calculate the difference score using fd residualized values
rest.hurst_diff <- rest.hurst_res %>% 
  
  # diff across sessions: make 'husrt.rest.ROI_diff' columns for each roi (and only within each lunaid) 
  group_by(lunaid) %>% 
  mutate(across(matches('rest.hurst.'), function(x) x-lead(x), .names = "{.col}_diff")) %>% 
  
  # only 1 row per lunaid, pick row ranked first (whatever visit has data)
  filter(rank(visitno)<2)

# baseline timepoint 1 is called e.g., rest.hurst.ACC. Delta t1 to t2 is called rest.hurst.ACC_diff
# model is cog (t1 and t2) ~ rest.hurst.ACC + rest.hurst.ACC_diff + invage + (1|lunaID)


# want to create new grand mean centered variables for both baseline and change
scale_vec <- function(x) as.vector(scale(x, scale=T, center=T))

rest.hurst_centered <- rest.hurst_diff %>% 
  ungroup %>%
  mutate(across(starts_with('rest.hurst.'), scale_vec, .names = "{.col}_cent"))

# merge hurst and behavior
hurst.behavior <- merge(rest.hurst_centered, behavior, by="lunaid", all=T)


describe(hurst.behavior)



















#Attempting to center on my end using rest.hurst_res
#There are three visits, dropping visit 3 for all subject.
rest.hurst_res <- rest.hurst_res %>% filter(visitno != 3)
table(rest.hurst_res$visitno) #2 now

#Wide data might be easier to deal with in this case.
#can change back to long during merge with beh? Or can do it now.
#Useful function to grab variable names
#dput(colnames(dat))

rest.hurst_res_wide <- pivot_wider(rest.hurst_res,
                                   names_from = visitno,
                                   values_from = c("sess.age", "invage", "rest.fd", "rest.hurst.RAntInsula", 
                                                   "rest.hurst.LAntInsula", "rest.hurst.RPostInsula", "rest.hurst.LPostInsula", 
                                                   "rest.hurst.RCaudate", "rest.hurst.LCaudate", "rest.hurst.ACC", 
                                                   "rest.hurst.MPFC", "rest.hurst.RDLPFC", "rest.hurst.LDLPFC", 
                                                   "rest.hurst.RSTS", "rest.hurst.LSTS", "rest.hurst.RThal"
                                   ))
length(unique(rest.hurst_res$lunaid)) #Looks correct

#Calculate difference scores betwixed the visits for all hurst variables.
#This could be more efficient using dplyr or a function
rest.hurst_res_wide$rest.hurst.RAntInsula_diff <- 
  rest.hurst_res_wide$rest.hurst.RAntInsula_2 - 
  rest.hurst_res_wide$rest.hurst.RAntInsula_1 

rest.hurst_res_wide$rest.hurst.LAntInsula_diff <- 
  rest.hurst_res_wide$rest.hurst.LAntInsula_2 - 
  rest.hurst_res_wide$rest.hurst.LAntInsula_1 

rest.hurst_res_wide$rest.hurst.RPostInsula_diff <- 
  rest.hurst_res_wide$rest.hurst.RPostInsula_2 - 
  rest.hurst_res_wide$rest.hurst.RPostInsula_1 

rest.hurst_res_wide$rest.hurst.LPostInsula_diff <- 
  rest.hurst_res_wide$rest.hurst.LPostInsula_2 - 
  rest.hurst_res_wide$rest.hurst.LPostInsula_1 

rest.hurst_res_wide$rest.hurst.RCaudate_diff <- 
  rest.hurst_res_wide$rest.hurst.RCaudate_2 - 
  rest.hurst_res_wide$rest.hurst.RCaudate_1 

rest.hurst_res_wide$rest.hurst.LCaudate_diff <- 
  rest.hurst_res_wide$rest.hurst.LCaudate_2 - 
  rest.hurst_res_wide$rest.hurst.LCaudate_1 

rest.hurst_res_wide$rest.hurst.ACC_diff <- 
  rest.hurst_res_wide$rest.hurst.ACC_2 - 
  rest.hurst_res_wide$rest.hurst.ACC_1 

rest.hurst_res_wide$rest.hurst.MPFC_diff <- 
  rest.hurst_res_wide$rest.hurst.MPFC_2 - 
  rest.hurst_res_wide$rest.hurst.MPFC_1 

rest.hurst_res_wide$rest.hurst.RDLPFC_diff <- 
  rest.hurst_res_wide$rest.hurst.RDLPFC_2 - 
  rest.hurst_res_wide$rest.hurst.RDLPFC_1 

rest.hurst_res_wide$rest.hurst.LDLPFC_diff <- 
  rest.hurst_res_wide$rest.hurst.LDLPFC_2 - 
  rest.hurst_res_wide$rest.hurst.LDLPFC_1 

rest.hurst_res_wide$rest.hurst.RSTS_diff <- 
  rest.hurst_res_wide$rest.hurst.RSTS_2 - 
  rest.hurst_res_wide$rest.hurst.RSTS_1 

rest.hurst_res_wide$rest.hurst.LSTS_diff <- 
  rest.hurst_res_wide$rest.hurst.LSTS_2 - 
  rest.hurst_res_wide$rest.hurst.LSTS_1 

rest.hurst_res_wide$rest.hurst.RThal_diff <- 
  rest.hurst_res_wide$rest.hurst.RThal_2 - 
  rest.hurst_res_wide$rest.hurst.RThal_1 

#Cool
#Now I will center baseline and difference scores.
rest.hurst_res_wide <- rest.hurst_res_wide %>%
  mutate(across(matches("_1$"), ~scale(.), .names = "{col}_cent")) %>%
  mutate(across(matches("_diff$"), ~scale(.), .names = "{col}_cent"))

psych::describe(rest.hurst_res_wide)
#Subset the variables we actually need?
subset_vars <- rest.hurst_res_wide %>%
  select(lunaid,contains("_cent"))
  
test <- merge(subset_vars, behavior, by = "lunaid", all = TRUE)

psych::describe(test)
#From here, you can add whatever variables to this "test" data set (I'd change the name).
#Not my best work, but it looks correct.

identical(hurst.behavior$rest.hurst.RAntInsula_diff_cent,
          test$rest.hurst.RAntInsula_diff_cent)
#Showing that they are different.