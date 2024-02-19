MAKEFLAGS += --no-builtin-rules
.SUFFIXES:
.PHONY: all FS alwaysrun .ALWAYS

all: txt/merged_7t.csv mri/txt/status.csv
.make:
	mkdir .make

txt/7T_packet.xlsx:
	curl 'https://docs.google.com/spreadsheets/d/e/2PACX-1vR2-clq04Tnw0BWICY5PiEP5DlHoKuEsPuuaOnT3TKeSjfwpYxMViaw8LxVipq0NQ/pub?output=xlsx' |mkifdiff --noempty $@

txt/db_sex.csv: .ALWAYS
	lncddb "select id,sex from person p join enroll e on e.pid=p.pid and e.etype = 'LunaID'" | mkifdiff -n $@

txt/merged_7t.csv: txt/sessions_db.txt mri/MRSI_roi/gam_adjust/out/gamadj_wide.csv mri/tat2/maskave.csv eeg/Shane/Results/FOOOF/Results/allSubjectsDLPFCfooofMeasures_20230523.csv mri/hurst/stats/MRSI_pfc13_H.csv eeg/eog_cal/eye_scored_mgs_eog_cleanvisit.csv behave/txt/SR.csv eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Gamma_DLPFCs_spectralEvents_wide.csv behave/txt/SSP.csv txt/db_sex.csv /Volumes/Hera/Projects/Maria/Census/parguard_luna_visit_adi.csv behave/txt/anti_scored.csv eeg/Shane/Results/SNR/SNRmeasures_PC1_allStim.csv
	./merge7T.R
	#eval "datalad run -o txt/merged_7t.csv $(perl -lne 'print join(" -i ",split(/ /,$1)) if m/merged_7t.csv:(.*)/' Makefile) ./merge7T.R"
	#datlad --explicit -m "update from make" run -o $@ -i $(substr ,-i ,$^) ./merge7T.R 


eeg/Shane/Results/SNR/SNRmeasures_PC1_allStim.csv: eeg/Shane/Results/SNR/allSubjectsSNR_allChans_allfreqs.csv
	eeg/Shane/Rscripts/SNR/createImputed_PCAdataframes.R
### other makefiles (added 20230516)
mri/tat2/maskave.csv: mri/tat2/Makefile .ALWAYS
	make -C $(dir $@) $(notdir $@)
mri/MRSI_roi/txt/13MP20200207_LCMv2fixidx.csv: .ALWAYS
	make -C $(dir $@) $(notdir $@)
mri/hurst/stats/MRSI_pfc13_H.csv: .ALWAYS
	# mri/hurst/Makefile
	make -C mri/hurst stats/MRSI_pfc13_H.csv

mri/MRSI_roi/gam_adjust/out/gamadj_wide.csv:
	make -C mri/MRSI_roi/gam_adjust/ out/gamadj_wide.csv

eeg/eog_cal/eye_scored_mgs_eog_cleanvisit.csv: .ALWAYS
	# eeg/Makefile
	make -C eeg eog_cal/eye_scored_mgs_eog_cleanvisit.csv

behave/txt/SR.csv:
	make -C behave txt/SR.csv

behave/txt/SSP.csv:
	make -C behave txt/SSP.csv

# 20240118: updated some address, no new rows
/Volumes/Hera/Projects/Maria/Census/parguard_luna_visit_adi.csv:
	make -C $(dir $@) $(notdir $@)

behave/txt/anti_scored.csv:
	make -C behave txt/anti_scored.csv

### MERGE 7T
txt/sessions_db.txt: .ALWAYS
	(echo "id\tvisitno\tvtype\tvdate\tage\tsex\tvscore\tdrop" && \
	 timeout 5s lncddb "with dc as ( \
	  select pid, string_agg(dropcode::text,',') drops \
	  from note\
	  where dropcode is not null  \
	  and dropcode::text not like 'BAD_VEIN'\
	  group by pid) \
	 select id, visitno, vtype,\
	  to_char(vtimestamp,'YYYYmmdd') as vdate, \
	round(age::numeric,2), \
	  sex, vscore, drops \
	from visit natural join visit_study \
	natural join person \
	join enroll on visit.pid = enroll.pid and etype like 'LunaID' \
	left join dc on visit.pid = dc.pid  \
	where study like '%BrainMech%' \
	order by vdate")  | mkifdiff $@

eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Gamma_DLPFCs_spectralEvents_wide.csv:
	eeg/Shane/Rscripts/spectral_events_wide.R
### IDs, raw MR org, FS, and origianl [PFC] MRSI (partially used for MRSI_roi)

.make/task_csv.ls: alwaysrun |.make
	mkls $@ "/Volumes/L/bea_res/Data/Tasks/MGSEncMem/7T/*/*/*view.csv"
.make/recall_csv.ls: alwaysrun |.make
	mkls $@ "/Volumes/L/bea_res/Data/Tasks/MGSEncMem/7T/*/*/*recall.csv"

# 20200714 - task 1d files generated from ormas dir: /Volumes/Zeus/Orma/7T_MGS/scripts/
.make/task_1d.ls: .make/task_csv.ls 
	mri/Orma_MGS/01_make_timing.R
	mkls $@ "/Volumes/Zeus/Orma/7T_MGS/data/1*_2*/*_cue.1D"

# 20200714 - initially as an example. uses recall/no recall as well as task onset
.make/task_1d_notused.ls: .make/task_csv.ls .make/recall_csv.ls
	mri/020_task_onsets.R
	mkls $@ "mri/1d/trial_hasimg_lr/*"

