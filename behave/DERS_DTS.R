#!/usr/bin/env Rscript
suppressPackageStartupMessages({library(dplyr); library(tidyr); library(glue)})

# 20220804WF - init
#   Difficulties in emotion regulation scale (DERS)
#   depenends on 000_getQualtrics.R writing selfreport.csv files
DERS_QUESTIONS <- c(
"I am clear about my feelings.", "I pay attention to how I feel.",
"I experience my emotions as overwhelming and out of control.",
"I have no idea how I am feeling.", "I have difficulty making sense out of my feelings.",
"I am attentive to my feelings.", "I know exactly how I am feeling.",
"I care about what I am feeling.", "I am confused about how I feel.",
"When I’m upset, I acknowledge my emotions.", "When I’m upset, I become angry with myself for feeling that way.",
"When I’m upset, I become embarrassed for feeling that way.",
"When I’m upset, I have difficulty getting work done.", "When I’m upset, I become out of control.",
"When I’m upset, I believe that I will remain that way for a long time.",
"When I’m upset, I believe that I will end up feeling very depressed.",
"When I’m upset, I believe that my feelings are valid and important.",
"When I’m upset, I have difficulty focusing on other things.",
"When I’m upset, I feel out of control.", "When I’m upset, I can still get things done.",
"When I’m upset, I feel ashamed at myself for feeling that way.",
"When I’m upset, I know that I can find a way to eventually feel better.",
"When I’m upset, I feel like I am weak.", "When I’m upset, I feel like I can remain in control of my behaviors.",
"When I’m upset, I feel guilty for feeling that way.", "When I’m upset, I have difficulty concentrating.",
"When I’m upset, I have difficulty controlling my behaviors.",
"When I’m upset, I believe there is nothing I can do to make myself feel better.",
"When I’m upset, I become irritated at myself for feeling that way.",
"When I’m upset, I start to feel very bad about myself.", "When I’m upset, I believe that wallowing in it is all I can do.",
"When I’m upset, I lose control over my behavior.", "When I’m upset, I have difficulty thinking about anything else.",
"When I’m upset I take time to figure out what I’m really feeling.",
"When I’m upset, it takes me a long time to feel better.",
"When I’m upset, my emotions feel overwhelming.")

DTS_QUESTIONS <- c(
"Feeling distressed or upset is unbearable to me.",
"When I feel distressed or upset, all I can think about is how bad I feel.", 
"I can't handle feeling distressed or upset.", "My feelings of distress are so intense that they completely take over.", 
"There's nothing worse than feeling distressed or upset.", "I can tolerate being distressed or upset as well as most people.", 
"My feelings of distress or being upset are not acceptable.", 
"I'll do anything to avoid feeling distressed or upset.", "Other people seem to be able to tolerate feeling distressed or upset better than I can.", 
"Being distressed or upset is always a major ordeal for me.", 
"I am ashamed of myself when I feel distressed or upset.", "My feelings of distress or being upset scare me.", 
"I'll do anything to stop feeling distressed or upset.", "When I feel distressed or upset, I must do something about it immediately.", 
"When I feel distressed or upset, I cannot help but concentrate on how bad the distress actually feels.")


rm_q_prefix <- function(s) gsub('^.*?- |^-','', s)
questions_subset <- function(d, Q=DERS_QUESTIONS)
   d[,which(rm_q_prefix(d[1,]) %in% Q)]

ders_numeric <- function(x)
   stringr::str_extract(x, '\\d+-\\d+') %>%
      factor(levels=c("0-10","11-35","36-65","66-90","91-100")) %>%
      as.numeric

all_surveys <- function(glob="/Volumes/L/bea_res/Data/Temporary Raw Data/7T/1*_2*[0-9]/1*_2*[0-9]_selfreport.csv"){
 l <- Sys.glob(glob)
 d_all <-lapply(l, function(f) read.csv(f) %>% mutate(ld8=LNCDR::ld8from(f)))
}

find_data_row <- function(d) {
  data_row <- nrow(d)
  if(data_row>3) data_row<-2
  if(data_row>=3 && sum(sapply(d[data_row,], function(x) x=="")) > 30) data_row<-2
  return(data_row)
}
add_metadata <- function(d, msg) {
  attr(d,'questions') <- names(d)
  names(d) <- rm_q_prefix(unlist(unname(d[1,])))
  comment(d) <- msg
  return(d)
}

read_ders <- function(d) {
  ld8 <- d$ld8[1]
  # subset to only the ders questions
  d <- questions_subset(d, DERS_QUESTIONS) %>%
     add_metadata(msg=glue("DERS: subset for {ld8}"))

  # only care about the second row
  # turn all columns numeric
  # and put id back in
  data_row <- find_data_row(d)
  d[data_row,] %>%
     mutate(across(everything(),ders_numeric), ld8 = ld8)
}
read_dts <- function(d) {
  ld8 <- d$ld8[1]
  # subset to only the ders questions
  d <- questions_subset(d, DTS_QUESTIONS) %>%
     add_metadata(msg=glue("DTS: subset for {ld8}"))

  # only care about the second row
  # turn all columns numeric
  # and put id back in
  data_row <- find_data_row(d)
  d[data_row,]  %>% mutate(ld8=ld8)
}

remove_empty <- function(d) {
   has_data <- apply(d, 1, function(x) sum(!is.na(x))) > 1
   d <- d[has_data,]
}

all_ders <- function(s=NULL){
   if(is.null(s)) s <- all_surveys()
   d_list <- lapply(s, read_ders)
   d <- bind_rows(d_list)

   # subset to just those with DERS columns. all should have ld8 column.
   d <- remove_empty(d)

   ld8_missing <- setdiff(sapply(s, function(x) x$ld8[1]), d$ld8)
   if(length(ld8_missing)>0L) cat("# missing",length(ld8_missing), "DERS data. responses are precoded or missing? ", head(ld8_missing), "\n")

   # questions isn't a default R attribute. it's not carried over from bind_rows
   # varies by survey battery. no good way to store it. and maybe not useful?
   #attr(d,'questions')  <- attr(d_list[[which(has_data)[1]]],'questions')

   #comment(d) # inhereted from last element in list

   return(d)
}
all_dts <- function(s){
   d_list <- lapply(s, read_dts)
   d <- bind_rows(d_list)
   d <- remove_empty(d) # 20221101: 328/344 survive
}

# if running from command line
# we'll lose 'questions' attribute
if(sys.nframe()==0){

   cat("# collecting all surveys @", Sys.time(),"\n")
   s <- all_surveys()
   cat("# collecting DERS responses @", Sys.time(),"\n")
   ders <- all_ders(s)
   cat("# saving data w/dims",dim(ders)," to txt/ders.csv @", Sys.time(),"\n")
   write.csv(file="txt/ders.csv", ders, row.names=FALSE)

   cat("# collecting DTS responses @", Sys.time(),"\n")
   dts <- all_dts(s)
   cat("# saving data w/dims",dim(dts)," to txt/dts.csv @", Sys.time(),"\n")
   write.csv(file="txt/dts.csv", dts, row.names=FALSE)
}
