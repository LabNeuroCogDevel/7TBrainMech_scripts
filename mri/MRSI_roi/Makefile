all: .make/slice_roi.ls

atlas_roi: roi_locations/ROI_mni_13MP20200207.nii.gz

roi_locations/ROI_mni_13MP20200207.nii.gz: | roi_locations/20200207_rmsome.bash
	roi_locations/20200207_rmsome.bash
#mkcoords/csi_rois_mni_MPRO_20190425.nii.gz  mkcoords/mni_coords_MPOR_20190425_labeled.txt:
#	mkcoords/01_11323_spheres_to_mni_cm.bash

# mni_coords_nolabel.txt csi_rois_mni.nii.gz:
# 	./mkroimni.bash

# find scout_pfc
.make/slicepfc.ls:
	../MRSI/01_get_slices.bash all
	@mkls $@ '/Volumes/Hera/Projects/7TBrainMech/subjs/*/slice_PFC/slice_pfc.nii.gz'

# rorig.nii.gz is freesurfer warpped to scout space
.make/FS_scout_registration.ls: .make/slicepfc.ls
	NOCSV="1" SHOWFINAL="" ../MRSI/02_label_csivox.bash ALL 
	@mkls $@ '/Volumes/Hera/Projects/7TBrainMech/subjs/*/slice_PFC/MRSI/parc_group/rorig.nii'

.make/slice_roi.ls: .make/FS_scout_registration.ls atlas_roi
	SHOWFINISH="" ./000_setupdirs.bash all
	@mkls $@ '/Volumes/Hera/Projects/7TBrainMech/subjs/*/slice_PFC/MRSI_roi/raw/slice_roi*.txt'

txt/13MP20200207_LCMv2fixidx.csv: $(wildcard /Volumes/Hera/Projects/7TBrainMech/subjs/1*_2*/slice_PFC/MRSI_roi/LCModel/v2idxfix/)
	./050_merge.R
