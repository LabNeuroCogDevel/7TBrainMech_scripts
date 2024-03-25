MAKEFLAGS += --no-builtin-rules
.SUFFIXES:
.SECONDARY: # don't remove intermediates, same as 'PRECIOUS: every file'
.PHONY: all all-voxstats funcres
# unset datalad to not use like
#   DATALAD= make

DATALAD ?= datalad run --explicit -o $@

all: stats/MRSI_pfc13_H.csv datatable.tsv stats/schaefer2018N17_H.csv

txt/nolds_dfa.csv:
	python3 hurst_nolds.py

datatable.tsv:
	./mkDataTable.R

../MRSI_roi/13MP20200207_covcentered.nii.gz:
	make -C ../MRSI_roi/ $@

.make/brnaswdkm_func_4: | .make
	mkls $@ '/Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_ica/1*_2*/brnaswdkm_func_4.nii.gz'

# 20240318 (create 20240307 FC/MP)
# gray matter mask
atlas/13MP20200207_mancov-centered_GMgt0.5-mask.nii.gz: ../MRSI_roi/13MP20200207_mancov-centered.nii.gz
	./gm_mask.bash $< $@
atlas/13MP-MNI_GMgt0.5-mask.nii.gz: ../MRSI_roi/roi_locations/ROI_mni_13MP20200207.nii.gz | atlas/
	./gm_mask.bash $< $@

# BAD!! need warp not resample!
#EXAMPLEFUNC:=/Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_nowarp/11868_20211025/brnsdkm_func_4.nii.gz
#funcres: atlas/13MP20200207_mancov-centered_GMgt0.5-mask_funcres.nii.gz atlas/13MP-MNI_GMgt0.5-mask_funcres.nii.gz
#%_funcres.nii.gz: %.nii.gz
#	3dresample -inset $^ -master $(EXAMPLEFUNC) -prefix $@ -overwrite

ts/mancov-brnasw.tseries-all.1D: atlas/13MP20200207_mancov-centered_GMgt0.5-mask.nii.gz | ts/
	3dROIstats -nomeanout -nzmean -1DRformat -mask $^ \
		/Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_ica/10129_20180917/brnaswdkm_func_4.nii.gz > $@

# have 3 different inputs for voxelwise hurst
# dencrct_matlab_H.nii.nii  matlab_H.nii.gz  py_dencrct_brnaswdkm_hurst_rs.nii.gz

.make/matlab_voxelwise.ls:
	matlab -nodisplay -r hurst_wholebrain.m
	mkls $@ 'hurst_nii/1*_2*/dencrct_matlab_H.nii.nii'

.make/py_voxelwise_hurst.ls:
	./hurst_nii.py
	mkls $@ 'hurst_nii/1*_2*/py_dencrct_brnaswdkm_hurst_rs.nii.gz'
.make/py_voxelwise_dfa.ls:
	./hurst_nii.py
	mkls $@ 'hurst_nii/1*_2*/py_dencrct_*_dfa.nii.gz'

## Matlab derived hurst
all-voxstats: \
	stats/hurstml_mean-vox_atlas-MP13GM_prefix-brnasw.csv \
	stats/hurstrs_mean-vox_atlas-MP13GM_prefix-brnasw.csv \
	stats/hurstml_mean-vox_atlas-cov6GM_prefix-brnasw.csv \
	stats/hurstrs_mean-vox_atlas-cov6GM_prefix-brnasw.csv \
	stats/dfa_mean-roi_atlas-cov6GM_prefix-brnasw.csv \
	stats/dfa_mean-vox_atlas-cov6GM_prefix-brnasw.csv \
	stats/dfa_mean-vox_atlas-MP13GM_prefix-brnasw.csv \
	stats/hurstrs_mean-roi_atlas-MP13GM_prefix-brnasw.csv \
	stats/dfa_mean-roi_atlas-MP13GM_prefix-brnasw.csv \
	stats/hurstrs_mean-roi_atlas-cov6GM_prefix-brnasw.csv
	#stats/hurstml_mean-roi_atlas-cov6GM_prefix-brnasw.csv \
	#stats/hurstml_mean-roi_atlas-cov6GM_prefix-brnasw.csv \

# roi atlas masks
COV6GM := atlas/13MP20200207_mancov-centered_GMgt0.5-mask.nii.gz
MP13GM := atlas/13MP-MNI_GMgt0.5-mask.nii.gz 

### ROI mean TS hurst/dfa
ts/atlas-cov6GM_prefix-brnasw/: $(COV6GM) .make/brnaswdkm_func_4
	./01_roi-meants.bash -outdir $@ -atlas $(COV6GM) -- $(shell cat .make/brnaswdkm_func_4)
ts/atlas-MP13GM_prefix-brnasw/: $(MP13GM) .make/brnaswdkm_func_4
	./01_roi-meants.bash -outdir $@ -atlas $(MP13GM) -- $(shell cat .make/brnaswdkm_func_4)

stats/dfa_mean-roi_atlas-MP13GM_prefix-brnasw.csv: ts/atlas-cov6GM_prefix-brnasw/
	$(DATALAD) ./02_roimean_hurst.bash -indir $^ -atlas  $(MP13GM) -output $@ -method dfa
stats/hurstrs_mean-roi_atlas-MP13GM_prefix-brnasw.csv: ts/atlas-cov6GM_prefix-brnasw/
	$(DATALAD) ./02_roimean_hurst.bash -indir $^ -atlas  $(MP13GM) -output $@ -method hurst_rs
