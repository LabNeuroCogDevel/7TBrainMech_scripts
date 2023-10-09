# 20230328 - from OR.  Work In Progress. not used here. integrated into OR scripts
# 20231009WF - q_to_column to simlify
source('000_getQualtrics.R') # get_pub
load('svys.RData') # provides: svys
pub_by_battery <- get_pub(svys)

q_to_column = list(
  "And how about the growth of body hair?"="petb",
  "As a male adolescent develops, the testes become larger and heavier"="puberty_tanner_m_testicle_size",
  "External Data Reference"="id",
  "Have you begun to grow hair on your face?"="mpete",
  "Have you begun to menstruate"="fpete",
  "Have you noticed a deepening of your voice?"="petd",
  "Have you noticed any skin changes, especially pimples?"="petc",
  "Have your breasts begun to grow?"="petd",
  "Recorded Date"="vdate",
  "The drawings on this page show different amount of female pubic hair"="puberty_tanner_tsp_or_breast",
  "The drawings on this page show different amounts of male pubic hair."="puberty_tanner_hair",
  "The drawings on this page show different stages of development of the breasts."="puberty_tanner_hair",
  "The drawings on this page show different stages of development of the testes, scrotum, and penis"="puberty_tanner_tsp_or_breast",
  "Welcome to the LNCD Survey Battery! - Your gender:"="sex",
  "Would you say that your growth in height:"="peta"
) 

rename_puberty_questions <- function(df_names){
  for(qname in names(q_to_column)) {
    mi <- grep(qname,df_names)
    if(length(mi)>0L) {
       newname <- q_to_column[[qname]]
       #cat("match '",qname,"' at",mi[1], "now '",newname ,"'\n")
       df_names[mi[1]] <- newname
    }
  }
  return(df_names)
}
pub_subset <- lapply(pub_by_battery, function(d) {
  names(d) <- rename_puberty_questions(names(d))
  keep <- names(d) %in% unique(unname((q_to_column)))
  d[,keep] %>% mutate(across(!vdate,as.character))
})
all_pub <- pub_subset %>%
   bind_rows() %>% 
   mutate(sex=toupper(substr(sex,1,1)),
          vdate=format(vdate,"%Y%m%d"),
          across(matches('tanner'), \(x) gsub('Stage ','',x) %>% as.numeric))
write.csv(all_pub, 'txt/puberty.csv')
# TODO: as.factor for colums pet[a-e]



# OLD FROM ORMA -- manually renames each survey
# # from list of dataframes to specific columns
# adol.f <- as.data.frame(pub_by_battery$adolbatF)[,c(8,13,20,146:164)]
# adol.m <- as.data.frame(pub_by_battery$adolbatM)[,c(8,13,20,188:204)]
# youth.f <- as.data.frame(pub_by_battery$youthbatF)[,c(8,13,20,248:266)]
# youth.m <- as.data.frame(pub_by_battery$youthbatM)[,c(8,13,20,249:265)]


