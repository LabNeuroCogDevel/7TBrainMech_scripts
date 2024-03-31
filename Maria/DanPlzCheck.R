merge7t <- read.csv('/Volumes/Hera/Projects/7TBrainMech/scripts/txt/merged_7t.csv')

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



