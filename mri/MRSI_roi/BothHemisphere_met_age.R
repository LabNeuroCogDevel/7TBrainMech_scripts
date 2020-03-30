BothHemisphere_met_age <- function(d, region1, region2, metabolite, CRLB, saveplot=F) {                                                    
  # MP and WF 3/27/2020
  # setup like                                                                                                               
  # MRS <- read.csv('txt/13MP20200207_LCMv1.csv')                                                                            
  # d = MRS; region1 = 6; region2 = 7; metabolite = "Glu.Cr"; CRLB = ~Glu.SD                                                               
  # out <- metabolite_ageeffect(MRS, 6, 7, Glu.Cr, Glu.SD)    
  
  require(dplyr)
  require(ggplot2)
  require(cowplot)  
  require(lme4)
  require(lmerTest)
  require(emmeans)
  
  # Filtering                                                                                                                
  brain_region_all <- d %>% filter(roi == region1 | roi == region2)                                                                          
  # for debuging e.g.: CRLB <- quo(Clu.SD)
  brain_region <-                                                                                                            
    brain_region_all %>%                                                                                                   
    filter(!!enquo(CRLB) <= 20) %>%                                                                                        
    na.omit()                                                                                                              
  
  #OUTPUT: return sample size so i know how many people i now have after exclusions                                          
  cat(sprintf("retaining %d/%d\n", nrow(brain_region), nrow(brain_region_all))) 
  
  # AGE EFFECT                                                                                                               
  # Test linear, inverse, and quadratic fits

  mtbl_str <- as.character(substitute(metabolite)) 
  # for debug: metabolite <- quo(Glu.Cr)
  # mtbl_str <- 'Glu.Cr'
  
  #linear
  fml <- mtbl_str %>% sprintf("%s ~ age + GMrat + label + (1|ld8)",.) %>% as.formula
  m1 <- lmer(fml, data = brain_region)
  
  #inverse 
  fml <- mtbl_str %>% sprintf("%s ~ invage + GMrat + label+ (1|ld8)",.) %>% as.formula
  m2 <- lmer(fml, data = brain_region)

  #quadratic
  fml <- mtbl_str %>% sprintf("%s ~ age + age2 + GMrat + label+ (1|ld8)",.) %>% as.formula
  m3 <- lmer(fml, data = brain_region)
  
  #calculate AIC 
  AIC_lin <- AIC(m1)
  AIC_inv <- AIC(m2)
  AIC_quad <- AIC(m3)
  
  interp_age <- seq(min(brain_region$age),
                    max(brain_region$age),
                    by=.1)
  bestAICval <- min(c(AIC_quad, AIC_lin, AIC_inv))
  if( AIC_lin == bestAICval) {
    smry <- summary(m1)
    best_model <- m1
    bestfit <- 'age'
    best_list <- list(age=interp_age)
  } else if (AIC_inv == bestAICval) {
    smry <- summary(m2)
    best_model <- m2
    bestfit <- 'invage'
    best_list <- list(invage=1/interp_age)
  } else if (AIC_quad == bestAICval) { 
    smry <- summary(m3)
    best_model <- m3
    bestfit <- 'age2'
    best_list <- list(age=interp_age,age2=interpage^2)
  } else {
      stop('unkown best AIC!')
  }
  
  print(smry)
  
  
  # TO DO: this is doing the crazy line thing again; might need to update predict function with new covariates?
  # TO DO: can I add a L and R line onto this graph 
  
  #brain_region$est <- predict(best_model,  brain_region %>% mutate(GMrat=mean(GMrat,na.rm=T),  label=first(label)))
  avgs <- emmeans::ref_grid(best_model, at=best_list)
  fitdf <- as.data.frame(summary(avgs)) 

  #graph 
  
  title <- sprintf("%s %s roi1=%d roi2=%d (n=%d, p=%.03f, e=%.03f)",
                   mtbl_str,
                   bestfit,
                   region1, region2, nrow(brain_region),
                   smry$coefficients[bestfit,'Pr(>|t|)'],
                   smry$coefficients[bestfit,'Estimate'])
  print(title)

  #plot L and R lines
  
  p <-
    ggplot(plot_data) +
    aes(x=age, y=!!enquo(metabolite), color=label, group=label) +
    geom_point() +
    geom_line(data=fitdf,aes(y=prediction), color='black') +
    ggtitle(title)


  # same as above, but without knowning what is happening!
  # plot_data_ef <- ggeffects::ggpredict(best_model,c("age","label"))
  # p <- plot(plot_data_ef, add.data=T) + ggtitle(title)

  # TO DO: check this
  # Save graph
  if(saveplot) {
    outfile <- paste0('imgs/ageeffect-',gsub('[^.A-Za-z0-9]+','_',title), '.png')
    ggsave(p, file=outfile)
  }

  #return graph, best model summary and sample size
  list(p=p, summary=smry, n=nrow(brain_region))
 }