stats/dfa_mean-roi_atlas-cov6GM_prefix-brnasw.csv: ts/atlas-cov6GM_prefix-brnasw/
	$(DATALAD) ./02_roimean_hurst.bash -indir $^ -atlas  $(COV6GM) -output $@ -method dfa
stats/hurstrs_mean-roi_atlas-cov6GM_prefix-brnasw.csv: ts/atlas-cov6GM_prefix-brnasw/
	$(DATALAD) ./02_roimean_hurst.bash -indir $^ -atlas  $(COV6GM) -output $@ -method hurst_rs

#### HURST/DFA VOXELWISE

# NB. wildcard is empty if .make/matlab_voxelwise.ls hasn't run
MATLAB_HURST_VOX=$(wildcard hurst_nii/1*_2*/dencrct_matlab_H.nii.nii)
PY_BRNASWDKM_HURST_VOX=$(wildcard hurst_nii/1*_2*/py_dencrct_brnaswdkm_hurst_rs.nii.gz)
PY_BRNASWDKM_DFA_VOX=$(wildcard hurst_nii/1*_2*/py_dencrct_brnaswdkm_dfa.nii.gz)

## ML
# manually inspected coverage center for dlpfc acc and mpfc
stats/hurstml_mean-vox_atlas-cov6GM_prefix-brnasw.csv: $(COV6GM) .make/matlab_voxelwise.ls
	$(DATALAD) ./02_grpmaskave_voxhurst.bash $@ $< $(MATLAB_HURST_VOX)
# original ROI locations
stats/hurstml_mean-vox_atlas-13MPGM_prefix-brnasw.csv: $(MP13GM) .make/matlab_voxelwise.ls
	$(DATALAD) ./02_grpmaskave_voxhurst.bash $@ $< $(MATLAB_HURST_VOX)

## PY HURST
# coverage
stats/hurstrs_mean-vox_atlas-MP13GM_prefix-brnasw.csv: $(MP13GM) .make/py_voxelwise_hurst.ls
	$(DATALAD) ./02_grpmaskave_voxhurst.bash $@ $< $(PY_BRNASWDKM_HURST_VOX)
# original ROI locations
stats/hurstrs_mean-vox_atlas-cov6GM_prefix-brnasw.csv: $(COV6GM) .make/py_voxelwise_hurst.ls 
	$(DATALAD) ./02_grpmaskave_voxhurst.bash $@ $< $(PY_BRNASWDKM_HURST_VOX)

## PY DFA
# manually identified coverage 
stats/dfa_mean-vox_atlas-cov6GM_brnasw.csv: $(COV6GM) .make/py_voxelwise_dfa.ls 
	$(DATALAD) ./02_grpmaskave_voxhurst.bash $@ $< $(PY_BRNASWDKM_DFA_VOX)
# original ROI locations
stats/dfa_mean-vox_atlas-MP13GM_prefix-brnasw.csv: $(MP13GM) .make/py_voxelwise_dfa.ls 
	$(DATALAD) ./02_grpmaskave_voxhurst.bash $@ $< $(PY_BRNASWDKM_DFA_VOX)

#### 
stats/schaefer2018N17_H.csv: .make/schaefer1d.ls
	ml hurst_schaefer.m

stats/roi-naccamyghpc_H-brnswdkm.csv: .make/nacc_amyg_hpc-brnswdkm_1d.ls
	ml -e "hurst_ROI('$@', 6, $(call sed "s/^|$/'/g" $< | paste -sd,))"

stats/MRSI_pfc13_H.csv: ../resting_mrsi_seed/.make/mrsipfc13_ts.ls
	matlab -nodisplay -r 'try, run hurst; catch e; disp(e); end; quit'

.make/schaefer1d.ls: atlas/schaefer2018_17N_1000.nii.gz $(wildcard /Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost/1*_2*/brnswdkm_func_4.nii.gz) | .make/
	./mk1d_schaefer.bash all
	mkls $@ 'txt/*schaefer201817N*1D'

.make/nacc_amyg_hpc-brnswdkm_1d.ls: atlas/nacc_amyg_hpc.nii.gz $(wildcard /Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost/1*_2*/brnswdkm_func_4.nii.gz) | .make/
	ROI=atlas/nacc_amyg_hpc.nii.gz NROI=6 ./mk1d_schaefer.bash all
	mkls $@ 'txt/*nacc_amyg_hpc*1D'

../resting_mrsi_seed/.make/mrsipfc13_ts.ls: 
	make -C ../resting_mrsi_seed/ .make/$(notdir $@)
	# /Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_nowarp/*/mrsipfc13_nzmean_ts.1D

# resample to resting state
RESTEXAMPLE := /Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost/11868_20211025/brnswdkm_func_4.nii.gz
atlas/schaefer2018_17N_1000.nii.gz: /opt/ni_tools/atlas/schaefer2018/Schaefer2018_LocalGlobal/Parcellations/MNI/Schaefer2018_1000Parcels_17Networks_order_FSLMNI152_2mm.nii.gz
	3dresample -inset $< -master $(RESTEXAMPLE) -prefix $@ 
	3drefit -space MNI $@
atlas/nacc_amyg_hpc.nii.gz: /Volumes/Hera/Amar/atlas/hurst_rois/nacc_amyg_hpc.nii.gz
	3dresample -inset $^ -prefix $@ -master $(RESTEXAMPLE)


%/:
	mkdir -p $@
