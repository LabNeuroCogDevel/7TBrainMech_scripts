.PHONY: always all

all: txt/top_hbt_gm.csv txt/all_hc.csv

txt/hc_missing.txt: txt/all_hc.csv txt/hc_scanlog.txt
	./missing_hc.R

# 20230227 
txt/top_hbt_gm.csv: .make/placement_nii.ls
	# /Volumes/Hera/Projects/7TBrainMech/scripts/mri/Hc/spectrum/2*/hc_gm_rat.csv
	./05_select_fs_labels.R

txt/all_hc.csv: .make/lcmodel.ls
	./gen_csv.R

txt/hc_scanlog.txt: always
	./db_scanlog_hc_acqnum.bash|mkifdiff $@

.make/pdf.ls:  .make/specturm.ls | .make
	./gen_pdf.bash
	mkls $@ pdfs 

.make/specturm.ls: always | .make
	# N.B. files from MRRC are less stable. this is unlikely to grab everything
	mkls $@ /Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/HPC/*/ /Volumes/Hera/Raw/MRprojects/7TBrainMech/2*/Recon_CSI/CSIHC/

.make/anat_mat.ls: .make/specturm.ls
	./01.1_reorg_for_matlab_gui.bash
	mkls $@ "spectrum/*/anat.mat"

.make/FS.ls: always | .make
	# for more FS, rerun /Volumes/Hera/Projects/7TBrainMech/scripts/mri/FS/001_runlocal.bash
	mkls $@ "/Volumes/Hera/preproc/7TBrainMech_rest/FS/1*_2*/mri/aseg.mgz"

.make/FS7.2.ls: always | .make
	# for more FS, rerun 
	# /Volumes/Hera/Projects/7TBrainMech/scripts/mri/FS/001c_runlocal.bash all
	# /Volumes/Hera/Projects/7TBrainMech/scripts/mri/FS/001_runlocal_lowres.bash all
	mkls $@ "/Volumes/Hera/preproc/7TBrainMech_rest/FS7.2/*res/1*_2*/mri/aseg.mgz"


.make/FS_warped.ls: .make/anat_mat.ls .make/FS.ls
	./01.2.1_FS_to_HcScout.bash all
	mkls $@ "spectrum/*/FS_warp"

.make/HBT.ls: .make/FS7.2.ls
	@echo /Volumes/Hera/Projects/7TBrainMech/scripts/mri/FS/020_segHA.bash
	@echo LOWRES=1 /Volumes/Hera/Projects/7TBrainMech/scripts/mri/FS/020_segHA.bash
	@echo /Volumes/Hera/Projects/7TBrainMech/scripts/mri/FS/020_segThal.bash
	@echo LOWRES=1 /Volumes/Hera/Projects/7TBrainMech/scripts/mri/FS/020_segThal.bash
	mkls $@ "/Volumes/Hera/preproc/7TBrainMech_rest/FS7.2/*res/1*_2*/mri/*hippoAmygLabels-T1.v21.HBT.FSvoxelSpace*"
	

.make/FSmasks.ls: .make/FS_warped.ls .make/HBT.ls
	./01.2.2_FS72_roimasks.bash all
	# 20250109 - WF review with Dest... 04_fslabels.bash runs fs_label_idv.R which creates these hc_gm_rat.csv files. 01.2.2 creates gm mask need for this
	# maybe should be gm.nii.gz fils instead of gm_rat.csv files
	mkls $@ "spectrum/2*/hc_gm_rat.csv"

.make/orient.ls: $(wildcard spectrum/*/orient.txt)
	# ./02_mlgui.bash # gui roi placements by hand!
	mkstat $@ "spectrum/*/orient.txt"


.make/lcmodel.ls: .make/orient.ls
	./03_lcmodel_all.bash
	mkstat $@ "spectrum/*/*.dir"

.make/reorient_unrotate.ls: .make/orient.ls
	/opt/ni_tools/julia-1.7.2/bin/julia	view_placements.jl
	mkls $@ 'spectrum/*/hc_loc_unrotated.1d'

.make/reorient_unrotate_matlab.ls: .make/orient.ls
	matlab -nodisplay -r 'try, hc_loc_unrotated_matlab; catch e,e,end; quit' # making coordinates.txt
	matlab -nodisplay -r 'try, SaveCoordinates; catch e,e,end; quit' # making coordinates_m.txt
	mkls $@ 'spectrum/*/coordinates*.txt'


# previously just used view_placement to gen pdf to QC
# now (20230307) have placements.nii.gz
#qc/hc_placement.pdf: .make/anat_mat.ls
#	./view_placements.jl
#	pdftk  /tmp/Hc_loc_202*pdf cat output $@

.make/placement_nii.ls: .make/reorient_unrotate.ls fs_label_idv.R .make/FSmasks.ls
	./04_fslabels.bash all
	mkls $@ "spectrum/*/placements.nii.gz"

.make:
	@-mkdir $@

txt/hc_fs_lut.txt: /opt/ni_tools/freesurfer7.2/FreeSurferColorLUT.txt
	awk -f hc_lut.awk $^  > $@

# 20250325 - CSIHC files moved. espcially from the '20230324' directory
# these should be copied back out. 2Gb of siarray.1.1 files; 245G of CSIHC folders
txt/search_all_siarray.txt:
	sudo find /Volumes/Hera/Raw/MRprojects/7TBrainMech/ -iname 'siarray.1.1' > txt/search_all_siarray.txt