mri/txt/ld8_age_sex.tsv:
	./all_age_sex.bash
mri/txt/rest_fd.csv:
	./mri/030_getfd.R

.make/raw_folders.ls: alwaysrun | .make
	mkls $@ '/Volumes/Hera/Raw/MRprojects/7TBrainMech/*[lL]una*/'

.make/bids.ls: .make/rawlinks.ls
.make/rawlinks.ls: .make/raw_folders.ls
	mri/001_dcm2bids.bash
	mkls .make/rawlinks.ls '/Volumes/Hera/Raw/BIDS/7TBrainMech/rawlinks/1*_2*/'
	mkls .make/bids.ls '/Volumes/Hera/Raw/BIDS/7TBrainMech/sub-1*/*/*/*.nii.gz'

.make/preproc.ls: .make/bids.ls
	mri/010_preproc.bash
	mkls $@ '/Volumes/Zeus/preproc/7TBrainMech_*/*/1*_2*/.*_complete'

.make/FS_missing.txt: alwaysrun | .make
	# Always run. update file mod time if we still have missing FS
	# so we know to run mri/011_FS.bash even if bids file hasn't changed
	# mkmissing is from lncdtools
	mkmissing -1 '/Volumes/Hera/Raw/BIDS/7TBrainMech/sub-*/2*/anat/sub-*_T1w.nii.gz' -2 '/Volumes/Hera/Projects/7TBrainMech/FS/1*_2*/'  -p '\d{5}[/-_]\d{8}' -s '[/-]' -r _ -o $@

mri/FS/recent_transfer_to.txt: .make/bids.ls .make/FS_missing.txt
	# 20200309 - PSU grant expired. using local. ignore this
	# N.B. freesurfer runs asynchronously. so we might need to rerurn fetch even if .make/bids.ls hasn't changed
	# when we send new files, recent_transfer_to.txt is updateded only if we transfered or submited 
	mri/FS/001_toPSC.bash | grep '^>|^Submitted' | mkifdiff $@

.make/FS.ls: .make/rawlinks.ls .make/FS_missing.txt
	mri/FS/001_runlocal.bash
	mkls $@ "/Volumes/Hera/Projects/7TBrainMech/FS/1*_2*/mri/aseg.mgz"

# 
# .make/missing_rawcsi.ls: alwaysrun
# 	mkmissing -1 '/Volumes/Hera/Raw/BIDS/7TBrainMech/rawlinks/1*_2*/*Scout33*' -2 '/Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/*/SI1/'  -p '(?<=[/-])\d{5}' -o $@
 
.make/rawmrsi.ls: alwaysrun
	# probably no fast way to make sure we have no new files
	find /Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/  -iname spreadsheet.csv -and -not -ipath '*Thal*' -and -not -ipath '*20190507processed*' | mkifdiff $@

.make/MRSI_coord.ls: .make/FS.ls .make/rawmrsi.ls
	# do all also makes csi_roi_gmmax_tis_values_20190411
	./mri/MRSI/90_doall.bash
	#mkls $@ '/Volumes/Hera/Projects/7TBrainMech/subjs/*/slice_PFC/MRSI/all_probs.nii.gz'
	# 20200309 only care about rorig and company
	#mkls $@ '/Volumes/Hera/Projects/7TBrainMech/subjs/*/slice_PFC/MRSI/parc_group/rorig.nii'

# mri/MRSI/csi_roi_gmmax_tis_values_20190411.txt: MRSI_coord.ls

.make/scout.ls: .make/rawlinks.ls
	mri/MRSI/01_get_slices.bash all
	mkls $@ "/Volumes/Hera/Projects/7TBrainMech/subjs/*/slice_PFC/slice_pfc.nii.gz"

.make/parc_res.ls: .make/FS.ls .make/scout.ls
	@ NOCSV=1 DISPLAY= mri/MRSI/02_label_csivox.bash ALL
	mkls $@ "/Volumes/Hera/Projects/7TBrainMech/subjs/*/slice_PFC/MRSI/parc_group/rorig.nii"

.make/mrsi_roi_setup.ls: .make/parc_res.ls 
	# TODO: when ROI mask changes, change here
	mri/MRSI_roi/000_setupdirs.bash
	mkls $@ "/Volumes/Hera/Projects/7TBrainMech/subjs/1*_2*/slice_PFC/MRSI_roi/raw/slice_roi_MPOR20190425_CM_1*_2*.txt"

mri/txt/status.csv: .make/FS.ls .make/preproc.ls .make/mrsi_roi_setup.ls
	mri/900_status.R

mri/txt/onset_and_recall_trialinfo.csv:
	cd mri && ./020_task_onsets.R

mri/txt/task_trs.txt: .make/bids.ls
	cd mri && ./014_actual_tr.bash| sponge $@


## Documentation attempts. old interawiki; docs/* markdown
readme.dwiki:
	# curl -d "u=<username>&p=<password>" --cookie-jar .doku_cjar http://arnold.wpic.upmc.edu/dokuwiki/doku.php?do=login
	curl --cookie .doku_cjar --cookie-jar .doku_cjar "http://arnold.wpic.upmc.edu/dokuwiki/doku.php?id=studies:7t:processingpipelines&do=export_raw" > $@

site/sitemap.xml: $(wildcard docs/*md)
	# pip install mkdocs mkdocs-material mkdocsstrings
	mkdocs gh-deploy
