.PHONY: always
txt/hc_missing.txt: txt/all_hc.csv txt/hc_scanlog.txt
	./missing_hc.R

txt/all_hc.csv:  .make/specturm.ls
	./gen_csv.R

txt/hc_scanlog.txt: always
	./db_scanlog_hc_acqnum.bash|mkifdiff $@

.make/pdf.ls:  .make/specturm.ls | .make
	./gen_pdf.bash
	mkls $@ pdfs 

.make/specturm.ls: always | .make
	# N.B. probably need to manually unzip HPC data
	mkls $@ /Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/HPC/*/

.make/anat_mat.ls: .make/specturm.ls
	./01.1_reorg_for_matlab_gui.bash
	mkls $@ "spectrum/*/anat.mat"

.make/FS.ls: always | .make
	# for more FS, rerun /Volumes/Hera/Projects/7TBrainMech/scripts/mri/FS/001_runlocal.bash
	mkls $@ "/Volumes/Hera/preproc/7TBrainMech_rest/FS/1*_2*/mri/aseg.mgz"

.make/FS_warped.ls: .make/anat_mat.ls .make/FS.ls
	./01.2_FS_to_HcScout.bash all
	mkls $@ "spectrum/*/FS_warp"

qc/hc_placement.pdf: .make/anat_mat.ls
	./view_placements.jl
	pdftk  /tmp/Hc_loc_202*pdf cat output $@

.make:
	@-mkdir $@

txt/hc_fs_lut.txt: /opt/ni_tools/freesurfer7.2/FreeSurferColorLUT.txt
	awk -f hc_lut.awk $^  > $@
