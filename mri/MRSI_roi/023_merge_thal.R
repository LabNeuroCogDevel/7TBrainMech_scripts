#!/usr/bin/env Rscript
pacman::p_load(dplyr,stringr) 

##-- funcs ---
## TODO: this should go into funcs.R also for ./06_fwhm_snr.R
# d must have 'fname'
cord_cols_extract <- function(d) d |>
        mutate(coord=stringr::str_extract(fname, "\\d+.\\d+(?=.dir/)")) |>
        separate(coord, c("sy", "sx")) |>
        mutate(x=216+1-as.numeric(sx), y=216+1-as.numeric(sy))

fwhm_from_glob <- function(path_glob='/Volumes/Hera/Projects/7TBrainMech/subjs/*/slice_PFC/MRSI_roi/ThalRedo/*.dir/csi.coord') {
    grep_res <- system(glue::glue('grep FWHM {path_glob}'), intern=T)
    fwhm_df <- read.table(text=grep_res, col.names=c('fname','junk1_fwhm','junk_eq','FWHM','junk_ppm','junk_sn','junk_eq2','snr'))
    fwhm <- fwhm_df |> cord_cols_extract() |>
        select(x,y,sx,sy,FWHM,snr,fname)
}

## -- merge 
# would be nice to read in all at once. but column names aren't consistant! LCModel does weird things?
#d <- readr::read_csv(Sys.glob('/Volumes/Hera/Projects/7TBrainMech/subjs/*/slice_PFC/MRSI_roi/ThalRedo/*/spreadsheet.csv'), id='fname')
# # File 1 column 5 is: Asp/Cre ; File 180 column 5 is: Asp/Cr

lcmodel_outs <- Sys.glob('/Volumes/Hera/Projects/7TBrainMech/subjs/*/slice_PFC/MRSI_roi/ThalRedo/*/spreadsheet.csv')
d <- lapply(lcmodel_outs,
       \(f) read.csv(f) |> rename_with(\(n) gsub('\\.Cre','\\.Cr',n)) |> mutate(fname=f)) |>
    bind_rows() |>
    mutate(ld8=str_extract(fname, '\\d{5}_\\d{8}')) |>
    cord_cols_extract()

# get line width (FWHM) from control LCModel output file
fwhm_df <- fwhm_from_glob() |> mutate(ld8=str_extract(fname, '\\d{5}_\\d{8}'))

# combine the lcmodel output and fwhm
m <- merge(d, fwhm_df|>select(-fname), by=c('ld8','sy','sx','x','y'), all=T) |>
    mutate(region=str_extract(fname, '[RL]Thal'),
           gm=str_extract(fname,'(?<=gm-)\\d+'))

write.csv(m, 'txt/ThalRedo.csv', row.names=F, quote=F)
