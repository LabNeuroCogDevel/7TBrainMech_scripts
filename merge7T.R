#!/usr/bin/env Rscript

##
# read various sources of information into a too-many-columns file.
# timepoint per row (beh, eeg, and MR on one line)
#
# see Makefile for individual file source
#
# modelled after mergePet.R
# /Volumes/Phillips/mMR_PETDA/scripts/mergePet_functions.R
##
#
# 20230518WF - init
# 20230531WF - update MRS to use gamadj
# 20240216WF - annotate resting state MRI "lost" scans
#
setwd("/Volumes/Hera/Projects/7TBrainMech/scripts/")
suppressPackageStartupMessages({
library(dplyr); library(tidyr)})
library(glue)
source('merge_funcs.R') # addcolprefix, lunadatemerge, check_datecol

# eeg file names have date typo. eeg.date extracted from that. corrected here
rewrite_date<-function(d,l, datecol='eeg.date'){
    # data.frame(lunaid=c(1,2,3,1,3),eeg.date=c(1,1,1,2,2)) %>% rewrite_date(list("1_1"="10", "3_2"=20))
    id_date <- names(l)
    all_ld8 <- paste(sep="_",d$lunaid,d[[datecol]])
    for(i in seq_along(id_date)){
        d[all_ld8 %in% id_date[i], datecol] <- l[[i]]
    }
    return(d)
}
eeg_newdates <- list('11632_20190101'='20191001',
                     '11678_20180116'='20181016',
                     "11668_20170710"="20180710",
                     "11670_20210823"="20210824",
                     "11672_20220617"="20220615")

# 20240122 - 1 person 2 lunaids! twice.
# 11390 and 11665 both have the same data repeated
# list name is replaced by list value
SAME_LUNA <- list('11748'='11515', '11665'='11390')
SAME_LUNA_df <- data.frame(lunaid=unname(unlist(SAME_LUNA)), alt.lunaid=names(SAME_LUNA))
RM_LUNA <- c('11467') # one visit sneaking in on eeg data. not a 7T participant
# these are dropped after disclosing/discovering exclusion criteria
RM_LUNA <- c(RM_LUNA, "11646", "11659", "11800", "11653", "11690", "11812")
rewrite_luna<-function(d, id_col='lunaid', same_luna=SAME_LUNA){
   d$lunaid <- gsub('11748; 11515','11515', d$lunaid)

   bad_luna_row<-d[,id_col] %in% RM_LUNA
   if(any(bad_luna_row)){
      cat("WARNING: non-7T LunaID removed\n")
      print(d[bad_luna_row,])
      d <- d[!bad_luna_row,]
   }
   # write lunaid from alt to used
   # NB. d[,id_col] BAD SYNTAX. collapses xlsx dataframe column into single value?!
   df_ids <- d[[id_col]]
   for(bad_id in names(same_luna)){
      has_bad_id <- df_ids %in% bad_id
      if(!any(has_bad_id)) next
      good_id <- same_luna[[bad_id]]
      print(glue("WARNING: change id {bad_id} to {good_id}"))
      d[has_bad_id, id_col] <- good_id
   }
   dedupped <- unique(d)

   if(nrow(dedupped)!=nrow(d)){
      cat("# alt id rewrite weirdness? (reporting that both ids exist in dataset -- dups will be removed. could be okay)\n")
      # TODO: assuming lunaid is id_col (as of 20240219, it always is)
      print(d[d$lunaid %in% unlist(SAME_LUNA),] %>%
            mutate(is_dup=duplicated(.)) %>%
            merge(SAME_LUNA_df,by='lunaid',all.x=T))
      cat("---\n")
   }
   check_date_dups(dedupped)

   return(dedupped)
}

# for anything built on duplicated preproc visit folders
# stochastic warp and despike (tat2, fd) mean slightly different data.
# not removed with simple unique
rm_dup_lunaid <- function(d) filter(d, !lunaid %in% SAME_LUNA_df$alt.lunaid)

