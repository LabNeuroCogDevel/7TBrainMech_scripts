metabolite_ageeffect <- function(d, region, metabolite, CRLB, saveplot=F) {
    # setup like
    # MRS <- read.csv('txt/13MP20200207_LCMv1.csv')
    # d = MRS; region = 1; metabolite = "Glu.Cr"; CRLB = ~Glu.SD
    # out <- metabolite_ageeffect(MRS, 1, Glu.Cr, Glu.SD)
    require(dplyr)
    require(ggplot2)
    require(cowplot)

    # Filtering
    brain_region_all <- d %>% filter(roi == region)
    brain_region <-
        brain_region_all %>%
        filter(!!enquo(CRLB) <= 20) %>%
        na.omit()

    #OUTPUT: return sample size so i know how many people i now have after exclusions
    cat(sprintf("retaining %d/%d\n", nrow(brain_region), nrow(brain_region_all)))

    # age effect
    # OUTPUT SUMMARY TABLE
    mtbl_str <- as.character(substitute(metabolite))
    fml <- mtbl_str %>% sprintf("%s ~ age", .) %>% as.formula
    m <- lm(fml, data = brain_region)
    smry <- summary(m)

    #OUTPUT A GRAPH
    title <- sprintf("%s roi=%d (n=%d, p=%.03f, e=%.03f)",
                       mtbl_str,
                       region, nrow(brain_region),
                       smry$coefficients['age','Pr(>|t|)'],
                       smry$coefficients['age','Estimate'])
    print(title)
    p <-
       ggplot(brain_region) +
       aes(x=age, y=!!enquo(metabolite)) +
       geom_point() +
       theme_cowplot() +
       ggtitle(title)

    if(saveplot) {
        outfile <- paste0('imgs/ageeffect-',gsub('[^.A-Za-z0-9]+','_',title), '.png')
        ggsave(p, file=outfile)
    }

    # retrun all objects
    list(p=p, summary=smry, n=nrow(brain_region))
}

plot_all <-function(d) {
    require(ggplot2)
    require(dplyr)
    require(tidyr)
    require(stringr)
    require(cowplot)
    # from rows for each subject to
    # repeat rows for each subject+region+metabolite+SD/Cr/V
    long <-
        d %>%
        gather(m, v, -ld8,-age, -GMrat, -roi, -label, -gm.atlas, -GMcnt, -x, -y) %>%
        na.omit()
    # bring into fewer rows by adding columns for SD, Cr, and V
    wider <- long %>%
        mutate(ex=str_extract(m,'(SD|Cr)$') %>% ifelse(is.na(.), 'V',.),
               m=gsub('.?(SD|Cr)$', '', m)) %>%
        spread(ex,v)

    pd <- wider %>%
        filter(m == 'Glu') %>%
        filter(SD <=20, !is.na(Cr), Cr != 0, Cr < 2) 

    p <-
        ggplot(pd) + aes(y=Cr, x=age) +
        geom_point() +
        stat_smooth(method='lm') +
        facet_grid(m ~ roi) +
        theme_cowplot()
}

make_long <- function(wide_metabolite='txt/13MP20200207_LCMv2fixidx.csv'){
   require(dplyr)
   require(tidyr)
   # get long verfsion of wide metabolite info
   # only pull out Cr and SD values for each metabolite+roi pair
   # ignore CrCH Chol NAAG adn Gln rations
   # includes scanyear visitnum age and fd
   age_breaks <- c(0,15,19,23,Inf)
   long <- 
       read.csv(wide_metabolite) %>%
       filter(!is.na(roi), !failqc) %>%
       select(ld8,visitnum, ld8, age, fd=fd_mean, roi=label, matches('\\.Cr$|\\.SD$')) %>%
       pivot_longer(cols=matches('Cr$|SD$')) %>%
       # met is metabolite, mtype is '.Cr' ratio or '.SD' crlb value
       separate(name,c('met','mtype'),extra="merge") %>%
       # repeats in pivot wider when these are included
       # dont care about eg CrCH.SD
       filter(!grepl('CrCH|Cho|NAAG|Gln',mtype)) %>%
       # use first just incase we still have some repeat values
       pivot_wider(names_from="mtype", values_fn=first) %>%
       # add some nice-to-have derivative columns
       mutate(agegrp=cut(age, breaks=age_breaks),
             scanyear=stringr::str_extract(ld8,'(?<=_)\\d{4}'))
}
