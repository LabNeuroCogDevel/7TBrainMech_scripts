# see ../Makefile
.PHONY:always
.SUFFIXES:
.SECONDARY: # don't remove intermediates, same as 'PRECIOUS: every file'
all: .make/nosmooth_nowarp_decon.txt

txt/missing_scans.txt: always
	./db_scanlog_restacq.bash |awk -F'\t' '$$2==""{print}' > $@

.make/nosmooth_nowarp_decon.txt: .make/nosmooth_nowarp_toT1.list
	# 
	./023b_deconvolve_tent_nosmooth.bash $(shell cat $<|sed 's:0[1-4]/Wn.*::'|sort -u) # /Volumes/Hera/Projects/7TBrainMech/pipelines/MHTask_nost_nowarp_nosmooth/1*_2*/
	mkls $@ '/Volumes/Hera/Projects/7TBrainMech/subjs/1*_2*/MGSEncMem/nowarpnosmooth/*_lrimg_tent_task_errts.nii.gz'

# 3dinfo -ad3 -iname /Volumes/Hera/Projects/7TBrainMech/pipelines/MHTask_nost_nowarp_nosmooth/1*_2*/*/Wnfdkm_func.nii.gz|grep 1.999| tee /tmp/7t_nosmooth_bad_warps.txt
# awk '{print $NF}' /tmp/7t_nosmooth_bad_warps.txt|xargs rename s/.nii.gz/_204x204x199.nii.gz/
#
.make/nosmooth_nowarp_toT1.list: $(wildcard /Volumes/Hera/Projects/7TBrainMech/pipelines/MHTask_nost_nowarp_nosmooth/1*_2*/0*/nfdkm_func.nii.gz) | .make
	# pp 7TBrainMech MHTask_nost_nowarp_nosmooth
	./011_nowarp_to_t1.bash $(dir $?)
	mkls $@ '/Volumes/Hera/Projects/7TBrainMech/pipelines/MHTask_nost_nowarp_nosmooth/1*_2*/0*/Wnfsdkm_func_4.nii.gz'

.make/rest-dencrct-maybe.list: $(wildcard /Volumes/Hera/Projects/7TBrainMech*_rest/pipelines/MHRest_nost_ica/1*_2*/brnaswdkm_func_4.nii.gz)
	./012b_link_rest-ica_dencor-maybe.bash
	mkls $@ '/Volumes/Hera/Projects/7TBrainMech/subjs/1*_2*/preproc/rest-ica_dencor-maybe/brnaswdkm_func_4.nii.gz'
%/:
	mkdir -p $@

../../7T_brainwarp_40mprage-only.nii.gz: .make/rest-dencrct-maybe.list
	4dConcatSubBriks -o $@ -- `stat -c "%N" subjs/1*_2*[0-9]/preproc/rest-ica_dencor-maybe|grep -v DenCrct|ld8|sort -u| xargs printf /Volumes/Hera/preproc/7TBrainMech_rest/MHT1_2mm/%s/mprage_nonlinear_warp_MNI_2mm_bet.nii.gz' '`

# TSNR
GLASSER_MMP := /opt/ni_tools/atlas/MMP_1.0_MNI-Glasser2016/MMP_in_MNI_corr.nii.gz
ALLREST := $(shell bash -c 'ls /Volumes/Hera/preproc/7TBrainMech_{rest/MHRest_nost{,_ica}/1*_2*/,mgsencmem/MHTask_nost/1*_2*/*}/wdkm_func.nii.gz')
ALLTSNR := $(addsuffix /tsnr/wdkm_tsnr.nii.gz,$(dir $(ALLREST)))
RESTEXAMPLE := /Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost/11868_20211025/brnswdkm_func_4.nii.gz
atlas/glasser.nii.gz: $(RESTEXAMPLE) | atlas/
	3dresample -rmode NN -inset '3dcalc( -a $(GLASSER_MMP) -short -expr a )' -master $(RESTEXAMPLE) -prefix $@
%/tsnr/wdkm_tsnr.nii.gz: | %/wdkm_func.nii.gz
	./013_tsnr.bash $| # making '$@'
txt/glasser_tsnr.txt: atlas/glasser.nii.gz $(ALLTSNR)
	3dROIstats -nzvoxels -nzmean -nomeanout -mask atlas/glasser.nii.gz $(ALLTSNR) > $@

#txt/calc_rest_tr.txt:
#	./calc_tr.bash
#
txt/calc_rest_tr.txt:
	./014_actual_tr.bash BIDS/bids_folder/sub-1*/20*/func/sub-*_task-rest*_bold.nii.gz | tee $@
