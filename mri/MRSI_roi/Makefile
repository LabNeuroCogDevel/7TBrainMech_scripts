all: .make/slice_roi.ls txt/13MP20200207_LCMv2fixidx.csv

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
	DISPLAY= NOCSV="1" SHOWFINAL="" ../MRSI/02_label_csivox.bash ALL 
	@mkls $@ '/Volumes/Hera/Projects/7TBrainMech/subjs/*/slice_PFC/MRSI/parc_group/rorig.nii'

.make/slice_roi.ls: .make/FS_scout_registration.ls atlas_roi
	SHOWFINISH="" ./000_setupdirs.bash all
	@mkls $@ '/Volumes/Hera/Projects/7TBrainMech/subjs/*/slice_PFC/MRSI_roi/raw/slice_roi*.txt'


#txt/id_sex_dob.txt:
#   # actually want id sex dob; not id age sex
#   # 20230511 inserted as reference. used by 050_merge when db is down. this code never run
#	 (echo -e "id\tage\tsex"; selld8 l |grep -P 'Scan\tBrainMech'|cut -f1-3) |mkifdiff $@

txt/13MP20200207_LCMv2fixidx.csv: $(wildcard /Volumes/Hera/Projects/7TBrainMech/subjs/1*_2*/slice_PFC/MRSI_roi/LCModel/v2idxfix/) txt/id_sex_dob.txt
	./050_merge.R # looks for */13MP20200207_picked_coords.txt and %s/spectrum*.dir/*csv
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

all_13MP20200207_cnt.nii.gz:
	./all_coverage.bash

all_13MP20200207_cnt_roimaxima.txt: all_13MP20200207_cnt.nii.gz roi_locations/ROI_mni_13MP20200207.nii.gz
	for mi in {1..13}; do 3dmaxima -min_dist 1000 -input "3dcalc( -a ./all_13MP20200207_cnt.nii.gz -b roi_locations/ROI_mni_13MP20200207.nii.gz -expr a*amongst(b,$$mi) -short )" 2>/dev/null|grep -Po '([-0-9.]{2,}( +|\))){3}'|tr '[)\n]' ' '; echo " $$mi"; done > $@

all_13MP20200207_centered.nii.gz: all_13MP20200207_cnt.nii.gz ./all_13MP20200207_cnt_roimaxima.txt  
	3dUndump -prefix $@ -master all_13MP20200207_cnt.nii.gz  -xyz -srad 5 -orient RAI ./all_13MP20200207_cnt_roimaxima.txt  -overwrite

13MP20200207_cnt_vol-per-roi.nii.gz: all_13MP20200207.nii.gz
	./coverage_roi4d.py 

SHELL:=/usr/bin/bash
13MP20200207_covcentered.nii.gz:  13MP20200207_cnt_vol-per-roi.nii.gz
	3dExtrema -sep_dist 40 -volume 13MP20200207_cnt_vol-per-roi.nii.gz |& \
		perl -slane '$$roi=$$1+1 if m/for Volume .(\d+)/; print "@F[2..4] $$roi" if m/^\s+1\s/' \
		> txt/cm-extrema_per-roi.txt
	3dUndump -prefix $@ -master 13MP20200207_cnt_vol-per-roi.nii.gz -xyz -srad 5 -orient RAI \
		txt/cm-extrema_per-roi.txt -overwrite

13MP20200207_mancov-centered.nii.gz: txt/MP_manual_coverage_center.txt
	3dUndump -prefix $@ -master 13MP20200207_cnt_vol-per-roi.nii.gz -xyz -srad 5 -orient RAI $< -overwrite
