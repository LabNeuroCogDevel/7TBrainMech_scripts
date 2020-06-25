#!/usr/bin/env Rscript
suppressPackageStartupMessages({library(dplyr)})

# ranking sequence number doesn't always work
# sometimes we redo!
# use 0 to drop
hfixfile <- '/Volumes/Hera/Projects/7TBrainMech/scripts/mri/BIDS/hardcode.txt'
hardcode_fix <- read.table(hfixfile,comment.char='#', header=T) %>%
   mutate(folder=gsub('/Volumes/Hera/Raw/BIDS/7TBrainMech/rawlinks/','', folder) %>%
                 gsub('_','/',.) %>% gsub('/$','',.)) %>%
   tidyr::separate(folder, c('luna','vdate','seqno','protocol','count'), sep='/',extra="drop") 

# make niftis in BIDS dir format
# expect raw dicoms like rawlinks/subj_date/seqno_protcol_ndcm
# output nii.gz into sub-$lunaid/$vdate/{anat,func}/*.nii.gz
setwd("/Volumes/Hera/Raw/BIDS/7TBrainMech/")

write_and_note <- function(f, cmd) {
   if (!file.exists(f)) {
      system(cmd)
      system(sprintf('3dNotes -h "%s" %s', cmd, f))
   }
}

args <- commandArgs(trailingOnly=TRUE)
if(length(args)>0L) {
   matchesrawlink <- grepl('rawlinks/',args)
   if(!all(matchesrawlink)) stop('inputs must be rawlink directories!\n Bad inputs:', paste("\n\t", args[!matchesrawlink]))
   dirlist <- lapply(args,function(x) gsub('^.*rawlinks/', 'rawlinks/', x) %>% gsub("/$", "", .) %>% paste0('/*/') %>% Sys.glob) %>% unlist
} else {
   dirlist <- Sys.glob("rawlinks/1*_2*/*/")
}

# need something to process
stopifnot(length(dirlist)>0L) 

info <-
   lapply( strsplit(dirlist, "[/_]"),
         function(x) {
            x <- as.list(x)
            if(length(x) != 6) {
               cat("getting info from path failed (", length(x), "items instead of raw,l,vd,s#,prt,#dcm)! ",
                   paste(x,collapse=" "), '\n')
               x <- c(x[1:length(x)], rep(NA,max(6-length(x),0)))
            }
            names(x)<-c("raw", "luna", "vdate", "seqno", "protocol", "ndcm")
            as.data.frame(x)
         }) %>%
   bind_rows %>%
   mutate(indir=dirlist) %>%
   select(-raw)

# -- identify the things we want to keep
idxs <- list(
             #^MP2RAGE.*T1-Images
  t1 = grepl("^MP2RAGEPTX.TR6000.*.UNI.DEN$", info$protocol, perl=T) &
           info$ndcm %in% c(256, 192),
  MGS= grepl("bold.*(TASK|MGS|tacq2s-180).*", info$protocol) &
             info$ndcm %in% c(9216,192), # 20191220 -  allow new mosaic 192
  rest= grepl("bold.*(REST|tacq2s-180).*", info$protocol) &
             info$ndcm %in% c(10560,220), # 20191220 -  allow mosaic 220
  # e.g. ../../BIDS/rawlinks/11667_20180629/0035_mtgre-yesMT_44
  #       ../../BIDS/rawlinks/11667_20180629/0036_mtgre-noMT_44
  MT= grepl("mtgre-(yes|no)MT", info$protocol) & info$ndcm == 44
)

if (!any(lapply(idxs, any)))
   stop("no matching protocols in input!\n",
        info %>%
         filter(grepl("MP2RAGE|bold", protocol)) %>%
         print.data.frame(max=99) %>%
         capture.output %>%
         paste(collapse="\n\t"))

# -- apply assignments
info$process <- NA
# ugly `<<-`, reader beware -- code might burn your eyes
# cumlative count to get run number
discard <-
   mapply(function(i, n) info$process[i] <<- n, idxs, names(idxs))

# --- setup file and directory names, and dcm2nii command to run
# like
#   {session}/anat/sub-{subject}_T1w
#   {session}/func/sub-{subject}_dir-{acq}_task-rest_run-{item:02d}_bold
#   {session}/func/sub-{subject}_task-mgs_run-{item:02d}_acq-{acq}_bold
proc <- info %>%
   filter(!is.na(process)) %>%
   group_by(luna, vdate, process) %>%
   mutate(item=rank(as.numeric(seqno))) %>%
   # hard code a fix for some weirdos
   left_join(hardcode_fix, by=c("luna","vdate","protocol","seqno"),
             suffix=c("", ".fix")) %>%
   # drop any where the fix item number is 0
   filter(is.na(item.fix) | item.fix != 0) %>%
   # and update any where if is not NA
   mutate(item=ifelse(is.na(item.fix),item,item.fix),
          # t1-> anat, MGS|REST->func, MT->mt
          type=ifelse(process=="t1", "anat", "func"),
          type=ifelse(process=="MT", "mt", type),
          # name actually only for bold. anat and mt will be changed later
          name=sprintf("sub-%s_task-%s_run-%02d_bold", luna, process, item),
          outdir=sprintf("sub-%s/%s/%s/", luna, vdate, type) )



# ranking by seqno might be bad. espcially if we failed to copy in run1
mgsidx<-!is.na(proc$process) & proc$process=='MGS'  
mgsrunno <- proc$protocol[mgsidx] %>% stringr::str_extract('(?<=MGS-)\\d+') %>% as.numeric %>% ifelse(is.na(.), 0, .)
suspectidx <- which(mgsidx)[proc$item[mgsidx] != mgsrunno & mgsrunno != 0]
suspect <- proc[suspectidx,c('luna','vdate','item','seqno', 'protocol')] %>% arrange(luna,seqno,item)
suspect %>% select(luna,vdate) %>% mutate(process='MGS') %>% unique %>% inner_join(proc) %>%
   select(luna,vdate,item,seqno,protocol) %>%
   print.data.frame(row.names=F)

# rename file for anat
t1idx <- proc$type=="anat"
proc$name[t1idx] <- gsub("_task.*", "_T1w", proc$name[t1idx])

# rename mt
mtidx <- proc$type=="mt"
proc$name[mtidx] <- gsub("_task.*", "_MT_acq-%s", proc$name[mtidx]) %>%
   sprintf(stringr::str_match(proc$protocol[mtidx], "yes|no"))

# described expected final outputfile
proc$file <- sprintf("%s/%s.nii.gz", proc$outdir, proc$name)

# and the command to create it
proc$cmd <- sprintf("dcm2niix -o %s -f %s %s",
                    proc$outdir, proc$name, proc$indir)

print.data.frame(proc)
# create directories and nifti files
discard <-
  lapply(proc$outdir, function(x) dir.exists(x) || dir.create(x, recursive=T) )

discard <-
  mapply(function(f, cmd) write_and_note(f, cmd), proc$file, proc$cmd )
