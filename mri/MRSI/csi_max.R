#!/usr/bin/env Rscript
library(LNCDR)

# roi lookup table (same for everyone)
l <- read.table("/Volumes/Hera/Projects/7TBrainMech/subjs/11299_20180511/slice_PFC/MRSI/2d_csi_ROI/ParcelCSIvoxel_lut.txt")
names(l) <- c("roi", "label", "abrv")

# get all dateof births
dob <- db_query("select id as lunaid,dob from person natural join enroll where etype like 'LunaID'")

# read in data, get just the max, make long, and merge wtih roi labels
# get age
d  <-
   read.table("txt/gaba.txt", sep="\t", header=T) %>%
   select(matches("Subj|Max"))  %>%
   tidyr::gather(roi, value, -Subj) %>%
   mutate(roi=gsub("Max_", "", roi)%>%as.numeric) %>%
#   filter(value>0) %>%
   merge(l %>% select(roi, label)) %>%
   tidyr::separate(Subj,c("lunaid", "vdate"), sep="_") %>%
   merge(dob, all.x=T, all.y=F) %>%
   mutate(vdate=lubridate::ymd(vdate),
          age=as.numeric(vdate-dob)/365.25)
write.csv(d, "txt/gaba_age.txt")

m_roi4<-lm(value ~ age, d %>% filter(roi==4))
summary(m_roi4)

roi_labels <- unique(d$label)
all_m <- lapply(roi_labels, function(x) lm(value ~ age, d[d$label==x, ]))
names(all_m) <- roi_labels

pvals <- sapply(all_m, function(x) summary(x)$coefficients[2, "Pr(>|t|)"])
print(pvals)

colnames(all_m)
names(all_m)
