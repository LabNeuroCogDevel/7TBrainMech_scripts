library(ppcor)

# analyses for bea
merge7t <- read.csv('/Volumes/Hera/Projects/7TBrainMech/scripts/txt/merged_7t.csv')

# make smaller dataframe with only variables i need
merge7t <- merge7t %>%
  dplyr::select(lunaid, visitno, rest.age, sess.age, sex, rest.fd, 
         matches('sipfc.*_(Glu|GABA)_gamadj'),
         matches('sipfc.*_all_GMrat'), 
         matches('hurst_*'), 
         matches('mgsLatency_*'), 
         matches('BestError_*'), 
         matches('*_(Offset|Exponent)'), 
         matches('antiET.*'))
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

cor.test(merge7t$hurst_brns.RDLPFC, merge7t$sipfc.RDLPFC_GABA_gamadj)
cor.test(merge7t$hurst_brns.LDLPFC, merge7t$sipfc.LDLPFC_GABA_gamadj)
cor.test(merge7t$hurst_brns.RDLPFC, merge7t$sipfc.RDLPFC_Glu_gamadj)
cor.test(merge7t$hurst_brns.LDLPFC, merge7t$sipfc.LDLPFC_Glu_gamadj)
cor.test(merge7t$hurst_brns.RDLPFC, merge7t$sipfc.RDLPFC_GluGABARat)
cor.test(merge7t$hurst_brns.LDLPFC, merge7t$sipfc.LDLPFC_GluGABARat)
cor.test(merge7t$hurst_brns.RDLPFC, merge7t$sipfc.RDLPFC_GluGABAMismatch)
cor.test(merge7t$hurst_brns.LDLPFC, merge7t$sipfc.LDLPFC_GluGABAMismatch)
cor.test(merge7t$hurst_brns.RDLPFC, merge7t$eeg.eyesOpen_RDLPFC_Exponent)
cor.test(merge7t$hurst_brns.RDLPFC, merge7t$eeg.eyesClosed_RDLPFC_Exponent)
cor.test(merge7t$hurst_brns.LDLPFC, merge7t$eeg.eyesOpen_LDLPFC_Exponent)
cor.test(merge7t$hurst_brns.LDLPFC, merge7t$eeg.eyesClosed_LDLPFC_Exponent)
cor.test(merge7t$hurst_brns.RDLPFC, merge7t$eeg.eyesOpen_RDLPFC_Offset)
cor.test(merge7t$hurst_brns.RDLPFC, merge7t$eeg.eyesClosed_RDLPFC_Offset)
cor.test(merge7t$hurst_brns.LDLPFC, merge7t$eeg.eyesOpen_LDLPFC_Offset)
cor.test(merge7t$hurst_brns.LDLPFC, merge7t$eeg.eyesClosed_LDLPFC_Offset)

ggplot(data=merge7t) + aes(y=hurst_brns.LDLPFC, x=eeg.eyesClosed_LDLPFC_Offset) + geom_point() + stat_smooth(method="lm") + theme_classic(base_size=25)
ggplot(data=merge7t) + aes(y=hurst_brns.LDLPFC, x=eeg.eyesOpen_LDLPFC_Offset) + geom_point() + stat_smooth(method="lm") + theme_classic(base_size=25)

ggplot(data=merge7t) + aes(x = sess.age, y = eeg.mgsLatency_DelayAll) + geom_point() + stat_smooth(method="lm") + theme_classic(base_size=25) + 
  xlab("Age") + ylab("Latency Variability")

ggplot(data=merge7t) + aes(x=sess.age, y=eeg.mgsLatency_DelayAll, group=lunaid) + geom_point() + 
  stat_smooth(method="lm", formula = y~I(1/x), fullrange=T, aes(group=NULL)) +theme_classic(base_size=25) + xlab("Age") + ylab("Latency Variability") +
  geom_line(aes(group=paste(lunaid))) 



# spatial span



