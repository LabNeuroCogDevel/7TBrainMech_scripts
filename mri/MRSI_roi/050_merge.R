#!/usr/bin/Rscript
library(dplyr)
library(tidyr)

setwd("/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI_roi/")
source('rest_fd.R')
# merge

# 20200311 - init
gr <- "/Volumes/Hera/Projects/7TBrainMech/subjs/1*_2*/slice_PFC/MRSI_roi/LCModel/v2idxfix"
xyroi <- Sys.glob(sprintf("%s/13MP20200207_picked_coords.txt", gr))
yxcsi <- Sys.glob(sprintf("%s/spectrum*.dir/*csv", gr))
gmcnt <- paste0(dirname(Sys.readlink(xyroi)), "/roi_percent_cnt_13MP20200207.txt")

L <- read.table("roi_locations/labels_13MP20200207.txt", sep=":") %>%
    mutate(roi=1:n()) %>%
    select(roi, label=V1)

G <- gmcnt[file.exists(gmcnt)] %>% lapply(read.table, as.is=T) %>% bind_rows
names(G) <- c("ld8", "gm.atlas", "roi", "GMrat", "GMcnt")

# 20231006 - add manually inspected model fits
#            create column indicating visual qc failed for those annotated
#            see gen_pdf.bash and e.g.
#            pdf/csi_all-gt2022-12-05_n-29_d8-20191017-20230309_slice-PFC_pg1.pdf
# has two formats (remote/MRRC, local/DIY)
#   orig:  luna_date-dateLuna/specturm.yy.xx
#   new:   luna_date/spectrum-yy.xx
# when it doesn't matching the original, make the new look like the old
visqc <-
  readxl::read_xlsx('txt/visual_qc.xlsx', col_names='path_to_qcfail') %>% 
  mutate(title_with_junk =
           ifelse(!grepl('Luna', path_to_qcfail, ignore.case=T),
                  gsub('/','-junk/',path_to_qcfail),
                  path_to_qcfail),
         failqc=TRUE) %>% 
  separate(title_with_junk,
           c("ld8", "mrid", "y","x"),extra="merge", sep = "[-.]") %>%
  select(-mrid)


readcsi <- function(f) {
      d <- read.csv(f) %>% mutate(f=f)
      names(d) <-
          gsub("Cre", "Cr", names(d)) %>%
          gsub("\\.+", ".", .)
      return(d)
}

csi_raw <-
   Filter(function(f) file.size(f) > 0, yxcsi) %>%
   lapply(readcsi) %>%
   bind_rows
csi_extract <- csi_raw %>%
   mutate(ld8=LNCDR::ld8from(f),
          coord=stringr::str_extract(f, "(?<=spectrum.)\\d+.\\d+")) %>%
   separate(coord, c("y", "x"))

cat("visually QC'ed as bad model fit, but no data in $ld8/spectrum*.dir/*csv:\n")
anti_join(visqc,csi_extract) %>%
   group_by(ld8) %>%
   summarise(n=n(), yx=paste(sep=".", collapse=" ",y,x))%>%
   print.data.frame(row.names=F)
cat("maybe these were redone/have more than one model?\n")

csi <- csi_extract %>%
   # 20231006 - reverse coded :( when failqc is na, it's a pass
   #            NB. merge here before we adjust x and y
   left_join(visqc, by=c("ld8","y","x")) %>% 
   mutate(failqc=ifelse(is.na(failqc),FALSE,failqc)) %>%
   # 20200414 - spectrum are oriented differently
   mutate(x=216+1-as.numeric(x), y=216+1-as.numeric(y)) %>%
   select(-f, -Row, -Col)

weird_csi <- csi %>% group_by(ld8) %>% tally %>% filter(n!=13)
if(nrow(weird_csi) > 0L){
    cat("have ", nrow(weird_csi), " without exact expected roi counts in csi!\n")
    print(weird_csi)
    cat("will probably have NaN roi number when x,y merge fails. will keep around\n")
}

roi <- xyroi %>%
    lapply(function(f) read.table(f)[, 1:3] %>%
                       mutate(LNCDR::ld8from(f))) %>%
    bind_rows %>%
    `names<-`(c("roi", "x", "y", "ld8"))

fd <- all7trestdf()
d <-
    merge(roi, csi, by=c("ld8", "x", "y"), all=T) %>%
    merge(L, by="roi", all=T) %>%
    merge(G, by=c("ld8", "roi"), all=T) %>%
    merge(fd, by=c("ld8"), all.x=T)

## get age and sex from DB
query <-
   gsub("_.*", "", d$ld8) %>%
   gsub("^", "'", .) %>%           # add begin quote
   gsub("$", "'", .) %>%           # add ending quote
   paste(collapse=",") %>%         # put commas between
   sprintf("
          select id, sex, dob
          from person
          natural join enroll
          where id in (%s)", .)
#cat("#",query,"\n")
# 20220119 - DB id down. wrote file from backup db
read_backup_dob<-function(){read.table('txt/id_sex_dob.txt', sep="\t",header=T) %>% mutate(dob=lubridate::ymd(dob));}
#r <- tryCatch(stop("testing"), error=function(e) {print(e); read_backup_dob()})
r <- tryCatch(LNCDR::db_query(query), error=function(e) {print(e); read_backup_dob();})

sep <-
   d %>% separate(ld8, c("id", "vdate"), remove=F) %>%
   mutate(vdate=lubridate::ymd(vdate)) 

# 20200504 - have 7 repeat subjects!
visitnum <-
    sep %>% group_by(id,vdate) %>% tally() %>%
    group_by(id) %>% mutate(visitnum=rank(vdate)) %>%
    select(-n)

da <-
   merge(visitnum, sep, all=T) %>%
   merge(r, ., by="id", all=T) %>%
   mutate(age=round(as.numeric(vdate-dob)/365.25, 2)) %>%
   select(-id, -dob, -vdate) %>%
   arrange(ld8, roi, x, y) # sort so version control of output csv is easier

write.csv(da, "txt/13MP20200207_LCMv2fixidx.csv", row.names=F)
