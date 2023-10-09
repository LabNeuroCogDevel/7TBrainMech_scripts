#!/usr/bin/env Rscript

#install.packages(c("qualtRics","ini"))
suppressPackageStartupMessages({
   library(qualtRics)
   library(dplyr)
   library(ini)
   library(jsonlite)
})

count_surveys <- function(svys) sapply(svys, function(x) ifelse(is.null(x), 0, nrow(x)))

get_survey_list <- function(){
   ini <- read.ini("qualtircs.ini")
   qualtrics_api_credentials(api_key=ini$api$api_token, base_url=ini$api$root_url)

   all_survey_list <- qualtRics::all_surveys()
   survey_list <- all_survey_list %>% filter(grepl("7T", name))
}

# query all: # SV_bdejyV7MRgmOhuZ (7TAdult Screen) failing?!
# force_request=T does not reuse cache. unclear if cache invalidated by survey's last update time 
get_svys_qualtrics <- function(force_request=TRUE) {
   survey_list <- get_survey_list()
   # show by date
   cat("# list of surveys")
   survey_list %>%
       arrange(-isActive, -order(lastModified)) %>%
       select(c( "name", "isActive", "lastModified", "id") ) %>% print(n=Inf)

   # get all the surveys and junk the ones with too few responses
   svys <- lapply(survey_list$id, function(x)
                         #tryCatch(getSurvey(x, root_url=ini$api$root_url, force=T),
                         tryCatch(fetch_survey(x, force_request=force_request, save_dir="surveys"),
                                  error=function(e) {
                                     str(e)
                                     cat("# error reading",x,"\n")
                                     return(NULL)}))
   names(svys) <- survey_list$name

   # save all surveys
   save(svys,file='svys.RData')
   return(svys)
}


# 

####
# save all batteries
save_all_csv <- function(svys=NULL) {
  if(is.null(svys)) load('svys.RData')

  survey_cnt <- count_surveys(svys)
  cat("\nless than 5 respones. ignoring these:\n")
  #survey_cnt[survey_cnt<5] %>% data.frame(name=names(.), n=.) %>% arrange(-n) %>% print.data.frame(row.names=F)
  #survey_cnt[survey_cnt>=5]

  bats <- names(survey_cnt[survey_cnt>5]) %>% grep(pattern="Battery",value=T)
  
  for (bname in bats) {
      s <- svys[[bname]]
      refcol <- "ExternalDatareference"
      if(! refcol %in% names(s)) refcol <- "ExternalReference"
      ld8 <- paste(s[[refcol]],format(s$StartDate,"%Y%m%d"),sep="_")
      #qname <- sapply(names(s), function(n) paste0(collapse="-",unique(c(n,attr(s[[n]],'label'))))) %>% unname
      qname <- sapply(names(s), function(n) attr(s[[n]],'label')) %>% unname
  
      for (i in 1:nrow(s)) {
          dname <- sprintf('/Volumes/L/bea_res/Data/Temporary Raw Data/7T/%s', ld8[i])
          if (dir.exists(sprintf("%s_dropped", dname))) {
              cat("#", dname, "dropped exists. skipping\n")
              next
          }
          if(is.na(LNCDR::ld8from(ld8[i]))) { cat("# bad id", ld8[i]); next }
          fname <- sprintf('%s/%s_selfreport.csv', dname, ld8[i])
          if (file.exists(fname)) {cat("#", fname, "exists.  not rewritting\n"); next}
          dtemp <- data.frame(t(qname))
          names(dtemp) <- names(s)
          rowtemp <- s[i,] %>% mutate_all(as.character)
          out <- rbind(dtemp, rowtemp)
          if (!dir.exists(dname)) dir.create(dname)
          cat("# writting", fname,"\n")
          write.csv(file=fname, out)
      }
  }
}

explore_examples <- function(srvy) {
   survey_list <- all_surveys() %>%  filter(grepl("7T", name))
   ###
   # get survey names
   ##
   m <- metadata(survey_list$id[survey_list$name==names(survey_cnt[survey_cnt>5][7])])
   a <- sapply(m$questions, function(x) gsub("<.*?>","",x$questionText))
   
   
   ###### 
   # see data
   d <- svys[["7T Screening: Youth (10)"]]
   print(d$Q20_1)
   print(d$Q20_71)
}

