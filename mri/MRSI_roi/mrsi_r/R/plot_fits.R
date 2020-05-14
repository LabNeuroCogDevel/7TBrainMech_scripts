#' @title
#' Plot best model fit
#'
#' @description
#' return a plot of fits
#'
#' @details
#' 
#' 
#' @param d dataframe with region, metabolite, and crlb columns
#' @param regions numeric region(s) to include
#' @param metabolite unquoted column name for y
#' @param CRLB unquoted column name for thres cutoff
#' @param saveplot boolean save or not
mrsi_plot <- function(d, regions, metabolite, CRLB, saveplot=F) {                                                    

  brain_region<- mrsi_clean(d, regions, !!enquo(CRLB), mesg=T)
  best_model  <- mrsi_bestmodel(d, regions, !!enquo(metabolite), !!enquo(CRLB))
  best_fit    <- what_age_y(best_model)

  sigval <-   p_or_t(smry$coefficients) 

  ptitle <- sprintf("%s %s rois=%s (n=%d, p=%.03f, e=%.03f)",
                   mtbl_str,
                   bestfit,
                   paste(regions),
                   nrow(brain_region),
                   sigval,
                   smry$coefficients[bestfit,'Estimate'])
  print(ptitle)

  # if we had multiple regions:
  #, color=label, group=label) +

  p <-
    ggplot(brain_region) +
    aes(x=age, y=!!enquo(metabolite)) +
    geom_point() +
    geom_line(data=fitdf,aes(y=prediction), color='black') +
    ggtitle(ptitle)


  # TO DO: check this
  # Save graph
  if(saveplot) {
    outfile <- paste0('imgs/ageeffect-',gsub('[^.A-Za-z0-9]+','_',ptitle), '.png')
    ggsave(p, file=outfile)
  }

  return(p)
}
