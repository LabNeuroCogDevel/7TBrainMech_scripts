#!/usr/bin/env Rscript
pacman::p_load(dplyr, tidyr)

# see ./050_merge.R
#  gr <- "/Volumes/Hera/Projects/7TBrainMech/subjs/1*_2*/slice_PFC/MRSI_roi/LCModel/v2idxfix"
#  yxcsi <- Sys.glob(sprintf("%s/spectrum*.dir/*csv", gr))
# 
#          coord=stringr::str_extract(f, "(?<=spectrum.)\\d+.\\d+")) %>%
#   separate(coord, c("y", "x"))
#   mutate(x=216+1-as.numeric(x), y=216+1-as.numeric(y)) %>%
d <- read.csv('txt/13MP20200207_LCMv2fixidx.csv')

coord_file <- with(d, paste0(
                          '/Volumes/Hera/Projects/7TBrainMech/subjs/', ld8,
                          '/slice_PFC/MRSI_roi/LCModel/v2idxfix/spectrum.',
                         216+1-y,'.',216+1-x, '.dir/csi.coord'))

missing_coord <- !file.exists(coord_file)
print(length(which(missing_coord))/length(coord_file)) # 15% !! 592
#coord_file[missing_coord][1]
#list.files("/Volumes/Hera/Projects/7TBrainMech/subjs/10173_20210830/slice_PFC/MRSI_roi/LCModel/v2idxfix/spectrum.123.159.dir/")
#[1] "csi.ps"          "spreadsheet.csv"

grep_res <- system('grep FWHM /Volumes/Hera/Projects/7TBrainMech/subjs/1*_2*/slice_PFC/MRSI_roi/LCModel/v2idxfix/spectrum.*.dir/csi.coord', intern=T)
fwhm_df <- read.table(text=grep_res, col.names=c('fname','junk1_fwhm','junk_eq','FWHM','junk_ppm','junk_sn','junk_eq2','snr'))

fwhm <- fwhm_df |>
   mutate(ld8=stringr::str_extract(fname, "(?<=/)\\d{5}_\\d{8}"),
          coord=stringr::str_extract(fname, "(?<=spectrum.)\\d+.\\d+")) |>
   separate(coord, c("sy", "sx")) |>
   mutate(x=216+1-as.numeric(sx), y=216+1-as.numeric(sy))|>
   select(ld8,x,y,sx,sy,FWHM,snr)

fwhm_snr_region <- d |> select(ld8,age,label,roi,x,y,failqc) |> merge(fwhm, by=c("ld8","x","y"), all.x=T)
write.csv(fwhm_snr_region, 'txt/fwhm_snr.csv', row.names=F,quote=F)

#fwhm_snr_region |> count(ld8, mia=is.na(FWHM)) |> separate(ld8,c('id','date')) |> mutate(date=lubridate::ymd(date)) |> ggplot() + aes(x=date,y=n, color=mia) + geom_point() + theme_bw()
