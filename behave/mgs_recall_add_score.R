#!/usr/bin/Rscript 

# 
# early recall subjects did not get a score
# this re-implements score in R

# known/direction without maybe yes/maybe no
no_maybes <- function(x, ...) { 
   as.numeric(x) %>%
   ifelse(.==0, 10, .) %>% # make 0 into 10 just for the 'cut' below
   ifelse(.==5, 99, .) %>% # make 0 into 10 just for the 'cut' below
   cut(breaks=c(-Inf, 2, 11, Inf), labels=c(..., "NA")) %>%
   as.character %>%
   ifelse(is.na(.), 'NA', .)
}
# specific for each
set_lr   <- function(x) no_maybes(x, c("left","right"))
set_seen <- function(x) no_maybes(x, c("old","new"))



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
get_score_from_row <- function(d_row, maybe_keys,conf_keys) {
     with(d_row, {

       score=0
       # new 1,2 
       # old 3,4 or 9,0
       ## not actually seen (image is new) 
       if     (see_know == "new" && see_know_key == "new")     return(201) # correctly say new
       else if(see_know == "new" && know_key %in% maybe_keys)  return(101) # said maybe old when new
       else if(see_know == "new" && know_key %in%  conf_keys)  return(  1) # confidently wrong 
       else if(see_know == "new")        stop("unkown new image combo ", know_key, " ",see_know_key) # confidently wrong 
       ## actually saw (image is old) 
       else if(see_know == "old" && see_know_key == "new")      return(0) # wrong
       else if(see_know == "old" && know_key %in% maybe_keys ) score=100  # correct but not confident
       else if(see_know == "old" && know_key %in% conf_keys )  score=200  # confidently correct
       else { stop("unkown combo ", see_know, know_key, see_know_key )}

       # points for correct side
       if (is.na(lr_dir_key) || lr_dir_key == "NA") return(score)
       cat("have side like ", lr_dir_key," ", lr_side, "\n")
       if( lr_dir_key == lr_side ) score=score+5
       if( dir_key == side ) score=score+10
       # all done
       return(score)
  })
}

get_score <- function(d){
   # pull '("0","1")' into seperate columns
   # reduce def/maybe into new (novel) or old (repeat), and near left/right to just left/right
   d <- d %>%
      mutate(corkeys=gsub("[^0-9,]", "", corkeys)) %>%
      separate(corkeys, c("know", "side"), sep=",") %>% 
      mutate(lr_side=set_lr(side),
             lr_dir_key=set_lr(dir_key),
             see_know_key=set_seen(know_key),
             see_know=set_seen(know))

   # some tasks used 3,4 others used 9,0
   conf_keys  <- c(1,0)
   maybe_keys <- c(2,9)
   if (max(as.numeric(d$know),na.rm=T) == 4) {
     conf_keys  <- c(1,3)
     maybe_keys <- c(2,4)
   }

   d$score <- d %>% split(1:nrow(d)) %>% sapply(get_score_from_row,maybe_keys=maybe_keys, conf_keys=conf_keys) 
   return(d)
}

# fix one
d_fixed <-read.csv('10195_20180129_mri_1_recall-a_20185929135903.csv') %>% get_score
d_fixed %>% select(know, know_key, see_know, see_know_key,lr_dir_key, lr_side,side, dir_key, score)

# test on newer
d<-read.csv("/Volumes/L/bea_res/Data/Tasks/MGSEncMem/7T/10129_20180917/01_mri_B/mri_mgsenc-B_20180917/10129_20180917_mri_1_recall-B_20180917184856.csv")
d$score_orig <- d$score
d<-get_score(d)
d %>%
  filter(score != score_orig) %>%
  select(know, know_key, see_know, see_know_key,
         lr_dir_key, lr_side,side, dir_key, score, score_orig) %>%
  print