#
# all file paths we need to merge
# also see Makefile for what scripts might make these
files <- list(
 gdoc="txt/7T_packet.xlsx",
 sess="txt/sessions_db.txt",
 # see mri/MRSI_roi/gam_adjust/Makefile
 mrsi="mri/MRSI_roi/gam_adjust/out/gamadj_wide.csv",
 # see mri/tat2/Makefile
 tat2="mri/tat2/maskave.csv",
 # see eeg/Shane/python/fooof/runFooof.py
 #fooof="eeg/Shane/fooof/Results/allSubjectsFooofMeasures_20230516.csv", # channel no region
 fooof="eeg/Shane/Results/FOOOF/Results/allSubjectsDLPFCfooofMeasures_20230523.csv", # region no channel
 # eeg/Shane/Rscripts/spectral_events_wide.R # 20230623
 #  Gamma eeg file renamed, updated 20231117
 eegspec="eeg/Shane/Results/Spectral_Analysis/Spectral_events_analysis/Gamma/Gamma_DLPFCs_spectralEvents_wide.csv",
 # 20231009 - switch to python for hurst and dfa
 # see mri/hurst/hurst_nolds.py
 hurst_brns="mri/hurst/stats/MRSI_pfc13_brnsdkm_hurst_rs.csv",
 hurst_ns="mri/hurst/stats/MRSI_pfc13_nsdkm_hurst_rs.csv",
 dfa_brns="mri/hurst/stats/MRSI_pfc13_brnsdkm_dfa.csv",
 dfa_ns="mri/hurst/stats/MRSI_pfc13_nsdkm_dfa.csv",
 #hurst="mri/hurst/stats/MRSI_pfc13_H.csv", #remove matlab hurst see mri/hurst/hurst.m

 #mgs_eog="eeg/eog_cal/eye_scored_mgs_eog.csv" # 20230612
 mgs_eog="eeg/eog_cal/eye_scored_mgs_eog_cleanvisit.csv", # 20230616. new cleaned version
 sr="behave/txt/SR.csv", # 20230620. pulled from db from RA matained sheets
 ssp="behave/txt/SSP.csv",  # 20230717. from behave/SSP_Cantab_spatial.R
 sex="txt/db_sex.csv", # 20230718 all sex in DB
 adi="/Volumes/Hera/Projects/Maria/Census/parguard_luna_visit_adi.csv", # 20230807, updated 20240118
 fd="mri/txt/rest_fd.csv", # 20230912 (but generated long ago)
 antiET="behave/txt/anti_scored.csv", # 20231101 (for MP)
 # eeg_dlpfc_snr="eeg/Shane/Results/SNR/allSubjectDLPFC_SNRMeasures_20231113.csv" # 20231113
 eeg_dlpfc_snr="eeg/Shane/Results/SNR/allSubjectDLPFC_SNRMeasures.csv", # 20231204
 eeg_pc1_snr="eeg/Shane/Results/SNR/SNRmeasures_PC1_allStim.csv", # 20240214 #eeg/Shane/Rscripts/SNR/createImputed_PCAdataframes.R
 lost_rest="txt/WF_rest_file_QC.tsv" # 20240216 - hand annotated rest data notes

)

## 7T "Packet". RA organized "ground truth" for study visits
# is in longer, row per visit type. Want wider row per visit (across all types)
overview_raw <- readxl::read_excel(files$gdoc, sheet="Overview") %>% mutate(ID=as.character(ID)) %>% filter(!is.na(ID))
topsheet_raw <- readxl::read_excel(files$gdoc, sheet="Top")

# top sheet was abandoned by MM. Overview sheet is up to date
# but top sheet has some drop status that is interesting. so we keep it
topsheet_overview <- merge(overview_raw,topsheet_raw,
                           all.x=T, by=c("7TROWID","VisitType","Date")) %>%
   # 20240213: 59 missing visit year in overview fixed by MP+AF.
   # cf. Top has 114 is.na(VisitYear.y) 
   mutate(VisitYear=ifelse(!is.na(VisitYear.x),VisitYear.x,VisitYear.y))

