require(dplyr)
require(tidyr)

# global stores where the files are
TXTDIR <- "/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI_roi/txt"

read_mgs_eog <- function(){
  eog <- read.csv(file.path(TXTDIR,'eeg_data_20200929.csv'))
}

read_ages <- function(){
  ages <- read.table(file.path(TXTDIR,"all_demo.tsv"), sep="\t")
}


# 1. Read in
# TODO/NOTE: age2 is centered but invage is not
read_mrs <- function() {
    # "~/Desktop/Lab/Projects/2020_MRSMGS/
    MRS_csv <-  file.path(TXTDIR, "13MP20200207_LCMv2fixidx.csv")

    #### Get data and remove bad quality data ####
    # cooridantes in DICOM "RAI" orientation. want LPI
    # know we have 216x216 grid. just reverse: 1->216; 216->1
    # als add varations on age
    MRS_all <- read.csv(MRS_csv) %>%
        mutate(x=216+1-x,
               y=216+1-y,
               invage = 1/age,
               age2   = (age-mean(age))^2)

}

# 1.1: Remove visually/manually identified
remove_bad_spectrum <- function(MRS_all){
    LCM_xlsx <- file.path(TXTDIR, "lcm.xlsx")
    # Step 1 Outlier Detection
    # have already visual inspected LCModel fits/spectra
    # all bad are annotated in this xlsx sheet
    # with a single column of path to bad spectrum. like:
    #
    #   11299_20180511-20180511Luna/spectrum.123.57  
    #   11451_20180216-20180216Luna1/spectrum.123.59 
    lcm <- readxl::read_excel(LCM_xlsx, col_names = FALSE)
    # turn file path into id and corridnate
    lcm <- separate(lcm, "...1", c("ld8", "junk","y","x"),
                    extra="merge",
                    sep = "[-.]") %>%
            select(-junk)
    # all in this sheet are bad    
    lcm$bad <- TRUE

    # remove any in lcm (list of bad) from dataframe of all
    MRS <- merge(MRS_all, lcm,
                 by=c("ld8", "x", "y"),
                 all=T)  %>%
           filter(is.na(bad)) %>%
           select(-bad)

    # na roi could have been added here or already exist in data?
    MRS <- MRS %>% filter(!is.na(roi))
}

# 1.2 - only care about visit 1
only_visit1 <- function(MRS) {
    #keep only visit 1 people
    MRS <- MRS %>% filter(visitnum==1)
    #keep people's correct coordinates
    #get rid of people who are actually visit 2 but for some reason aren't filtered out
    MRS <- MRS %>% filter(ld8!="10195_20191205")
}

remove_metabolite_thresh <- function(MRS) {
    # Step 2 Outlier Detection - get rid of peole who have bad data for 3 major metabolite peaks - GPC+Cho, NAA+NAAG, Cr
    # TODO: keep NA?
    MRS <- filter(MRS, GPC.Cho.SD <= 10 | is.na(GPC.Cho.SD))
    MRS <- filter(MRS, NAA.NAAG.SD <= 10 | is.na(NAA.NAAG.SD))
    MRS <- filter(MRS, Cr.SD <= 10 | is.na(Cr.SD))

    # Step 3 Outlier Detection - get rid of people who have lots of macromolecule in their spectra, as that can create distortions
    MRS <- filter(MRS, MM20.Cr <= 3 | is.na(MM20.Cr))
}


# use it all together to get MRSI data
get_mrs <- function(){
    MRS <-
        read_mrs() %>%
        remove_bad_spectrum %>%
        only_visit1 %>%
        remove_metabolite_thresh
}
