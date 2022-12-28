library(stringr)
library(purrr)
library(dplyr)
library(tidyr)
library(LNCDR)

# mgs_recall.py -- but not for all subjects
# ---- scores ----
# -- didn't see  
# 1   = said saw (but didn't)
# 101 = said maybe didn't
# 201 = confidently correct
# --- did see
# 0 = said didn't
# 100 = maybe known
# 200 = confidently correct
# -- side
# +5  = correct side    (105, 205)
# +15 = exactly correct (115,215)

get_key_known <- function(key) ifelse(key %in% c(1, 2), "K",
                                 ifelse(key %in% c(9, 0), "U", "WTF"))
get_key_side <- function(key) ifelse(key %in% c(1, 2), "L",
                                 ifelse(key %in% c(9, 0), "R", "U"))
# input: known correct, pushed, direction correct, pushed
score_keys <- function(kc, kp, dc, dp) {
   score<-0
   # actually uknown (unseen)
   #if ( get_key_known(kc) == "U" ) {
   if (kc == 0 ) {
      if ( get_key_known(kp) == "K" )  return(1)
      # more certian, more points
      else if ( kp == 0 ) score <- 201
      else if ( kp == 9 ) score <- 101
      else return(NA)
   } else {
      # did actually see
      #   but said do not know
      if ( get_key_known(kp) != "K" )  return(0)
      # more certian, more points
      else if ( kp == 1 ) score <- 200
      else if ( kp == 2 ) score <- 100
      else return(NA)
      # add points for correct side
      if ( get_key_side(dc) == get_key_side(dp) ) {
         score <- score + 5
      }
      if ( !is.na(dp) &&  dc == dp ) {
         score <- score + 10
      }
   }
   return(score)
}

skv <- Vectorize(score_keys)

add_imgset <- function(d) {
   # extract imgset from imagefile when we don't already have it
   if(!any(is.na(d$imgset))) return(d$imgset)
   d$imgfile[d$imgfile!=""] %>% first %>% str_extract("(?<=^img.)[A-Z]")
}


task_globs <- function(ld8s, filepatt="*recall*[0-9].csv") {
  # filepatt="*view.csv" for view
  task_dir <- "/Volumes/L/bea_res/Data/Tasks/MGSEncMem/7T/"
  #task_dir <- "~/scratch/7tmgs/1d/"
  # weirder bad copies (~40ish of these)
  # /Volumes/L/bea_res/Data/Tasks/MGSEncMem/7T/{11816_20200203,11735_20190719}/
  #  01_mri_A/01/mri_mgsenc-A_20200203/11816_20200203_mri_1_recall-A_20200203165706.csv
  #     11735/01/mri_mgsenc-A_20190719/
  task_subdir <- c("/*/",
                          "/0[0-5]/mri_mgsenc*/", 
                       "/1*/0[0-5]/mri_mgsenc*/",
                    "/*mri*/0[0-5]/mri_mgsenc*/")
  g <- expand_grid(task_dir, ld8s, task_subdir, filepatt)
  allcombos <- apply(g, 1, paste0, collapse="")
  taskfiles <- Sys.glob(allcombos) %>% unique

  if(length(taskfiles)==0L)
     warning("no files matching: ", task_dir,
             paste(collapse=",",ld8s),
             "{",paste(collapse=",",task_subdir),"}",
             filepatt)
  return(taskfiles)
}

mk_recall <- function(ld8s=c("1*_2*")){
  recall_files_all <- task_globs(ld8s, "*recall*[0-9].csv")
                                 
  cat("# expect there to be only 1 recall file per ld8\n")
  ld8from(recall_files_all) %>% sort %>% rle %>% with(data.frame(ld8=values,nfiles=lengths)) %>% filter(nfiles!=1) %>% print
  recall_files <- recall_files_all[ ! ld8from(recall_files_all) %>% duplicated]
  recall <- data.frame(stringsAsFactors=F,
              recall_f = recall_files,
              ld8      = str_extract(recall_files, "\\d{5}_\\d{8}"),
              imgset   = str_extract(recall_files, "(?<=mri_)[A-Z]")) %>%
     mutate( contents=map(recall_f, read.csv)) %>%
     unnest(cols = c(contents)) %>%
     select(-recall_f) %>%
     mutate(corkeys=gsub("[)(']", "", corkeys)) %>%
     separate(corkeys, c("know_cor", "dir_cor")) %>%
     # redo score because some are missing it :(
     mutate(score_r = skv(know_cor, know_key, dir_cor, dir_key)) %>%
     group_by(ld8) %>% mutate(imgset=add_imgset(.data))
  
  # 20180705 -- check against score, all same
  if (recall %>% filter(!is.na(score), score!=score_r) %>% nrow > 0L)
     stop("bad scoring: python task and R do not match")
  return(recall)
}

#### read task files
mk_onsets <- function(ld8s="1*_2*") {
  tasklog <- task_globs(ld8s, "*view.csv")
  cat("# expect 3 onset 'view.csv' files per ld8\n")
  ld8from(tasklog) %>% sort %>% rle %>% with(data.frame(ld8=values,nfiles=lengths)) %>% filter(nfiles!=3) %>% print
  
  read_onsets <- function(f) read.csv(f) %>%
     mutate(block = gsub(".*_([1-4])_view.csv", "\\1", f),
            ld8   = str_extract(f, "\\d{5}_\\d{8}"),
            )
  onsets <- lapply(tasklog, read_onsets) %>% bind_rows
  
  cat("# expect summarised onsets to have 3 blocks of 24 trials\n")
  onsets %>% group_by(ld8) %>% summarise(blk_mx=max(trial),ntotal=n()) %>% group_by(blk_mx,ntotal) %>% tally %>% print
  return(onsets)
}

onset_recall <- function(ld8s="1*_2*") {
  MGSDUR <- 2 # how long is mgs on for (before fixation ITI starts)
  recall <- mk_recall(ld8s)
  onsets <- mk_onsets(ld8s)
  d <- merge(onsets, recall, by=c("ld8", "imgfile"), all.x=T) %>%
     arrange(ld8, block, cue)
  d$dur <- d$mgs - d$cue + MGSDUR
  
  cat("# expect merged onsets+recall to have same summary count (ntotal=72)\n")
  d %>% group_by(ld8) %>% summarise(blk_mx=max(trial),ntotal=n()) %>% group_by(blk_mx,ntotal) %>% tally %>% print
  
  ## write out 1d files
  oned_ready <- d %>%
     mutate(coarse_side = gsub("Near", "", side),
            hasimg      = ifelse(imgtype.x=="None", "noimg", "img"))
  
}

# TODO: this should be reworked and put into LNCDR
write_oned_by_fname <- function(oned_ready, col_1d="cue", dur_col='dur', redo=FALSE){
 if(!all(c("fname",col_1d,"dur") %in% names(oned_ready)))
    stop("missing column names")
 split(oned_ready, oned_ready$fname) %>%
    lapply(function(x) {
            fname <- first(x$fname)
            if(file.exists(fname) && !redo) {cat("skip", fname,"\n"); return(fname)}
            dname <- dirname(fname)
            if(!dir.exists(dname)) dir.create(dname,recursive=TRUE)
            save1D(x, colname=col_1d, dur=dur_col, nblocks=3, fname=fname)})
}