# adol.f <- adol.f %>% 
# #  select(adol.f, c(1:4,11:15,22:23)) %>%      # ask Will to troubleshoot, will just "NULL" for now
#   rename(id = "External Data Reference") %>%
#   rename(sex = "Welcome to the LNCD Survey Battery! - Your gender:") %>%
#   rename(vdate = "Recorded Date") %>%
#   rename(puberty_tanner_hair = "The drawings on this page show different stages of development of the breasts. The female passes through each of the 5 stages shown by these sets of drawings. Please look at each set of drawings and read the sentences under the drawings. Then choose the set of drawings closest to your stage of breast development.") %>%
#   rename(puberty_tanner_tsp_or_breast = "The drawings on this page show different amount of female pubic hair. A girl passes through each of the 5 stages shown by these drawings. Please look at each drawing and read the sentences under the drawing. Then choose the drawing closest to your stage of hair development.") %>%
#   rename(peta = "Would you say that your growth in height:") %>%
#   rename(petb = "And how about the growth of body hair? (\"body hair\" means hair any place other than your head, such as under your arms)  \nWould you say that your body hair:") %>%
#   rename(petc = "Have you noticed any skin changes, especially pimples?​") %>%
#   rename(petd = "Have your breasts begun to grow?") %>%
#   rename(fpete = "Have you begun to menstruate (started to have your period)?")
# 
# adol.f <- adol.f[,c(1:3,10:14,21:22)]
# adol.f$id <- as.character(adol.f$id)
# 
# youth.f <- youth.f %>% 
#   rename(id = "External Data Reference") %>%
#   rename(sex = "Welcome to the LNCD Survey Battery! - Your gender:") %>%
#   rename(vdate = "Recorded Date") %>%
#   rename(puberty_tanner_hair = "The drawings on this page show different stages of development of the breasts. The female passes through each of the 5 stages shown by these sets of drawings. Please look at each set of drawings and read the sentences under the drawings. Then choose the set of drawings closest to your stage of breast development.") %>%
#   rename(puberty_tanner_tsp_or_breast = "The drawings on this page show different amount of female pubic hair. A girl passes through each of the 5 stages shown by these drawings. Please look at each drawing and read the sentences under the drawing. Then choose the drawing closest to your stage of hair development.") %>%
#   rename(peta = "Would you say that your growth in height:") %>%
#   rename(petb = "And how about the growth of body hair? (\"body hair\" means hair any place other than your head, such as under your arms)  \nWould you say that your body hair:") %>%
#   rename(petc = "Have you noticed any skin changes, especially pimples?​") %>%
#   rename(petd = "Have your breasts begun to grow?") %>%
#   rename(fpete = "Have you begun to menstruate (started to have your period)?")
# 
# youth.f <- youth.f[,c(1:3,10:14,21:22)]
# 
# adol.m <- adol.m %>% 
#   rename(id = "External Data Reference") %>%
#   rename(sex = "Welcome to the LNCD Survey Battery! - Your gender:") %>%
#   rename(vdate = "Recorded Date") %>%
#   rename(puberty_tanner_hair = "The drawings on this page show different amounts of male pubic hair. A boy passes through each of the five stages shown by these drawings. Please look at each drawing an read the sentences under the drawing. Then choose the drawing closest to your stage of hair development. In choosing the right picture, look only at the pubic hair, and not at the size of the testes, scrotum, and penis.") %>%
#   rename(puberty_tanner_tsp_or_breast = "The drawings on this page show different stages of development of the testes, scrotum, and penis. A boy passes through each of the five stages shown by these drawings. Please look at each of the drawings and read the sentences under the drawings. Then choose the drawing closest to your stage of development. In choosing the right picture, look only at the stage of development, not at pubic hair.") %>%
#   rename(puberty_tanner_m_testicle_size = "As a male adolescent develops, the testes become larger and heavier than they were when he was a child. Above are 5 drawings indicating testes size. Please choose the size that is closest to your size.") %>%
#   rename(peta = "Would you say that your growth in height:") %>%
#   rename(petb = "And how about the growth of body hair? (\"body hair\" means hair any place other than your head, such as under your arms)  \nWould you say that your body hair:") %>%
#   rename(petc = "Have you noticed any skin changes, especially pimples?​") %>%
#   rename(petd = "Have you noticed a deepening of your voice?") %>%
#   rename(mpete = "Have you begun to grow hair on your face?")
# 
# adol.m <- adol.m[,c(1:3,8:12,18:20)]
# 
# youth.m <- youth.m %>% 
#   rename(id = "External Data Reference") %>%
#   rename(sex = "Welcome to the LNCD Survey Battery! - Your gender:") %>%
#   rename(vdate = "Recorded Date") %>%
#   rename(puberty_tanner_hair = "The drawings on this page show different amounts of male pubic hair. A boy passes through each of the five stages shown by these drawings. Please look at each drawing an read the sentences under the drawing. Then choose the drawing closest to your stage of hair development. In choosing the right picture, look only at the pubic hair, and not at the size of the testes, scrotum, and penis.") %>%
#   rename(puberty_tanner_tsp_or_breast = "The drawings on this page show different stages of development of the testes, scrotum, and penis. A boy passes through each of the five stages shown by these drawings. Please look at each of the drawings and read the sentences under the drawings. Then choose the drawing closest to your stage of development. In choosing the right picture, look only at the stage of development, not at pubic hair.") %>%
#   rename(puberty_tanner_m_testicle_size = "As a male adolescent develops, the testes become larger and heavier than they were when he was a child. Above are 5 drawings indicating testes size. Please choose the size that is closest to your size.") %>%
#   rename(peta = "Would you say that your growth in height:") %>%
#   rename(petb = "And how about the growth of body hair? (\"body hair\" means hair any place other than your head, such as under your arms)  \nWould you say that your body hair:") %>%
#   rename(petc = "Have you noticed any skin changes, especially pimples?​") %>%
#   rename(petd = "Have you noticed a deepening of your voice?") %>%
#   rename(mpete = "Have you begun to grow hair on your face?")
# 
# youth.m <- youth.m[,c(1:3,8:12,18:20)]
# 
# pub7t.m <- bind_rows(adol.m, youth.m)
# pub7t.f <- bind_rows(adol.f, youth.f)



