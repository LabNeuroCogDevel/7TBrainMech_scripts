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
#' @param crlb unquoted column name for thres cutoff
#' @param saveplot boolean save or not
#' @import ggplot2
#' @export
mrsi_plot <- function(d, regions, metabolite, crlb, saveplot=F) {
  require(ggplot2)

  brain_region<- mrsi_clean(d, regions, crlb)
  best_model  <- mrsi_bestmodel(brain_region, metabolite)
  fitdf       <- mrsi_fitdf(best_model)

  ## info from model that we didn't expliclty return
  smry <- summary(best_model)
  # dangerously assume first factor is the metabolite
  mtbl_str <- rownames(attr(smry$terms,"factors"))[1]
  bestfit  <- what_age_y(smry$coefficients)
  sigval   <- p_or_t(smry$coefficients[bestfit,])

  ptitle <- sprintf("%s %s rois=%s (n=%d, %s, e=%.03f)",
                   mtbl_str,
                   bestfit,
                   paste(regions, collapse=", ", sep=", "),
                   nrow(brain_region),
                   sigval,
                   smry$coefficients[bestfit, "Estimate"])
  print(ptitle)

  # if we had multiple regions:
  #, color=label, group=label) +

  p <-
    ggplot(brain_region) +
    aes(x=age, y=!!sym(metabolite)) +
    geom_point() +
    geom_line(data=fitdf, aes(y=prediction), color="black") +
    ggtitle(ptitle)


  # TO DO: check this
  # Save graph
  if (saveplot) {
    outfile <- paste0("imgs/ageeffect-",
                      gsub("[^.A-Za-z0-9]+", "_", ptitle),
                      ".png")
    ggsave(p, file=outfile)
  }

  return(p)
}


#' @title
#' Plot best model fit over raw data for multiple metabolites
#'
#' @description
#' return a plot of fits and raw
#'
#' @details
#' @param d dataframe with region, metabolite, and crlb columns
#' @param regions numeric region(s) to include
#' @param mtbl_thres list of quoted metabolite and thres column names
#'                      list(Glu.Cr="Glu.SD"), GABA.Cr="GABA.SD"))
#' @param saveplot boolean save or not
#' @import ggplot2
#' @import magrittr
#' @importFrom dplyr bind_rows
#' @importFrom magrittr %>%
#' @examples
#' mrsi_plot_many(d, 1, list(Glu.Cr='Glu.SD', GABA.Cr="GABA.SD")) %>% print
#' @export
mrsi_plot_many <- function(d, regions, mtbl_thres, saveplot=F) {
  require(ggplot2)
  require(magrittr)

  d_and_fit <- mapply(function(m, t) fit_and_data(d,regions, m, t),
                       names(mtbl_thres), mtbl_thres,
                      SIMPLIFY=F)

  # get data and fit separately
  d_raw <- lapply(d_and_fit, '[[', 'd') %>% dplyr::bind_rows()
  d_fit <- lapply(d_and_fit, '[[', 'f') %>% dplyr::bind_rows()

  p <-
    ggplot(d_raw) +
    aes(x=age, y=concentration, color=metabolite) +
    geom_point(alpha=.5) +
    geom_line(data=d_fit, aes(y=prediction))
}

# for internal use
# get model and data

#' @title fit and filter data
#' @description fitted and flitered data with common column names
#' @details
#' @param d datafraem with region, metabolite, and crlb columns
#' @param regions regions to include, like c(1,2,3)
#' @return
#'  list with d (cleaned data w/concentration and metabolite column names) and f (fitted data)
#' @export
fit_and_data <- function(d, regions, mtbl, thres, crlb_thres=20) {
  d <- mrsi_clean(d, regions, thres, mesg=T, nona=c("GMrat", mtbl), crlb_thres=crlb_thres)
  # set metabolite column to same value everywhere
  d$concentration <- d[,mtbl]
  d$metabolite <- mtbl

  m <- mrsi_bestmodel(d, mtbl)
  f <- mrsi_fitdf(m)
  return(list(d=d, f=f))
}