# clean IDs (remove double ID ; separator), rename columns, match visit type names to DB/session
topsheet_long <- topsheet_overview %>%
   transmute(lunaid=gsub('\\.0$','',as.character(ID)), # lunaid column not labeled. comes in like 11702.0
             date=format(Date,"%Y%m%d"), # match ymd "d8" format
             vscore=Rating_0_5,
             vdrop=VisitDropped,
             sdrop=SubDropped,
             dropreason=ReasonDropped,
             # need these and would be lost otherwise (transmute) so renaming while it's free
             visitno=VisitYear, vtype=VisitType, notes) %>% # top.demo=Demographics,
   filter(!is.na(vtype)) %>%
   mutate(vtype=case_when(vtype== "EEG"~"eeg",
                          vtype=="Behavioral"~"behave",
                          vtype=="MRI"~"mri")) # rest could be sipfc or hpc?
# widen to row per visit. per type columns for date,score,notes, and drops
topsheet <- topsheet_long %>%
   pivot_wider(names_from=c("vtype"),
               id_cols=c("lunaid","visitno"),
               values_from=c("date","notes","vscore", "vdrop","sdrop","dropreason"),
               names_glue="top.{vtype}.{.value}",
               values_fn=\(x) paste0(x,collapse=";")) %>%
   select(-matches('(eeg|behave).notes'))  %>%
   filter(!is.na(visitno))

## DB session info
# "pull_from_sheets" elsewhere uses google calendar, 7T scan files, and p participation flow to get sessions
# hard coding some missing data while that is being debugged (20240219). unique after for when they are added
sess <- read.table(files$sess, sep="\t", header=T) %>%
   rename(lunaid=`id`) %>%
   rbind(c(11904,"1",'Scan',20230727,15.68,"M",2.5,"")) %>% # TODO: this shoud be in DB. not hard coded here
   rbind(c(11695,"1",'Scan',20201106,15.84,"F",1,"")) %>% # TODO: this shoud be in DB. not hard coded here
   rbind(c(11945,"1",'eeg' ,20230829, 12.5,"F",5,""))   %>% # TODO: this shoud be in DB. not hard coded here
   mutate(across(c(lunaid,visitno,vdate,age,vscore), as.numeric)) %>%
   unique

sex <- read.table(files$sex,col.names=c("lunaid","sex"))
behave <- sess %>%
         filter(vtype=="Behavioral",!is.na(visitno)) %>%
         select(lunaid,visitno,behave.date=vdate, behave.age=age) %>%
         merge(topsheet %>% select(lunaid,visitno,top.behave.date) %>% filter(!is.na(visitno)),
               all=T, by=c("lunaid","visitno")) %>% 
         mutate(behave.date=ifelse(is.na(behave.date),top.behave.date,behave.date)) %>% select(-top.behave.date)
mrsi <- read.csv(files$mrsi)
tat2 <- read.csv(files$tat2)
fooof <- read.csv(files$fooof)
fd <- read.table(files$fd,header=T) %>%
   rename(lunaid=id, date=d8) %>%
   addcolprefix('rest') %>%
   rm_dup_lunaid
antiET <- read.csv(files$antiET,header=T) %>%
   filter(! ld8 %in% c("11786_20210310")) %>% # beh visit with no imaging data. redone in 2022
   separate(ld8,c('lunaid', 'behave.date')) %>%
   rename_with(\(x) gsub('^AS','',x)) %>%
   select(-age,-sex,-visitno) %>%
   addcolprefix('antiET', preserve=c("lunaid", "behave.date"))
mgs_eog_visit <- read.csv(files$mgs_eog)
sr <- read.csv(files$sr) %>% addcolprefix('sr') %>%
      rename(screen.date=sr.date.screening, visitno=sr.visitno)
# cols like "eeg.Delay_LDLPFC_GammaEventDuration_mean"
eegspec <- read.csv(files$eegspec) %>% addcolprefix('eeg')
ssp <- read.csv(files$ssp) %>%
   separate(ld8,c('lunaid','behave.date')) %>%
   addcolprefix('ssp',sep="_", preserve=c("lunaid", "behave.date")) %>%
   addcolprefix('cantab', preserve=c("lunaid", "behave.date"))

# removing city, state, zip, FIP. TODO: keep all columns?
adi <- read.csv(files$adi) %>%
   select(lunaid, visitno=visit, ADI_NATRANK, ADI_STATERNK)