# foof and mrsi correlations
dlpfc_fm<- merge7t %>% dplyr::select(lunaid, visitno, sess.age, invage, sex, matches('sipfc.RDLPFC_(Glu|GABA)_gamadj'), matches('sipfc.LDLPFC_(Glu|GABA)_gamadj'), hurst.RDLPFC_ns = hurst_ns.RDLPFC, hurst.LDLPFC_ns = hurst_ns.LDLPFC,  matches('*_(Offset|Exponent)'))
dlpfc_fm <- dlpfc_fm %>% rename_with(\(n) gsub('eeg.(eyes[^.]*).([LR]DLPFC)','eeg.\\2.\\1',n))



with(dlpfc_fm %>% 
       dplyr::select(eeg.RDLPFC.eyesClosed_Offset, hurst.RDLPFC_ns, invage) %>% 
       na.omit(),
     pcor.test(eeg.RDLPFC.eyesClosed_Offset, hurst.RDLPFC_ns, invage, method="pearson")
) 

ggplot(dlpfc_fm) + aes(x=eeg.LDLPFC.eyesOpen_Offset, y = hurst.LDLPFC_brns) + geom_point() + stat_smooth(method="lm")

# long df for plots
dlpfc_fm_long <- dlpfc_fm %>% 
  pivot_longer(matches('RDLPFC|LDLPFC')) %>% 
  separate(name,c('measure', 'hemi', 'ei'), extra="merge")


# MGS

# dlpfc
dlpfc<- merge7t %>% dplyr::select(lunaid, visitno, sess.age, invage, sex, matches('sipfc.RDLPFC_(Glu|GABA)_gamadj'), matches('sipfc.LDLPFC_(Glu|GABA)_gamadj'), hurst.RDLPFC_brns = hurst_brns.RDLPFC, hurst.LDLPFC_brns = hurst_brns.LDLPFC,  matches('mgsLatency_*'), matches('BestError_*'), matches('antiET.*'), matches('ssp'))
dlpfc_long <- dlpfc %>% 
  pivot_longer(matches('RDLPFC|LDLPFC')) %>% 
  separate(name,c('measure', 'hemi', 'ei'), extra="merge")

dlpfc_hurst_cog <- dlpfc_long %>% filter(measure=='hurst')
dlpfc_mrs_cog <- dlpfc_long %>% filter(measure=='sipfc')


hurst_mgslat <- lmer(data=dlpfc_hurst_cog, value ~ eeg.mgsLatency_DelayAll + invage + hemi + (1|lunaid))
summary(hurst_mgslat)
hurst_mgslat <- lmer(data=dlpfc_hurst_cog, value ~ eeg.mgsLatency_DelayAll * invage + hemi + (1|lunaid))
summary(hurst_mgslat)


hurst_mgslatSD <- lmer(data=dlpfc_hurst_cog, value ~ eeg.mgsLatency_sd_DelayAll + invage + hemi + (1|lunaid))
summary(hurst_mgslatSD)
dlpfc_hurst_cog %>% group_by(lunaid, eeg.mgsLatency_sd_DelayAll) %>% 
  summarise(value=mean(value)) %>% 
  ggplot() + aes(x=value, y=eeg.mgsLatency_sd_DelayAll) +geom_point() + stat_smooth(method="lm") +theme_classic(base_size=25) +
  xlab("Hurst") + ylab(" MGS latency SD")  + theme(legend.title = element_blank(), legend.key = element_rect(fill = NA, color = NA)) + geom_line(aes(group=paste(lunaid))) 
ggsave("DLPFC_Hurst_MGSLatSD.tiff", height=6, width=6, dpi=300)


hurst_besterror <- lmer(data=dlpfc_hurst_cog, value ~ eeg.BestError_DelayAll + invage + hemi + (1|lunaid))
summary(hurst_besterror)

hurst_besterrorsd <- lmer(data=dlpfc_hurst_cog, value~ eeg.BestError_sd_DelayAll + invage + hemi + (1|lunaid))
summary(hurst_besterrorsd)


