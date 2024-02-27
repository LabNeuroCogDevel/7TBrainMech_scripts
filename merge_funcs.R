
addcolprefix <- function(d,pre, sep=".", preserve=c("lunaid")) {
   preserve_rex <- paste0("^", pre, sep, "(",paste0(collapse="|", preserve),")")
   newnames     <-  paste(pre, colnames(d), sep = sep)
   colnames(d)  <- gsub(preserve_rex,'\\1', newnames)
   return(d)
}

check_datecol <- function(y, by.y) {
   datecol <- unlist(y[,by.y[2]])
   issue <- str_length(datecol) != 8 | is.na(datecol)
   if(any(issue)) {
      cat( "has ", length(which(issue)), " bad dates:\n");
      str(datecol[issue]) # todo not helpful when its a number
      print.data.frame(y[issue,c(by.y)])
      cat("# end of things that dont look like dates\n")
      y<-y[!issue,]
   }
   return(y)
}

lunadatemerge <-function(x, y, by.y, idfrom=NULL,...){
   # 20200505 remove bad dates
   y <- rm_bad_date(y, by.y)
   d_all <- merge(x,y,by.x=c('lunaid','vdate'),all=T,by.y=by.y,...)
   # track where new ids come from
   if(is.null(idfrom))  idfrom <- substitute(y)
   d_all <- addidfrom(d_all, idfrom)
   return(d_all)
}


eeg_newdates <- list('11632_20190101'='20191001',
                     '11678_20180116'='20181016',
                     "11668_20170710"="20180710",
                     "11670_20210823"="20210824",
                     "11672_20220617"="20220615")

rewrite_date<-function(d,l=eeg_newdates, datecol='eeg.date'){
    # data.frame(lunaid=c(1,2,3,1,3),eeg.date=c(1,1,1,2,2)) %>% rewrite_date(list("1_1"="10", "3_2"=20))
    id_date <- names(l)
    all_ld8 <- paste(sep="_",d$lunaid,d[[datecol]])
    for(i in seq_along(id_date)){
        d[all_ld8 %in% id_date[i], datecol] <- l[[i]]
    }
    return(d)
}
