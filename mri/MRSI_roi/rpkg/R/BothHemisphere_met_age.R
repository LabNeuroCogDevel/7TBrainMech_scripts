#' @title
#' Model two regions
#'
#' @description
#' `BothHemisphere_met_age` returns plot, model summary, and row count
#'
#' @details
#' 
#' 
#' @param d dataframe with region, metabolite, and crlb columns
#' @param region1 numeric region to include
#' @param region2 numeric region to include
#' @param metabolite unquoted column name for y
#' @param CRLB unquoted column name for thres cutoff
#' @param saveplot boolean save or not
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
  models_strs <-
      list(age   ="%s ~ age        + GMrat + label + (1|ld8)",
           invage="%s ~ invage     + GMrat + label+ (1|ld8)",
           age2  ="%s ~ age + age2 + GMrat + label+ (1|ld8)")

  # fill in formula and calculate model
  models <- lapply(models_strs, function(fmlstr) sprintf(fmlstr,mtbl_str) %>% as.formula %>% lmer(brain_region))
  AICs <- sapply(models, AIC)

  # find which is the best based on AIC
  bestfit <- names(AICs)[which.min(AICs)] # age, invage, or age2
  best_model <- models[[bestfit]]
  smry <- summary(best_model)


  # what to use as age column to use as input for emmeans
  # age2 needs 2 columns (age + age2)
  interp_age <- seq(min(brain_region$age),
                    max(brain_region$age),
                    by=.1)

  if( bestfit == "age") {
    best_list <- list(age=interp_age)
  } else if (bestfit=="invage") {
    best_list <- list(invage=1/interp_age)
  } else if (bestfit=="age2") { 
    best_list <- list(age=interp_age,age2=interpage^2)
  } else {
      stop('unknown best AIC model!', bestfit)
  }
  
  print(smry)
  
  
  # TO DO: this is doing the crazy line thing again; might need to update predict function with new covariates?
  # TO DO: can I add a L and R line onto this graph 
  
  #brain_region$est <- predict(best_model,  brain_region %>% mutate(GMrat=mean(GMrat,na.rm=T),  label=first(label)))
  avgs <- emmeans::ref_grid(best_model, at=best_list)
  fitdf <- as.data.frame(summary(avgs)) 
  # add age back if we dont have it (invage fit)
  if(bestfit == 'invage') fitdf$age <- 1/fitdf$invage

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
    ggplot(brain_region) +
    aes(x=age, y=!!enquo(metabolite), color=label, group=label) +
    geom_point() +
    geom_line(data=fitdf,aes(y=prediction), color='black') +
    ggtitle(title)


  # same as above, but with a lot less control
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