## tat2 - roi, subj (luan_date), event, beta
#        use to get rest date
tat2_wide <- tat2 %>%
   separate(subj,c('lunaid','rest.date')) %>%
   # is all rest. no other events
   #pivot_wider(names_from=c("roi","event"), values_from="beta")
   select(-event) %>% 
   pivot_wider(names_from=c("roi"), values_from="beta") %>%
   # add tat2 columns, but undo for ids
   addcolprefix('tat2') %>%
   rename(rest.date=tat2.rest.date) %>%
   merge(sess %>%
         filter(vtype=="Scan") %>%
         select(lunaid,visitno,vdate,rest.age=age,rest.vscore=vscore),
         all.x=T, by.x=c("lunaid","rest.date"), by.y=c("lunaid","vdate")) %>%
   rm_dup_lunaid %>% # motion correction is stocastic. same visit different tat2
   # fill missing rest.date. TODO: don't use tat2 to fill rest.date?
   bind_rows(data.frame(lunaid='11745', visitno=1, rest.date='20190322')) %>% unique

## mrsi -- subset to just GABA|Glu + CR|SD 
#  and ditch anything without an roi label
# TODO: might want version with regresssion applied
mrsi_mrg <- mrsi %>%
   separate(ld8, c("lunaid","date")) %>% 
   # same visit in duplicate lunaid, different placement. remove alt.id, keep "good"
   rm_dup_lunaid %>%
   addcolprefix('sipfc')
mrsi_mrg <-  merge(mrsi_mrg,
           sess %>% filter(vtype=="Scan") %>%
           select(lunaid, vdate, visitno, sipfc.age=age, sipfc.vscore=vscore),
         all.x=T, by.x=c("lunaid","sipfc.date"),by.y=c("lunaid","vdate"))

# fooof - Subject, Channel, Offset, Exponent, Condition (closed/open)
# 20230609 - from shane
if("Channel" %in% names(fooof)) {
   eeg_lookup <- c("F4"="RDLPFC","F6"="RDLPFC","F8"="RDLPFC",
                      "F3"="LDLPFC","F4"="LDLPFC","F7"="LDLPFC")
   fooof_dlpfc <- fooof %>% select(-X) %>%
      filter(Channel %in% names(eeg_lookup)) %>%
      mutate(Region=eeg_lookup[Channel]) %>%
      select(-Channel) %>%
   group_by(Subject, Region, Condition) %>%
   summarise_all(mean) # across(c("Offset","Exponent"), mean)
} else {
  fooof_dlpfc <- fooof %>% select(Subject,Condition,Offset,Exponent,Region)
}
   

fooof_wide <- fooof_dlpfc %>%
    pivot_wider(
        names_from=c("Condition", "Region"),
        values_from = c("Offset","Exponent"),
        names_glue = "{Condition}_{Region}_{.value}") %>%
    separate(Subject, c("lunaid","date")) %>% 
    addcolprefix('eeg')
# 11668_20170710 first visit no in DB? only one missing currently. quick fix
# should be 20180710
fooof_wide$eeg.date[fooof_wide$lunaid == "11668"&fooof_wide$eeg.date == "20170710"] <- "20180710"


#cat("have",nrow(fooof_wide),"eeg rows\n")
#fooof_mia <- fooof_wide %>% filter(is.na(visitno))
#if(nrow(fooof_mia) >0L) {
# cat("fooof with missing visit number\n")
# fooof_mia %>% select(lunaid,eeg.date) %>% print
#}

## Hurst will use tat2's rest.date to merge
#  dont need session info -- should already have. but just incase

hursts <- lapply(list("hurst_brns","hurst_ns","dfa_brns","dfa_ns"),
                 \(x) read.csv(files[[x]]) %>% addcolprefix(x, preserve='ld8')) %>%
          Reduce(f=\(x,y) merge(x,y,by='ld8'))

hurst_ses <- hursts %>%
   separate(ld8,c('lunaid','vdate')) %>%
   rm_dup_lunaid %>%
   rename(rest.date=vdate) %>%
   # TODO: maybe a function for all rest like inputs
   merge(sess %>%
         filter(vtype=="Scan") %>%
         select(lunaid,visitno,vdate,rest.age=age,rest.vscore=vscore),
         all.x=T, by.x=c("lunaid","rest.date"), by.y=c("lunaid","vdate"))