qualtrics_to_visit_task <- function(s, taskname, vtype="behave") {
  #s <- all_surveys[["7T Screening: Youth (10)"]]
  
  # remove first and last name so we dont introduce PPI
  s_tojson <- s %>% select(-RecipientFirstName, -RecipientLastName)
  # get question labels, make part of title
  n <- names(s_tojson)
  l <- unname(sapply(s_tojson, attr, "label"))
  names(s_tojson) <- mapply(function(x, y) c(x, y) %>% na.omit %>% unique %>% paste0(collapse=":"),
                            n, l, USE.NAMES=F)
  # create vector of measures
  measures <- split(s_tojson, 1:nrow(s_tojson)) %>%
              unname %>% lapply(toJSON) %>% unlist


  ## create lncddb visit_task friendly dataframe

  # 20220803 - new surveys have exteranl without "Data" in the name
  if(! "ExternalDataReference" %in% names(d) ) s$ExternalDataReference <- s$ExternalReference

  s <- s %>% select(ExternalDataReference, StartDate) %>%
     mutate(task=taskname, measures=measures,
            ExternalDataReference=as.character(ExternalDataReference))
  # subset to only those that were successfully screened have id in database
  id_str <- paste0(collapse=",", "'", s$ExternalDataReference, "'")
  query <- paste("select * from enroll where id in (", id_str, ")")
  pids <-LNCDR::db_query(query)
  d <- inner_join(s, pids, by=c(ExternalDataReference="id"))

  if (nrow(d) != nrow(s))
     warning("DB pid/enroll merge matched ",
             nrow(d), " of ", nrow(s), " surveys. missing: ",
             paste(collapse=", ",
                   setdiff(s$ExternalDataReference, d$ExternalDataReference)))
  
  return(d)
}


incomplete_db_add <- function(svys) {
  d <- qualtrics_to_visit_task(svys[["7T Screening: Youth (10)"]], "Youth Screening", vtype="behave")
  d <- qualtrics_to_visit_task(svys[["7T Y1 Male Adult Survey Battery"]], "7TY1Male_Survey", vtype="behave")
  
  con <- DBI::dbConnect(RPostgreSQL::PostgreSQL(),
                        host="arnold.wpic.upmc.edu",
                        user="postgres",
                        dbname="lncddb")
}

get_labels <- function(d) sapply(d, attr, 'label')
`%||%` <- function(x,y) ifelse(!is.na(x)&x!='', x, y)
name_from_label <- function(d) { names(d) <- (get_labels(d) %||% names(d)); mutate_all(d, as.character); }

get_pub <- function(svys) {
  has_pub_Q <- lapply(svys, function(x) grep('drawing on this page|any skin changes',ignore.case=T,perl=T,value=T, get_labels(x)))
  has_pub_and_data <- svys[sapply(has_pub_Q,function(x) length(x)>=1)] %>% lapply(nrow) %>% Filter(f=function(x) x>=1) %>% names  
  svys[has_pub_and_data] %>% lapply(function(x) rbind(min(as.character(x$StartDate)),max(as.character(x$EndDate)),nrow(x))) %>% data.frame %>% t
  #7T.Y3.Adolescent..11.13..Female.Survey.Battery "2022-02-27 02:13:09" "2022-02-27 20:35:02" "1" 
  #7T.Y3.Adolescent..14.17..Female.Survey.Battery "2022-01-03 15:25:08" "2022-06-26 18:51:25" "3" 
  #7T.Y3.Adolescent..14.17..Male.Survey.Battery   "2021-08-25 23:13:18" "2022-07-21 20:20:23" "3" 
  #7T.Y2.Adolescent..14.17..Male.Survey.Battery   "2020-08-27 16:51:55" "2022-08-11 16:14:32" "10"
  #7T.Y2.Adolescent..11.13..Female.Survey.Battery "2020-01-15 15:58:28" "2022-07-07 17:59:19" "8" 
  #7T.Y2.Adolescent..11.13..Male.Survey.Battery   "2019-11-27 15:13:09" "2022-07-09 17:33:19" "10"
  #7T.Y2.Adolescent..14.17..Female.Survey.Battery "2019-10-22 14:58:38" "2022-02-20 03:21:06" "17"
  #7T.Male.Youth..10.13..Survey.Battery           "2018-05-04 14:45:15" "2021-03-03 18:13:12" "33"
  #7T.Female.Youth..10.13..Survey.Battery         "2018-03-29 16:52:55" "2021-04-01 20:47:21" "29"
  #7T.Female.Youth..14.17..Survey.Battery         "2018-03-28 22:08:25" "2020-12-12 00:53:53" "24"
  #7T.Male.Youth..14.17..Survey.Battery           "2018-03-22 21:14:53" "2020-09-28 16:18:19" "30"
  return(list(
  adolbatF = svys[has_pub_and_data %>% grep(pattern='Adol.*Female', value=T,perl=T)] %>% lapply(name_from_label) %>% bind_rows %>% readr::type_convert(),
  adolbatM = svys[has_pub_and_data %>% grep(pattern='Adol.*Male', value=T,perl=T)] %>% lapply(name_from_label) %>% bind_rows %>% readr::type_convert(),

  youthbatF = svys[has_pub_and_data %>% grep(pattern='Female.*Youth', value=T,perl=T)] %>% lapply(name_from_label) %>% bind_rows %>% readr::type_convert(),
  youthbatM = svys[has_pub_and_data %>% grep(pattern='Male.*Youth', value=T,perl=T)] %>% lapply(name_from_label) %>% bind_rows %>% readr::type_convert()
  ))
  # names(adolbatM)[188:204]
  # names(adolbatF)[146:165] 
  #srvy_wpub$youthbatF %>% names %>% `[`(249:266)
  #srvy_wpub$youthbatM %>% names %>% `[`(249:265)  
}

