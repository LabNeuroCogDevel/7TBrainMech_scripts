## FS based
# subjs/*/slice_PFC/MRSI/2d_csi_ROI/ParcelCSIvoxel_lut.txt 
#    13 thal

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
