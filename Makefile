MAKEFLAGS += --no-builtin-rules
.SUFFIXES:
.PHONY: all FS

all: mri/txt/status.csv

.make/rawlinks.ls .make/bids.ls: $(wildcard /Volumes/Hera/Raw/MRprojects/7TBrainMech/*/)
	mri/001_dcm2bids.bash
	mkls .make/rawlinks.ls '/Volumes/Hera/Raw/BIDS/7TBrainMech/rawlinks/1*_2*/'
	mkls .make/bids.ls '/Volumes/Hera/Raw/BIDS/7TBrainMech/sub-1*/*/*/*.nii.gz'
	
.make/preproc.ls: .make/bids.ls
	mri/010_preproc.bash
	mkls $@ '/Volumes/Zeus/preproc/7TBrainMech_*/*/1*_2*/.*_complete'

.make/FS_missing.txt:
	# Always run. update file mod time if we still have missing FS
	# so we know to run mri/011_FS.bash even if bids file hasn't changed
	# mkmissing is from lncdtools
	mkmissing -1 '/Volumes/Hera/Raw/BIDS/7TBrainMech/sub-*/2*/anat/sub-*_T1w.nii.gz' -2 '/Volumes/Hera/Projects/7TBrainMech/FS/*/'  -p '(?<=[/-])\d{5}' -o $@

.make/FS.ls: .make/bids.ls .make/FS_missing.txt
	# N.B. freesurfer runs asynchronously. so we might need to rerurn fetch even if .make/bids.ls hasn't changed
	echo bash mri/011_FS.bash
	mkls $@ '/Volumes/Hera/Projects/7TBrainMech/FS/*/mri/aseg.mgz'
	# todo touch file if any are missing


.make/missing_rawcsi.ls: 
	mkmissing -1 '/Volumes/Hera/Raw/BIDS/7TBrainMech/rawlinks/1*_2*/*Scout33*' -2 '/Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/20180216Luna1/SI1/'  -p '(?<=[/-])\d{5}' -o $@

.make/rawmrsi.ls:
	# probably no fast way to make sure we have no new files
	find /Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/  -iname spreadsheet.csv -and -not -ipath '*Thal*' -and -not -ipath '*20190507processed*' | mkls $@
	
.make/MRSI_coord.ls: .make/FS.ls .make/rawmrsi.ls
	# do all also makes csi_roi_gmmax_tis_values_20190411
	./mri/MRSI/90_doall.bash
	mkls $@ '/Volumes/Hera/Projects/7TBrainMech/subjs/*/slice_PFC/MRSI/all_probs.nii.gz'

# mri/MRSI/csi_roi_gmmax_tis_values_20190411.txt: MRSI_coord.ls

mri/txt/status.csv: .make/FS.ls .make/preproc.ls .make/MRSI_coord.ls
	mri/900_status.R