read_from_csv <- function(){
   csvs <- Sys.glob('/Volumes/L/bea_res/Data/Temporary Raw Data/7T/1*_2*/*_selfreport.csv')
   all_csv <- lapply(csvs,read.csv)
}


# names of suverys that have any question matching qtext
svy_with_Q <- function(svys, qtext, min_resp=1){
  Q_matches <- lapply(svys, function(x) grep(qtext,ignore.case=T,perl=T,value=T, get_labels(x)))
  Q_any <- sapply(Q_matches,function(x) length(x)>=1)
  svys[Q_any] %>% lapply(nrow) %>% Filter(f=function(x) x>=min_resp) %>% names  
}

# percieved_stress_scale
extract_qrange <- function(svy,qstart,qend) {

   refcol <- "ExternalDatareference"
   if(! refcol %in% names(svy)) refcol <- "ExternalReference"
   ld8 <- paste(svy[[refcol]],format(svy$StartDate,"%Y%m%d"),sep="_")

   labs <- get_labels(svy)
   start_i <- first(grep(qstart, labs, ignore.case=T, perl=T))
   if(class(qend)=="character") {
     end_i <- last(grep(qend, labs, ignore.case=T, perl=T))
   } else {
     end_i <- start_i + qend
   }
   #cat("getting:",start_i,end_i,"(",end_i-start_i,")\n")
   d <- svy[,start_i:end_i]
   names(d) <- labs[start_i:end_i]
   d$ld8 <- ld8
   return(d)
}
rm_num_label <- function(x) as.character(x) %>% gsub(' -.*','', .) %>% as.numeric()

PSS <- function(svys=NULL){
  if(is.null(svys)) load('svys.RData')
  qstart <- '^In the last month, how often have you been upset because of something that'
  qend <-'^In the last month, how often have you felt difficulties were piling up so high that you could not overcome them?'
  #qend <- 9
  svynames <- svy_with_Q(svys, qstart, min_resp=3)
  d_list <- lapply(svys[svynames], function(svy) extract_qrange(svy, qstart, qend))
  # show how many we have from each survey
  print.data.frame(row.names=F,
                   data.frame(s=names(d_list),
                              n=unname(sapply(d_list, nrow)),
                              firstd=sapply(d_list, function(x) min(gsub('.*_','',x$ld8),na.rm=T)),
                              lastd=sapply(d_list, function(x) max(gsub('.*_','',x$ld8),na.rm=T))) %>%
                   arrange(-as.numeric(lastd))) 

  pss <- d_list %>% lapply(function(d) d %>% mutate(across(!ld8, as.character))) %>% bind_rows
  return(pss)
}

if (sys.nframe() == 0){

   inargs <- commandArgs(trailingOnly=TRUE)
   if(length(inargs) == 0L) inargs <- "both"

   if(any(inargs %in% c("fetch", "both"))) {
      cat("# Writting svys.RData\n")
      svys <- get_svys_qualtrics()
      object.size(svys)
   }else{
      load('svys.RData')
   }

   if(any(inargs %in% c("csv", "both"))) {
      save_all_csv(svys)
   }

   if(any(inargs %in% c("pss"))) {
      pss <- PSS()
      # NA filter can probably go into PSS function
      not_all_na <- apply(pss,1,function(x) length(which(is.na(x))) < 10)
      # was done earlier but wanted to make sure NAs were b/c of bad conversion
      pss_no_all_na <- pss[not_all_na,] %>% mutate(across(!ld8, rm_num_label))
      write.csv(pss_no_all_na, file="PSS.csv", row.names=F, quote=T)
   }
}
