#!/usr/bin/env Rscript

#
# 20180911 WF MP - read in all subject daw task files (generated from daw2csv.m)
#

# find all the daw txt files
allfiles <- Sys.glob("/Volumes/Hera/Projects/7TBrainMech/subjs/*/daw/daw_*.txt")

# read in just one file as data.frame 'd'
#   d <- read.csv(allfiles[[1]])
#   # same as
#   d <- read.csv("/Volumes/Hera/Projects/7TBrainMech/subjs/10129_20180829/daw/daw_10129_20180829.txt")

# read in all: run 'read.csv' on each file in the allfiles list. makes a new list of data.frames
d_list <- lapply(allfiles, read.csv)

# combine into one data.frame, see also ?dplyr::bind_rows
# 1) rbind binds rows of dataframes together (combines them over length -- width stays the same)
# 2) do.call simplifies writting 'rbind(d_list[[1]], d_list[[2]], d_list[[3]], ....)'
d <- do.call(rbind, d_list)
write.csv(d,'all_daw.csv',row.names=F)
