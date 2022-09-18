#!/usr/bin/env Rscript

#install.packages(c("qualtRics","ini"))
suppressPackageStartupMessages({
   library(qualtRics)
   library(dplyr)
   library(ini)
   library(jsonlite)
})

ini <- read.ini("qualtircs.ini")
qualtrics_api_credentials(api_key=ini$api$api_token, base_url=ini$api$root_url)

survey_list <- all_surveys() %>%  filter(grepl("7T", name))
# show by date
survey_list %>%
    arrange(-isActive, -order(lastModified)) %>%
    select(c( "name", "isActive", "lastModified", "id") ) %>% print(n=Inf)

# get all the surveys and junk the ones with too few responses
svys <- lapply(survey_list$id, function(x)
                      tryCatch(getSurvey(x, root_url=ini$api$root_url, force=T),
                               error=function(e) NULL))
names(svys) <- survey_list$name
survey_cnt <- sapply(svys, function(x) ifelse(is.null(x), 0, nrow(x)))

cat("\nignoring these\n")
survey_cnt[survey_cnt<5] %>% data.frame(name=names(.), n=.) %>% arrange(-n) %>% print.data.frame(row.names=F)
survey_cnt[survey_cnt>=5]

# save all surveys
save(svys,file='svys.RData')

####
# save all batteries
bats <- names(survey_cnt[survey_cnt>5]) %>% grep(pattern="Battery",value=T)

for (bname in bats) {
    s <- svys[[bname]]
    refcol <- "ExternalDatareference"
    if(! refcol %in% names(s)) refcol <- "ExternalReference"
    ld8 <- paste(s[[refcol]],format(s$StartDate,"%Y%m%d"),sep="_")
    sid <- survey_list$id[survey_list$name == bname]
    #qname <- sapply(names(s), function(n) paste0(collapse="-",unique(c(n,attr(s[[n]],'label'))))) %>% unname
    qname <- sapply(names(s), function(n) attr(s[[n]],'label')) %>% unname

    for (i in 1:nrow(s)) {
        dname <- sprintf('/Volumes/L/bea_res/Data/Temporary Raw Data/7T/%s', ld8[i])
        if (dir.exists(sprintf("%s_dropped", dname))) {
            cat("#", dname, "dropped\n")
            next
        }
        if(is.na(LNCDR::ld8from(ld8[i]))) { cat("# bad id", ld8[i]); next }
        fname <- sprintf('%s/%s_selfreport.csv', dname, ld8[i])
        if (file.exists(fname)) {cat("#", fname, "exists\n"); next}
        dtemp <- data.frame(t(qname))
        names(dtemp) <- names(s)
        rowtemp <- s[i,] %>% mutate_all(as.character)
        out <- rbind(dtemp, rowtemp)
        if (!dir.exists(dname)) dir.create(dname)
        print(fname)
        write.csv(file=fname, out)
    }
}
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



d <- qualtrics_to_visit_task(svys[["7T Screening: Youth (10)"]], "Youth Screening", vtype="behave")
d <- qualtrics_to_visit_task(svys[["7T Y1 Male Adult Survey Battery"]], "7TY1Male_Survey", vtype="behave")

con <- DBI::dbConnect(RPostgreSQL::PostgreSQL(),
                      host="arnold.wpic.upmc.edu",
                      user="postgres",
                      dbname="lncddb")


