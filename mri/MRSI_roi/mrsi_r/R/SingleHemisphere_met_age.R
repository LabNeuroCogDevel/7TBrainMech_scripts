SingleHemisphere_met_age <- function(d, region, metabolite, CRLB, saveplot=F) {
  # setup like
  # MRS <- read.csv('txt/13MP20200207_LCMv1.csv')
  # d = MRS; region = 1; metabolite = "Glu.Cr"; CRLB = ~Glu.SD
  # out <- metabolite_ageeffect(MRS, 1, Glu.Cr, Glu.SD)
  require(dplyr)
  require(ggplot2)
  require(cowplot)

  # check for age columns. make if we need and can
  stopifnot('age' %in% names(d))
  if (! 'invage'  %in% names(d)) d$invage <- 1/d$age
  if (! 'age2'    %in% names(d)) d$age2   <- d$age^2

  # currently not using fd, and it is missing for some subjects
  d <- d %>% select(-matches('^fd'))

    
  ## Filtering
  # only this roi region (roi# 1 to 13)
  brain_region_all <- d %>% filter(roi == region)
  # check NAs
  region_nona <- brain_region_all %>% na.omit()
  nomit <- nrow(brain_region_all) - nrow(region_nona)
  if(nomit >0L) cat("removed ", nomit, "rows with NA\n");
  # filter by crlb
  brain_region <- region_nona %>% filter(!!enquo(CRLB) <= 20)
  nCRLBrm <- nrow(region_nona) - nrow(brain_region)
  if(nCRLBrm >0L) cat("removed ", nCRLBrm, "rows with CRLB>=30\n");


  mtbl_str <- as.character(substitute(metabolite))

  # remove outliers
  #brain_region$zscore <- scale(brain_region[,mtbl_str], center = TRUE, scale = TRUE)
  #brain_region$zscore <- abs(brain_region$zscore)
  #brain_region<-brain_region[brain_region$zscore<2,]

  # debuging - print what we removed
  #leftout <- brain_region %>% anti_join(brain_region_all, .) 
  #print(str(leftout))

  #OUTPUT: return sample size so i know how many people i now have after exclusions
  cat(sprintf("after all filtering: retaining %d/%d\n", nrow(brain_region), nrow(brain_region_all)))

  # AGE EFFECT
  # Test linear, inverse, and quadratic fits without outliers

  #linear
  fml <- sprintf("%s ~ age + GMrat", mtbl_str) %>% as.formula
  #fml <- mtbl_str %>% sprintf("%s ~ age + GMrat",.) %>% as.formula
  m1 <- lm(fml, data = brain_region)

  #inverse
  fml <- sprintf("%s ~ invage + GMrat", mtbl_str) %>% as.formula
  #fml <- mtbl_str %>% sprintf("%s ~ invage + GMrat",.) %>% as.formula
  m2 <- lm(fml, data = brain_region)

  #quadratic
  fml <- sprintf("%s ~ age + age2 + GMrat", mtbl_str) %>% as.formula
  #fml <- mtbl_str %>% sprintf("%s ~ age + age2 + GMrat + CRLB",.) %>% as.formula
  m3 <- lm(fml, data = brain_region)

  #calculate AIC
  AIC_lin <- AIC(m1)
  AIC_inv <- AIC(m2)
  AIC_quad <- AIC(m3)

  # GRAPHING

  if (AIC_quad < AIC_lin & AIC_quad < AIC_inv) {
    smry <- summary(m3)
    best_model <- m3
    bestfit <- 'age2'
  } else if (AIC_inv < AIC_lin & AIC_inv < AIC_quad) {
    smry <- summary(m2)
    best_model <- m2
    bestfit <- 'invage'
  } else {
    smry <- summary(m1)
    best_model <- m1
    bestfit <- 'age'
  }

  # get residuals for outlier detection
  brain_region$z <- abs(scale(best_model$residuals))
  cat('number z>3: ', length(which(brain_region$z>=3)),'\n')
  brain_region<-brain_region[brain_region$z<3,]


   # do it again with the outliers removed
  #linear
  fml <- sprintf("%s ~ age + GMrat", mtbl_str) %>% as.formula
  #fml <- mtbl_str %>% sprintf("%s ~ age + GMrat + CRLB",.) %>% as.formula
  m1 <- lm(fml, data = brain_region)

  #inverse
  fml <- sprintf("%s ~ invage + GMrat", mtbl_str) %>% as.formula
  #fml <- mtbl_str %>% sprintf("%s ~ invage + GMrat + CRLB",.) %>% as.formula
  m2 <- lm(fml, data = brain_region)

  #quadratic
  fml <- sprintf("%s ~ age + age2 + GMrat", mtbl_str) %>% as.formula
  #fml <- mtbl_str %>% sprintf("%s ~ age + age2 + GMrat + CRLB",.) %>% as.formula
  m3 <- lm(fml, data = brain_region)

  #calculate AIC
  AIC_lin <- AIC(m1)
  AIC_inv <- AIC(m2)
  AIC_quad <- AIC(m3)

  # GRAPHING
  if (AIC_quad < AIC_lin & AIC_quad < AIC_inv) {
    smry <- summary(m3)
    best_model <- m3
    bestfit <- 'age2'
  } else if (AIC_inv < AIC_lin & AIC_inv < AIC_quad) {
    smry <- summary(m2)
    best_model <- m2
    bestfit <- 'invage'
  } else {
    smry <- summary(m1)
    best_model <- m1
    bestfit <- 'age'
  }


  brain_region$est <- predict(best_model,  brain_region %>% mutate(GMrat=mean(GMrat,na.rm=T)))

  #graph
  title <- sprintf("%s %s roi=%d (n=%d, p=%f, e=%.03f)",
                   mtbl_str,
                   bestfit,
                   region, nrow(brain_region),
                   smry$coefficients[bestfit,'Pr(>|t|)'],
                   smry$coefficients[bestfit,'Estimate'])
  print(title)

  p <-
    ggplot(brain_region) +
    aes(x=age, y=!!enquo(metabolite)) +
    geom_point() +
    geom_line(aes(y=est), color='blue') +
    ggtitle(title)


  # TO DO: check whether this works
  # Save graph
  if(saveplot) {
    outfile <- paste0('imgs/ageeffect-',gsub('[^.A-Za-z0-9]+','_',title), '.png')
    ggsave(p, file=outfile)
  }

  #return graph, best model summary and sample size
  list(p=p, summary=smry, n=nrow(brain_region))
}
