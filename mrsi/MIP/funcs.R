require(dplyr)
require(lme4)
# source('get_data.R')

z <- function(x) scale(x, center=T, scale=T)

thresh_and_z <- function(MRS, y_col, sd_col, z_thres=2) {
  MRS$met_conc <- MRS[,y_col]
  MRS$conc_sd <- MRS[,sd_col]
  MRS.thres <- MRS %>%
    filter(conc_sd <= 20, met_conc != 0) %>%
    group_by(label) %>%
    mutate(z_met_conc=z(met_conc)) %>%
    filter(abs(z_met_conc) <= z_thres) %>%
    # TODO: this okay?
    # zscore age and gm AFTER filtering
    mutate(zscore_invage  = z(invage),
           zscore_gm      = z(GMrat)) %>%
    ungroup
}

gen_model_combos <- function(MRS, y_col, sd_col, roi_nums) {

  MRS.thres <-
      MRS %>%
      filter(roi %in% roi_nums) %>%
      thresh_and_z(y_col, sd_col)

  models <- list(
      z_inv       = z_met_conc~ zscore_invage   + label                   + (1|ld8),
      z_inv_sexgm = z_met_conc~ zscore_invage   + label + sex + zscore_gm + (1|ld8),

      inv_hemi_int = met_conc ~ invage * label         + sex + GMrat     + (1|ld8),
      inv_sex_int  = met_conc ~ invage * sex   + label       + GMrat     + (1|ld8),
      inv_gmrat_int= met_conc ~ invage * GMrat + label + sex             + (1|ld8)
  )
  lapply(models, lmer, data=MRS.thres)
}


example <- function(){
    # source('get_data.R')
    mrs <- get_mrs()
    roi12_glu_models <- gen_model_combos(mrs, 'Glu.Cr', 'Glu.SD', roi_nums=c(1,2))

    summary(roi12_glu_models$z_inv)
}
