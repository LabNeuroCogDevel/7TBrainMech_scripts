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
txt/met_long.csv: txt/13MP20200207_LCMv2fixidx.csv
	Rscript -e "source('funcs.R'); write.csv(make_long(),'txt/met_long.csv')"


# 20230320
# after './coord_builder.bash place putamen'
all_putamen2.nii.gz: $(wildcard ../../../subjs/1*/slice_PFC/MRSI_roi/putamen2/*/cmsphere-mni.nii.gz)
	4dConcatSubBriks -o all_putamen2.nii.gz -- ../../../subjs/1*/slice_PFC/MRSI_roi/putamen2/*/cmsphere-mni.nii.gz
all_putamen2_cnt.nii.gz: all_putamen2.nii.gz
	3dTstat -overwrite -prefix all_putamen2_cnt.nii.gz -nzcount all_putamen2.nii.gz
.make/putamen_lcmodel.ls: $(wildcard /Volumes/Hera/Projects/7TBrainMech/subjs/1*_2*/slice_PFC/MRSI_roi/putamen2/*/spectrum.*)
	ml putamen2_lcmodel.m
	mkls $@ '/Volumes/Hera/Projects/7TBrainMech/subjs/10129_20180917/slice_PFC/MRSI_roi/putamen2/*/spectrum.*dir/spreadsheet.csv'

txt/putamen_gm.csv: $(wildcard ../../../subjs/1*_2*/slice_PFC/MRSI_roi/putamen2/*/coords_mprage.nii.gz)
	./putamen_gmcount.bash
txt/putamen_lcmodel.csv: .make/putamen_lcmodel.ls txt/putamen_gm.csv
	./putamen_lcmodel2csv.R
