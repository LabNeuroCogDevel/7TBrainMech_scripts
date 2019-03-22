#!/usr/bin/env Rscript

#install.packages(c("qualtRics","ini"))
suppressPackageStartupMessages({
   library(qualtRics)
   library(dplyr)
   library(ini)
   library(jsonlite)
})

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
  # create lncddb visit_task friendly dataframe
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

ini <- read.ini("qualtircs.ini")
registerOptions(api_token=ini$api$api_token, root_url=ini$api$root_url)

survey_list <- getSurveys() %>%  filter(grepl("7T", name))
# show by date
survey_list %>%
    arrange(-isActive, -order(lastModified)) %>%
    select(c( "name", "isActive", "lastModified", "id") ) %>% print(n=Inf)

# get all the surveys and junk the ones with too few responses
all_surveys <- lapply(survey_list$id, function(x)
                      tryCatch(getSurvey(x, root_url=ini$api$root_url, force=T),
                               error=function(e) NULL))
names(all_surveys) <- survey_list$name
survey_cnt <- sapply(all_surveys, function(x) ifelse(is.null(x), 0, nrow(x)))

cat("\nignoring these\n")
survey_cnt[survey_cnt<5] %>% data.frame(name=names(.), n=.) %>% arrange(-n) %>% print.data.frame(row.names=F)
survey_cnt[survey_cnt>=5]





d <- qualtrics_to_visit_task(all_surveys[["7T Screening: Youth (10)"]], "Youth Screening", vtype="behave")
d <- qualtrics_to_visit_task(all_surveys[["7T Y1 Male Adult Survey Battery"]], "7TY1Male_Survey", vtype="behave")

con <- DBI::dbConnect(RPostgreSQL::PostgreSQL(),
                      host="arnold.wpic.upmc.edu",
                      user="postgres",
                      dbname="lncddb")