#hurst_ses %>% filter(is.na(visitno))
noX <- function(d) { if(names(d)[1] == "X") return(d[-1,]); return(d); }

#ignoreSNR=TRUE # 20231117 ignore eeg SNR per shane
#ignoreSNR=FALSE # 20231129 back up
ignoreSNR=!file.exists(files$eeg_dlpfc_snr) # 20240118 down again
#
if(!ignoreSNR){
   # "","Subject","luna","vdate","Region","ERSP","ITC","BaselinePower","Induced","Evoked","InducedDB","EvokedDB","age","visitno","Freq"
eeg_dlpfc_snr <- read.csv(files$eeg_dlpfc_snr) %>% noX %>%
    select(-Subject, -age, -vdate) %>%
    rename(lunaid=luna) %>%
    pivot_wider(id_cols=c("lunaid","visitno"),
                names_from=c("Freq","Region"),
                values_from=c("ERSP","ITC","BaselinePower",
                              "Induced","Evoked","InducedDB","EvokedDB")) %>%
    addcolprefix("eeg.snr", preserve=c("lunaid","visitno"))
} else {
   eeg_dlpfc_snr <- NULL
}

mgs_eog <- mgs_eog_visit %>%
   rename(lunaid=LunaID,date=ScanDate) %>%
   addcolprefix('eeg') %>%
   #wrong:  11670_20210823, 11672_2022061 folder and filename disagree.  db matches filename
   rewrite_date(eeg_newdates) %>%
   merge(sess %>%
         filter(vtype=="eeg") %>%
         select(lunaid,visitno,eeg.date=vdate,eeg.age=age,eeg.vscore=vscore),
         all.x=T, by.x=c("lunaid","eeg.date"), by.y=c("lunaid","eeg.date"))

missing_eog <- filter(mgs_eog,is.na(eeg.age))

if(nrow(missing_eog)>0L){
   cat("#",nrow(missing_eog),"MISSING EEG (EOG) visit in DB\n")
   missing_eog %>% select(lunaid,eeg.date) %>% print
}

## EEG spectrum (gamma)
# hard code some date adjustments
eegspec <- eegspec %>% rewrite_date(eeg_newdates)
# add session b/c at least one visit isn't in fooof
#eegspec_ses <- eegspec %>% merge(sess %>%
#         filter(vtype=="eeg") %>%
#         select(lunaid,visitno,vdate,eeg.age=age,eeg.vscore=vscore),
#         all.x=T, by.x=c("lunaid","eeg.date"), by.y=c("lunaid","vdate"))

eeg_date <- sess %>%
         filter(vtype=="eeg") %>%
         select(lunaid,visitno,eeg.date=vdate,eeg.age=age,eeg.vscore=vscore)


#####
sessid <- function(d)
   apply(d,1,function(x)
         paste0(collapse="_",x[c("lunaid","visitno")])) %>%
   gsub(' ','',.)

check_date_dups <- function(d){
   d_datesub <- d %>% select(lunaid,matches('\\.date$|^visitno$'))
   dups <- d[duplicated(d),]
   if(nrow(dups)>0L) {
      cat("WARNING: dups in ", df_varname,"\n")
      print(dups)
   }
   return(dups)
}