# 20230328 -- code from Oct 17 into 000_getQualtrics.R
#   #install.packages(c("qualtRics","ini"))
#   suppressPackageStartupMessages({
#      library(qualtRics)
#      library(dplyr)
#      library(ini)
#      library(jsonlite)
#   })
#   
#   load('svys.RData')
#   get_labels <- function(d) sapply(d, attr, 'label')
#   `%||%` <- function(x,y) ifelse(!is.na(x)&x!='', x, y)
#   name_from_label <- function(d) { names(d) <- (get_labels(d) %||% names(d)); mutate_all(d, as.character); }
#   get_pub <- function(svys) {
#     has_pub_Q <- lapply(svys, function(x) grep('drawing on this page|any skin changes',ignore.case=T,perl=T,value=T, get_labels(x)))
#     has_pub_and_data <- svys[sapply(has_pub_Q,function(x) length(x)>=1)] %>% lapply(nrow) %>% Filter(f=function(x) x>=1) %>% names  
#     svys[has_pub_and_data] %>% lapply(function(x) rbind(min(as.character(x$StartDate)),max(as.character(x$EndDate)),nrow(x))) %>% data.frame %>% t
#     #7T.Y3.Adolescent..11.13..Female.Survey.Battery "2022-02-27 02:13:09" "2022-02-27 20:35:02" "1" 
#     #7T.Y3.Adolescent..14.17..Female.Survey.Battery "2022-01-03 15:25:08" "2022-06-26 18:51:25" "3" 
#     #7T.Y3.Adolescent..14.17..Male.Survey.Battery   "2021-08-25 23:13:18" "2022-07-21 20:20:23" "3" 
#     #7T.Y2.Adolescent..14.17..Male.Survey.Battery   "2020-08-27 16:51:55" "2022-08-11 16:14:32" "10"
#     #7T.Y2.Adolescent..11.13..Female.Survey.Battery "2020-01-15 15:58:28" "2022-07-07 17:59:19" "8" 
#     #7T.Y2.Adolescent..11.13..Male.Survey.Battery   "2019-11-27 15:13:09" "2022-07-09 17:33:19" "10"
#     #7T.Y2.Adolescent..14.17..Female.Survey.Battery "2019-10-22 14:58:38" "2022-02-20 03:21:06" "17"
#     #7T.Male.Youth..10.13..Survey.Battery           "2018-05-04 14:45:15" "2021-03-03 18:13:12" "33"
#     #7T.Female.Youth..10.13..Survey.Battery         "2018-03-29 16:52:55" "2021-04-01 20:47:21" "29"
#     #7T.Female.Youth..14.17..Survey.Battery         "2018-03-28 22:08:25" "2020-12-12 00:53:53" "24"
#     #7T.Male.Youth..14.17..Survey.Battery           "2018-03-22 21:14:53" "2020-09-28 16:18:19" "30"
#     return(list(
#     adolbatF = svys[has_pub_and_data %>% grep(pattern='Adol.*Female', value=T,perl=T)] %>% lapply(name_from_label) %>% bind_rows %>% readr::type_convert(),
#     adolbatM = svys[has_pub_and_data %>% grep(pattern='Adol.*Male', value=T,perl=T)] %>% lapply(name_from_label) %>% bind_rows %>% readr::type_convert(),
#   
#     youthbatF = svys[has_pub_and_data %>% grep(pattern='Female.*Youth', value=T,perl=T)] %>% lapply(name_from_label) %>% bind_rows %>% readr::type_convert(),
#     youthbatM = svys[has_pub_and_data %>% grep(pattern='Male.*Youth', value=T,perl=T)] %>% lapply(name_from_label) %>% bind_rows %>% readr::type_convert()
#     ))
#     # names(adolbatM)[188:204]
#     # names(adolbatF)[146:165] 
#     #srvy_wpub$youthbatF %>% names %>% `[`(249:266)
#     #srvy_wpub$youthbatM %>% names %>% `[`(249:265)  
#   }
#   
#   # finally output as list
#   #  pub_by_battery$youthbatM
#   pub_by_battery <- get_pub(svys)
#   #srvy_wpub$youthbatF %>% names %>% `[`(249:266)
#   #srvy_wpub$youthbatM %>% names %>% `[`(249:265)  