dlpfc_hurst_cog %>% group_by(lunaid, cantab.ssp_max.span) %>% 
  summarise(value=mean(value)) %>% 
  ggplot() + aes(x=value, y=eeg.mgsLatency_sd_DelayAll) +geom_point() + stat_smooth(method="lm") +theme_classic(base_size=25) +
  xlab("Hurst") + ylab(" MGS latency SD")  + theme(legend.title = element_blank(), legend.key = element_rect(fill = NA, color = NA)) + geom_line(aes(group=paste(lunaid))) 

ggplot(data=dlpfc_hurst_cog) +  aes(x=value, y=cantab.ssp_max.span) + geom_point() + stat_smooth(method="lm") +theme_classic(base_size=25) 

hurst_cantabssp <- lmer(data=dlpfc_hurst_cog, value ~ cantab.ssp_max.span + invage + hemi + (1|lunaid))
summary(hurst_cantabssp)



# ACC

acc<- merge7t %>% dplyr::select(lunaid, visitno, sess.age, invage, sex, matches('sipfc.ACC_(Glu|GABA)_gamadj'), hurst.ACC_brns = hurst_brns.ACC, matches('mgsLatency_*'), matches('BestError_*'), matches('antiET.*'))

acc_hurst_mgslat <- lmer(data=acc, eeg.mgsLatency_DelayAll ~ hurst.ACC_brns + invage + (1|lunaid))
summary(acc_hurst_mgslat) # trend main effect hurst 
acc_hurst_mgslat <- lmer(data=acc, eeg.mgsLatency_DelayAll ~ hurst.ACC_brns * invage + (1|lunaid))
summary(acc_hurst_mgslat)

acc_hurst_mgslatsd <- lmer(data=acc, eeg.mgsLatency_sd_DelayAll ~ hurst.ACC_brns + invage + (1|lunaid))
summary(acc_hurst_mgslatsd)
acc_hurst_mgslatsd <- lmer(data=acc, eeg.mgsLatency_sd_DelayAll ~ hurst.ACC_brns * invage + (1|lunaid))
summary(acc_hurst_mgslatsd)


acc_hurst_besterror <- lmer(data=acc, eeg.BestError_DelayAll ~ hurst.ACC_brns + invage + (1|lunaid))
summary(acc_hurst_besterror)
acc_hurst_besterror <- lmer(data=acc, eeg.BestError_DelayAll ~ hurst.ACC_brns * invage + (1|lunaid))
summary(acc_hurst_besterror) # trend interaction

acc_hurst_besterrorsd <- lmer(data=acc, eeg.BestError_sd_DelayAll ~ hurst.ACC_brns + invage + (1|lunaid))
summary(acc_hurst_besterrorsd)
acc_hurst_besterrorsd <- lmer(data=acc, eeg.BestError_sd_DelayAll ~ hurst.ACC_brns * invage + (1|lunaid))
summary(acc_hurst_besterrorsd) # trend interaction

# MPFC

MPFC<- merge7t %>% dplyr::select(lunaid, visitno, sess.age, invage, sex, matches('sipfc.MPFC_(Glu|GABA)_gamadj'), hurst.MPFC_brns = hurst_brns.MPFC, matches('mgsLatency_*'), matches('BestError_*'), matches('antiET.*'))

MPFC_hurst_mgslat <- lmer(data=MPFC, eeg.mgsLatency_DelayAll ~ hurst.MPFC_brns + invage + (1|lunaid))
summary(MPFC_hurst_mgslat)
MPFC_hurst_mgslat <- lmer(data=MPFC, eeg.mgsLatency_DelayAll ~ hurst.MPFC_brns * invage + (1|lunaid))
summary(MPFC_hurst_mgslat)

MPFC_hurst_mgslatsd <- lmer(data=MPFC, eeg.mgsLatency_sd_DelayAll ~ hurst.MPFC_brns + invage + (1|lunaid))
summary(MPFC_hurst_mgslatsd) # significant
ggplot(data=MPFC) + aes(x=hurst.MPFC_brns, y=eeg.mgsLatency_sd_DelayAll) +geom_point() + stat_smooth(method="lm") +theme_classic(base_size=25) +
  xlab(" MPFC Hurst") + ylab(" MGS latency") + ggtitle("MPFC Hurst x MGS Latency")