merge_and_check <- function(big, d, ...) {
   if(is.null(d)) return(big)

   df_varname <- substitute(d)
   # replace duplicate ids by picking one
   if('lunaid' %in% names(d)) d <- rewrite_luna(d)

   # did 2 IDs come in? maybe b/c rewrite_luna
   check_date_dups(d)

   big.new <- merge(big, d, ...)
   big.new.uniq <- big.new %>% unique # 11832 is repeated 2 twice?
   if(nrow(big.new)!=nrow(big.new.uniq)){
      cat("WARNING: duplicated rows added to merged dataset!","\n")
   }
   big.new <- big.new.uniq
   check_date_dups(big.new)


   bs <- sessid(big)
   ds <- sessid(d)
   mia_big <- setdiff(bs,ds)
   mia_d   <- setdiff(ds,bs)


   # debugging bad merge
   #print(substitute(d))
   #names(big) %>% grep(pattern='lunaid|visitno|\\.date$',value=T) %>% print()
   #print(nrow(big))
   #names(big.new) %>% grep(pattern='lunaid|visitno|\\.date$',value=T) %>% print()
   #print(nrow(big.new))

   new_visits <- anti_join(big.new,
                           big %>% select(lunaid,visitno),
                           by = c("lunaid", "visitno"))

   # what column do we care about for merging?
   args <- list(...)
   if(is.null(args[['by.y']])) args[['by.y']] <-  args[['by']]
   new_ids <- apply(new_visits[args[['by.y']]], 1, paste0, collapse="_")

   cat("#",
       glue(
                  "{df_varname}({nrow(d)}x{ncol(d)}) adding ",
                  "to {nrow(big)}x{ncol(big)}; ",
                  "{length(mia_big)} visits w/visitno ({nrow(new_visits)} new) / ",
                  "{length(mia_d)} not in {df_varname}"),
       "\n")

   cat("  missing: ", paste(collapse=", ",head(mia_big)), "\n")
   cat("      new: ", paste(collapse=", ",head(new_ids)), "\n")
   cat("   total rows now",nrow(big.new),"\n")
   return(big.new)
}

# hard coded visits known missing
missing_visitnums <- 
         setNames(data.frame(rbind(c(11695,1,20201106),
                                   c(11745,1,20190322))),
                  c("lunaid","visitno","rest.lost.date"))
rest_ses <- sess %>% filter(vtype=='Scan') %>%
         select(lunaid, visitno, rest.lost.date=vdate) %>%
         # missing data also missing in sess
         rbind(missing_visitnums) %>%
   filter(!(lunaid=='11745'&rest.lost.date=='20190318')) %>%
   unique # 11695_20201106 and 11745_20190322 maybe back into db?
 # 2 rest days 11745_20180318, 11745_20180322
         
lost_rest <-
   read.table(files$lost_rest,header=T,sep="\t") %>%
   select(ld8,rest.lost=lost,rest.lost.note=WFnote) %>%
   filter(rest.lost>0) %>%
   separate(ld8,c("lunaid","rest.lost.date")) %>%
   merge(rest_ses, all.x=T, by=c("lunaid","rest.lost.date"))
lost_rest_to_merge <- lost_rest %>% select(-rest.lost.date)

cat("mergeing all, writing merge file\n")
merged <-
   topsheet %>% rewrite_luna %>%
   merge_and_check(tat2_wide, by=c("lunaid","visitno"), all=T) %>%
   merge_and_check(behave, by=c("lunaid","visitno"), all=T) %>%
   merge_and_check(eeg_date, by=c("lunaid","visitno"), all=T) %>%
   merge_and_check(mrsi_mrg, by=c("lunaid","visitno"), all=T) %>%
   merge_and_check(fooof_wide, by=c("lunaid","eeg.date"), all=T) %>%
   merge_and_check(hurst_ses, by=c("lunaid","visitno","rest.date","rest.age","rest.vscore"), all=T) %>%
   merge_and_check(mgs_eog, by=c("lunaid","visitno","eeg.date","eeg.age","eeg.vscore"), all=T) %>%
   merge_and_check(sr, by=c("lunaid","visitno"), all.x=T, all.y=F) %>%
   merge_and_check(eegspec, by=c("lunaid","eeg.date"), all=T) %>%
   # only all.x b/c might have dropped after behv visit
   merge_and_check(ssp, by=c("lunaid","behave.date"),all.x=T) %>%
   merge_and_check(sex, by=c("lunaid"), all.x=T) %>%
   merge_and_check(adi, by=c("lunaid","visitno"), all.x=T) %>%
      # 20240227 - misisng future vists assigned ADI at last known
      group_by(lunaid) %>% arrange(visitno) %>%
      fill(matches('^ADI_.*RANK'),.direction="down") %>% ungroup() %>%
   merge_and_check(fd, by=c("lunaid","rest.date"), all.x=T) %>%
   merge_and_check(antiET, by=c("lunaid","behave.date"),all.x=T) %>%
   merge_and_check(eeg_dlpfc_snr, by=c("lunaid","visitno"),all.x=T) %>%
   merge_and_check(lost_rest_to_merge, by=c("lunaid","visitno"),all.x=T) %>%

   # beh visit with no imaging data. redone in 2022
   filter(! paste0(lunaid,'_',behave.date) %in% c("11786_20210310")) %>% 
   # remove behave in only overview sheet (42. additonal 17 have only behave.date)
   filter(!(is.na(rest.date) & is.na(eeg.date)  &is.na(top.eeg.date) & is.na(top.mri.date) & is.na(behave.date))) %>%
   merge(SAME_LUNA_df, all.x=T, by='lunaid') %>%
   # TODO: where does this bad eeg date come from!? also 11665 without session number w/eeg.date
   #   lunaid alt.lunaid visitno behave.date rest.date eeg.date top.behave.date top.mri.date top.eeg.date sipfc.date screen.date
   # 1  11748       <NA>      NA        <NA>      <NA> 20190429            <NA>         <NA>         <NA>       <NA>        <NA> 
   filter(!lunaid %in% c(11748)) %>%
  unique # 11832 is repeated 2 twice? (as of 20240213, this is no longer a problem)

