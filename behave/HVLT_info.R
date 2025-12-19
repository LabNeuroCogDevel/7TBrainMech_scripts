#!/usr/bin/env Rscript
# 20251219WF - init
#   
# explore txt/HVLT/HVLTY{1,2}_1{A,B}_Part{A,B}.csv
# created by HVLT.R


library(dplyr)

# read in all
HVLT <- lapply(Sys.glob('txt/HVLT/*PartA.csv'),
               \(f) #read.csv(f, colClasses='character') |>
                    read.csv(f) |>
                    transmute(ID, sex=as.character(sex), age,
                              VisitType, VisitYear, VisitType=gsub('Behv','Beh',VisitType),
                              time=as.character(time_started), trial, percent_correct,
                              file=f)) |>
    bind_rows()


## quick summary
HVLT |> group_by(VisitYear, VisitType, version=stringr::str_extract(file,"(?<=_1)[AB]")) |>
    summarise(nID = length(unique(ID)),
              age = mean(age,na.rm=T),
              correct = mean(percent_correct)) 

# VisitYear VisitType  version   nID   age correct
#     <int> <chr>      <chr>   <int> <dbl>   <dbl>
#         1 Behavioral A         217  18.4   0.770
#         1 Behavioral B           1  24.0   0.729
#         2 Behavioral A          96  19.7   0.794
#         2 Behavioral B           1  15.5   0.375
#         2 EEG        B           1  15.3   0.854
#         3 Behavioral A          48  21.4   0.835
#         3 EEG        B           1  14.0   0.500

## different versions?

# 1A vs 1B reference set of words to recall (?)
xnames <- function(f) read.csv(f) |> names() |> toupper() %>% gsub('[^A-Z]','',.) |> sort()
a <- xnames('./txt/HVLT/HVLTY1_1A_PartA.csv')
b <- xnames('./txt/HVLT/HVLTY1_1B_PartA.csv')
setdiff(a,b) |> dput()
#c("CAVE", "COW", "EMERALD", "HORSE", "HOTEL", "HUT", "LION", "OPAL", "PEARL", "SAPPHIRE", "TENT", "TIGER")
setdiff(b,a) |> dput()
# c("BOMB", "BOURBON", "FORK", "PAN", "PISTOL", "POT", "RIFLE", "RUM", "SPATULA", "SWORD", "VODKA", "WINE")


pa <- xnames('./txt/HVLT/HVLTY1_1A_PartA.csv')
pb <- xnames('./txt/HVLT/HVLTY1_1A_PartB.csv')
setdiff(pa,pb)
setdiff(pb,pa) # b has 'n false positive' and additional word columns(?)
