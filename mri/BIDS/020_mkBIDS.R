#!/usr/bin/env Rscript

# make niftis in BIDS dir format
# expect raw dicoms like rawlinks/subj_date/seqno_protcol_ndcm
# output nii.gz into sub-$lunaid/$vdate/{anat,func}/*.nii.gz
setwd("/Volumes/Hera/Raw/BIDS/7TBrainMech/")

library(dplyr)
write_and_note <- function(f, cmd) {
   if (!file.exists(f)) {
      system(cmd)
      system(sprintf('3dNotes -h "%s" %s', cmd, f))
   }
}

dirlist <- Sys.glob("rawlinks/1*_2*/*/")

info <-
   lapply( strsplit(dirlist, "[/_]"),
         function(x) {
            x <- as.list(x)
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
             info$ndcm == 9216,
  rest= grepl("bold.*(REST|tacq2s-180).*", info$protocol) &
             info$ndcm == 10560
)

# -- apply assignments
info$process <- NA
# ugly `<<-`, reader beware -- code might burn your eyes
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
   mutate(item=rank(as.numeric(seqno)),
          type=ifelse(process=="t1", "anat", "func"),
          name=sprintf("sub-%s_task-%s_run-%02d_bold", luna, process, item),
          outdir=sprintf("sub-%s/%s/%s/", luna, vdate, type) )

# rename file for anat
t1idx <- proc$type=="anat"
proc$name[t1idx] <- gsub("_task.*", "_T1w", proc$name[t1idx])

# described expected final outputfile
proc$file <- sprintf("%s/%s.nii.gz", proc$outdir, proc$name)

# and the command to create it
proc$cmd <- sprintf("dcm2niix -o %s -f %s %s",
                    proc$outdir, proc$name, proc$indir)

print(proc)
# create directories and nifti files
discard <-
  lapply(proc$outdir, function(x) dir.exists(x) || dir.create(x, recursive=T) )

discard <-
  mapply(function(f, cmd) write_and_note(f, cmd), proc$file, proc$cmd )