cat(glue("# merged: {nrow(merged)} rows with {ncol(merged)} columns"),"\n")

# often have ages missing, want a single column to use for generic age @ session
# NB. 'sess.age' will match grepl. dont rerun these lines multiple times w/o reruning merge above
all_age_cols <- merged[,grepl('\\.age$',names(merged))] # eeg.age rest.age behave.age sipfc.age
merged$sess.age       <- apply(all_age_cols, 1, mean,na.rm=T)
merged$sess.age_range <- apply(all_age_cols, 1, \(x) diff(range(x,na.rm=T)))

write.csv(merged, 'txt/merged_7t.csv', quote=T, row.names=F)


cat("merged with missing visit number\n")
merged %>% filter(is.na(visitno)) %>% select(lunaid,matches('\\.date$')) %>% print
cat("ashley flagged ids")
merged %>% filter(lunaid %in% c(11737 ,11744,11763,11824,11890,11950)) %>% select(lunaid,visitno, matches('\\.date$')) %>% print

# merged these in so this doesn't happen
#cat("bad behave.date")
#merged %>% filter(is.na(behave.date)&!is.na(top.behave.date)) %>% select(lunaid,matches('\\.date$')) %>% print

cat("missing rest")
merged %>%
   merge(read.table('txt/MP_rest_file_qc.tsv',sep="\t",header=T), all=T,by="lunaid") %>%
   filter(is.na(rest.date),!is.na(top.mri.date)) %>%
   transmute(ld8=paste(lunaid,top.mri.date,sep="_") %>%gsub(';','\n',.),
             vs=top.mri.vscore,
             vdrop=top.mri.vdrop,
             notes=top.mri.notes,
             WFnote=rest.lost.note,
             rest.lost,
             MPnote=MPrestNote) %>%
   filter(vdrop!="TRUE"|is.na(vdrop), vs>0) %>%
   select(ld8,notes,vs,MPnote,WFnote, rest.lost) %>% 
   arrange(-!is.na(MPnote),-!is.na(WFnote)) %>%
   #clipr::write_clip()
   pander::pandoc.table(split.table = Inf)

cat("Visit type counts\n")
merged %>%
    transmute(lunaid,visitno,across(matches('\\.date$'), \(x) !is.na(x))) %>%
    count(behave.date,rest.date,eeg.date) %>%
    arrange(-n) %>%
    pander::pandoc.table()
 # behave.date rest.date eeg.date   n
 #        TRUE      TRUE     TRUE 291
 #        TRUE     FALSE    FALSE  43
 #        TRUE     FALSE     TRUE  41
 #        TRUE      TRUE    FALSE   4
 #       FALSE     FALSE    FALSE   1

cat("repeat visit numbers?!\n")
merged %>% count(lunaid,visitno)  %>% filter(n>1)                                                                                                                        
# lunaid visitno n
#  11390       1 4
#  11515       1 4
#  11515       2 2
#  11745       1 2
