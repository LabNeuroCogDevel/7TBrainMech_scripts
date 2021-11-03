MAKEFLAGS += --no-builtin-rules
.SUFFIXES:
.PHONY: all FS alwaysrun

all: mri/txt/status.csv
.make:
	mkdir .make

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
	./030_getfd.R

.make/raw_folders.ls: alwaysrun | .make
	mkls $@ '/Volumes/Hera/Raw/MRprojects/7TBrainMech/*[lL]una*/'

.make/rawlinks.ls .make/bids.ls: .make/raw_folders.ls
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
	@ NOCSV=1 mri/MRSI/02_label_csivox.bash ALL
	mkls $@ "/Volumes/Hera/Projects/7TBrainMech/subjs/*/slice_PFC/MRSI/parc_group/rorig.nii"

.make/mrsi_roi_setup.ls: .make/parc_res.ls 
	# TODO: when ROI mask changes, change here
	mri/MRSI_roi/000_setupdirs.bash
	mkls $@ "/Volumes/Hera/Projects/7TBrainMech/subjs/1*_2*/slice_PFC/MRSI_roi/raw/slice_roi_MPOR20190425_CM_1*_2*.txt"

mri/txt/status.csv: .make/FS.ls .make/preproc.ls .make/mrsi_roi_setup.ls
	mri/900_status.R

readme.dwiki:
	# curl -d "u=<username>&p=<password>" --cookie-jar .doku_cjar http://arnold.wpic.upmc.edu/dokuwiki/doku.php?do=login
	curl --cookie .doku_cjar --cookie-jar .doku_cjar "http://arnold.wpic.upmc.edu/dokuwiki/doku.php?id=studies:7t:processingpipelines&do=export_raw" > $@