MPFC_hurst_mgslatsd <- lhurst_mgslat <- lmer(data=dlpfc_hurst_cog, eeg.mgsLatency_DelayAll ~ value + invage + hemi + (1|lunaid))
summary(hurst_mgslat)
mer(data=MPFC, eeg.mgsLatency_sd_DelayAll ~ hurst.MPFC_brns * invage + (1|lunaid))
summary(MPFC_hurst_mgslatsd)


MPFC_hurst_besterror <- lmer(data=MPFC, eeg.BestError_DelayAll ~ hurst.MPFC_brns + invage + (1|lunaid))
summary(MPFC_hurst_besterror)
MPFC_hurst_besterror <- lmer(data=MPFC, eeg.BestError_DelayAll ~ hurst.MPFC_brns * invage + (1|lunaid))
summary(MPFC_hurst_besterror)

MPFC_hurst_besterrorsd <- lmer(data=MPFC, eeg.BestError_sd_DelayAll ~ hurst.MPFC_brns + invage + (1|lunaid))
summary(MPFC_hurst_besterrorsd)
MPFC_hurst_besterrorsd <- lmer(data=MPFC, eeg.BestError_sd_DelayAll ~ hurst.MPFC_brns * invage + (1|lunaid))
summary(MPFC_hurst_besterrorsd)

#### Anti ----

dlpfc_hurst_cog$antiET.pctCorr <-  with(dlpfc_hurst_cog, (antiET.Cor/(antiET.Cor + antiET.ErrCor + antiET.Err)))
ggplot(data=dlpfc_hurst_cog) + aes(x=value, y=antiET.pctCorr) +geom_point() + stat_smooth(method="lm") +theme_classic(base_size=25) +
  xlab("Hurst") + ylab(" Percent Correct") + ggtitle("DLPFC Hurst x Anti Percent Correct")

hurst_antipctcorr<- lmer(data=dlpfc_hurst_cog, value ~ antiET.pctCorr + invage + hemi + (1|lunaid))
summary(hurst_antipctcorr)

idx <- which(!is.na(dlpfc_hurst_cog$value))
h_res <- residuals(lm(data=dlpfc_hurst_cog[idx,], value~invage, na.action=na.exclude))
dlpfc_hurst_cog$hurst_ageresid <- NA
dlpfc_hurst_cog[idx,]$hurst_ageresid <-  h_res

ggplot(data=dlpfc_hurst_cog) + aes(x=sess.age, y=antiET.pctCorr) +geom_point() + stat_smooth(method="lm") +theme_classic(base_size=25) +
  xlab("age") + ylab(" Percent Correct") + ggtitle("Age x Anti Percent Correct")

hurst_anticorrlat<- lmer(data=dlpfc_hurst_cog,  value ~ antiET.cor.lat * invage + hemi + (1|lunaid))
summary(hurst_anticorrlat)
+ theme(legend.position='none')

acc$antiET.pctCorr <-  with(acc, (antiET.Cor/(antiET.Cor + antiET.ErrCor + antiET.Err)))
acc_hurst_pctcor <- lmer(data=acc, antiET.pctCorr ~ hurst.ACC_brns + invage + (1|lunaid))
summary(acc_hurst_pctcor)
acc_hurst_corlat <- lmer(data=acc, antiET.cor.lat ~ hurst.ACC_brns + invage + (1|lunaid))
summary(acc_hurst_corlat)

MPFC$antiET.pctCorr <-  with(MPFC, (antiET.Cor/(antiET.Cor + antiET.ErrCor + antiET.Err)))
MPFC_hurst_pctcor <- lmer(data=MPFC, antiET.pctCorr ~ hurst.MPFC_brns + invage + (1|lunaid))
summary(MPFC_hurst_pctcor)
MPFC_hurst_corlat <- lmer(data=MPFC, antiET.cor.lat ~ hurst.MPFC_brns + invage + (1|lunaid))
summary(MPFC_hurst_corlat)
MPFC_hurst_corlat <- lmer(data=MPFC, antiET.cor.lat ~ hurst.MPFC_brns + invage + (1|lunaid))
summary(MPFC_hurst_corlat)


