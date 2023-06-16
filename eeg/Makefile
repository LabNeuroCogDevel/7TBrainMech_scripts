eog_cal/eye_scored_mgs_eog_cleanvisit.csv: eog_cal/eye_scored_mgs_eog.csv
	cd eog_cal && Rscript clean_eog_visit.R

eog_cal/eye_scored_mgs_eog.csv: $(wildcard /Volumes/Hera/Raw/EEG/7TBrainMech/1*_2*/*_mgs*.bdf) $(wildcard /Volumes/Hera/Raw/EEG/7TBrainMech/1*_2*/*_MGS*.bdf)
	cd eog_cal && ml score_eog.m
