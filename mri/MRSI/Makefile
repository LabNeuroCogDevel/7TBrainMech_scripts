## FS based
# subjs/*/slice_PFC/MRSI/2d_csi_ROI/ParcelCSIvoxel_lut.txt 
#    13 thal

txt/ids.txt: id_list.bash $(wildcard /Volumes/Hera/Raw/BIDS/7TBrainMech/rawlinks/1*_2*)
	./id_list.bash

# if we have new MR data, we can make new roi_slice.nii.gz files
.make/roi_slice.lst: 01_get_slices.bash txt/ids.txt
	./01_get_slices.bash missing
	mkls $@ '../../../subjs/1*_2*/slice_PFC/roi_slice.nii.gz'

# if we have new folders where all the spreadhseet.csv are, we can label regions
.make/csi_label.lst: 02_label_csivox.bash $(wildcard /Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/*/)
	./02_label_csivox.bash all
	mkls $@ '../../../subjs/1*_2*/slice_PFC/MRSI/all_csi.nii.gz'

## atlas roi based
csi_roi_max_values.txt: 03_func_atlas.bash subj_db.m
	./03_func_atlas.bash

# csi_roi_max_values.txt
#   3 left dlpfc
#   4 right dlpfc
#   6 ACC
#   7 thalamus
missing_subjects.txt: csi_roi_max_stats.R csi_roi_max_values.txt
	Rscript csi_roi_max_stats.R
