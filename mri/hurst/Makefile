MAKEFLAGS += --no-builtin-rules
.SUFFIXES:
.SECONDARY: # don't remove intermediates, same as 'PRECIOUS: every file'
.PHONY: all all-hurst all-pet

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

all-hurst: \
	stats/hurstml_mean-vox_atlas-MP13GM_prefix-brnasw.csv \
	stats/hurstrs_mean-vox_atlas-MP13GM_prefix-brnasw.csv \
	    stats/dfa_mean-vox_atlas-MP13GM_prefix-brnasw.csv \
	\
	stats/hurstml_mean-vox_atlas-cov6GM_prefix-brnasw.csv \
	stats/hurstrs_mean-vox_atlas-cov6GM_prefix-brnasw.csv \
	    stats/dfa_mean-vox_atlas-cov6GM_prefix-brnasw.csv \
	\
	stats/hurstrs_mean-roi_atlas-onlyGM_prefix-brnasw.csv \
	    stats/dfa_mean-roi_atlas-onlyGM_prefix-brnasw.csv \
	\
	stats/hurstrs_mean-roi_atlas-cov6GM_prefix-brnasw.csv \
	    stats/dfa_mean-roi_atlas-cov6GM_prefix-brnasw.csv \
	\
	stats/hurstrs_mean-roi_atlas-MP13GM_prefix-brnasw.csv \
	    stats/dfa_mean-roi_atlas-MP13GM_prefix-brnasw.csv \
	\
	stats/hurstrs_mean-roi_atlas-mrsi13_prefix-brnasw.csv \
	    stats/dfa_mean-roi_atlas-mrsi13_prefix-brnasw.csv \
		 \
	stats/hurstrs_mean-roi_atlas-mrsi13GM_prefix-brnasw.csv\
	    stats/dfa_mean-roi_atlas-mrsi13GM_prefix-brnasw.csv

	#stats/hurstml_mean-roi_atlas-cov6GM_prefix-brnasw.csv \
	#stats/hurstml_mean-roi_atlas-cov6GM_prefix-brnasw.csv \

## Matlab derived hurst
# roi atlas masks
COV6GM := atlas/13MP20200207_mancov-centered_GMgt0.5-mask.nii.gz
MP13GM := atlas/13MP-MNI_GMgt0.5-mask.nii.gz 
onlyGM := atlas/mni_gm50_mask.nii.gz
SchaeferVol := atlas/schaefer200_17N_2mm.nii.gz
Schaefer100Vol := atlas/schaefer100_17N_2mm.nii.gz
Schaefer1000Vol := atlas/schaefer1000_17N_2mm.nii.gz
GlasserMNI := atlas/glasser_2mm.nii.gz

### ROI mean TS hurst/dfa
ts/atlas-cov6GM_prefix-brnasw/: $(COV6GM) .make/brnaswdkm_func_4
	./01_roi-meants.bash -outdir $@ -atlas $(COV6GM) -- $(shell cat .make/brnaswdkm_func_4)
ts/atlas-MP13GM_prefix-brnasw/: $(MP13GM) .make/brnaswdkm_func_4
	./01_roi-meants.bash -outdir $@ -atlas $(MP13GM) -- $(shell cat .make/brnaswdkm_func_4)
ts/atlas-onlyGM_prefix-brnasw/: $(GM) .make/brnaswdkm_func_4
	./01_roi-meants.bash -outdir $@ -atlas $(onlyGM) -- $(shell cat .make/brnaswdkm_func_4)

# 20240606
ts/atlas-schaefer200N17_prefix-brnasw/: $(SchaeferVol) .make/brnaswdkm_func_4
	./01_roi-meants.bash -outdir $@ -atlas $(SchaeferVol) -- $(shell cat .make/brnaswdkm_func_4)
# 20240607
ts/atlas-schaefer100N17_prefix-brnasw/: $(Schaefer100Vol) .make/brnaswdkm_func_4
	./01_roi-meants.bash -outdir $@ -atlas $(Schaefer100Vol) -- $(shell cat .make/brnaswdkm_func_4)

ts/atlas-schaefer1000N17_prefix-brnasw/: $(Schaefer1000Vol) .make/brnaswdkm_func_4
	./01_roi-meants.bash -outdir $@ -atlas $(Schaefer1000Vol) -- $(shell cat .make/brnaswdkm_func_4)
# 20240611
ts/atlas-glasser_prefix-brnasw/: $(GlasserMNI) .make/brnaswdkm_func_4
	./01_roi-meants.bash -outdir $@ -atlas $(GlasserMNI) -- $(shell cat .make/brnaswdkm_func_4)


stats/dfa_mean-roi_atlas-MP13GM_prefix-brnasw.csv: ts/atlas-MP13GM_prefix-brnasw/
	$(DATALAD) ./02_roimean_hurst.bash -indir $^ -atlas  $(MP13GM) -output $@ -method dfa
stats/hurstrs_mean-roi_atlas-MP13GM_prefix-brnasw.csv: ts/atlas-MP13GM_prefix-brnasw/
	$(DATALAD) ./02_roimean_hurst.bash -indir $^ -atlas  $(MP13GM) -output $@ -method hurst_rs

stats/dfa_mean-roi_atlas-cov6GM_prefix-brnasw.csv: ts/atlas-cov6GM_prefix-brnasw/
	$(DATALAD) ./02_roimean_hurst.bash -indir $^ -atlas  $(COV6GM) -output $@ -method dfa
stats/hurstrs_mean-roi_atlas-cov6GM_prefix-brnasw.csv: ts/atlas-cov6GM_prefix-brnasw/
	$(DATALAD) ./02_roimean_hurst.bash -indir $^ -atlas  $(COV6GM) -output $@ -method hurst_rs


MRSI13GLOB:=/Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_nowarp/1*_2*/mrsipfc13_nzmean_ts.1D
stats/dfa_mean-roi_atlas-mrsi13_prefix-brnasw.csv: ../resting_mrsi_seed/.make/mrsipfc13_ts.ls
	$(DATALAD) ./02_roimean_hurst.bash -indir "$(MRSI13GLOB)" -atlas  mrsi13 -output $@ -method dfa
stats/hurstrs_mean-roi_atlas-mrsi13_prefix-brnasw.csv: ../resting_mrsi_seed/.make/mrsipfc13_ts.ls
	$(DATALAD) ./02_roimean_hurst.bash -indir "$(MRSI13GLOB)" -atlas  mrsi13 -output $@ -method hurst_rs
# gm masked
MRSI13GMGLOB:=/Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_nowarp/1*_2*/mrsipfc13_nzmean_gm_ts.1D
stats/dfa_mean-roi_atlas-mrsi13GM_prefix-brnasw.csv: ../resting_mrsi_seed/.make/mrsipfc13_gm_ts.ls
	$(DATALAD) ./02_roimean_hurst.bash -indir "$(MRSI13GMGLOB)" -atlas  mrsi13 -output $@ -method dfa
stats/hurstrs_mean-roi_atlas-mrsi13GM_prefix-brnasw.csv: ../resting_mrsi_seed/.make/mrsipfc13_gm_ts.ls
	$(DATALAD) ./02_roimean_hurst.bash -indir "$(MRSI13GMGLOB)" -atlas  mrsi13 -output $@ -method hurst_rs

stats/dfa_mean-roi_atlas-onlyGM_prefix-brnasw.csv: ts/atlas-onlyGM_prefix-brnasw/
	$(DATALAD) ./02_roimean_hurst.bash -indir $^ -atlas  $(onlyGM) -output $@ -method dfa
stats/hurstrs_mean-roi_atlas-onlyGM_prefix-brnasw.csv: ts/atlas-onlyGM_prefix-brnasw/
	$(DATALAD) ./02_roimean_hurst.bash -indir $^ -atlas  $(onlyGM) -output $@ -method hurst_rs

stats/dfa_mean-roi_atlas-schaefer200N17_prefix-brnasw.csv: ts/atlas-schaefer200N17_prefix-brnasw/
	$(DATALAD) ./02_roimean_hurst.bash -indir $^ -atlas  $(SchaeferVol) -output $@ -method dfa

stats/dfa_mean-roi_atlas-schaefer100N17_prefix-brnasw.csv: ts/atlas-schaefer100N17_prefix-brnasw/
	$(DATALAD) ./02_roimean_hurst.bash -indir $^ -atlas  $(Schaefer100Vol) -output $@ -method dfa

stats/dfa_mean-roi_atlas-schaefer1000N17_prefix-brnasw.csv: ts/atlas-schaefer1000N17_prefix-brnasw/
	$(DATALAD) ./02_roimean_hurst.bash -indir $^ -atlas  $(Schaefer1000Vol) -output $@ -method dfa

stats/dfa_mean-roi_atlas-glasser_prefix-brnasw.csv: ts/atlas-glasser_prefix-brnasw/
	$(DATALAD) ./02_roimean_hurst.bash -indir $^ -atlas $(GlasserMNI)  -output $@ -method dfa

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
#
stats/hurstml_mean-vox_atlas-MP13GM_prefix-brnasw.csv: $(MP13GM) .make/matlab_voxelwise.ls
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
stats/dfa_mean-vox_atlas-cov6GM_prefix-brnasw.csv: $(COV6GM) .make/py_voxelwise_dfa.ls 
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
../resting_mrsi_seed/.make/mrsipfc13_gm_ts.ls:
	make -C ../resting_mrsi_seed/ .make/$(notdir $@)
	# /Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_nowarp/*/mrsipfc13_nzmean_GM_ts.1D

# resample to resting state
RESTEXAMPLE := /Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost/11868_20211025/brnswdkm_func_4.nii.gz
atlas/schaefer2018_17N_1000.nii.gz: /opt/ni_tools/atlas/schaefer2018/Schaefer2018_LocalGlobal/Parcellations/MNI/Schaefer2018_1000Parcels_17Networks_order_FSLMNI152_2mm.nii.gz
	3dresample -inset $< -master $(RESTEXAMPLE) -prefix $@ 
	3drefit -space MNI $@
atlas/nacc_amyg_hpc.nii.gz: /Volumes/Hera/Amar/atlas/hurst_rois/nacc_amyg_hpc.nii.gz
	3dresample -inset $^ -prefix $@ -master $(RESTEXAMPLE)
# 20240607
atlas/schaefer100_17N_2mm.nii.gz:
	3dresample -rmode NN -inset /opt/ni_tools/atlas/schaefer2018/Schaefer2018_LocalGlobal/Parcellations/MNI/Schaefer2018_100Parcels_17Networks_order_FSLMNI152_2mm.nii.gz -master $(RESTEXAMPLE) -prefix $@
atlas/schaefer1000_17N_2mm.nii.gz:
	3dresample -rmode NN -inset /opt/ni_tools/atlas/schaefer2018/Schaefer2018_LocalGlobal/Parcellations/MNI/Schaefer2018_1000Parcels_17Networks_order_FSLMNI152_2mm.nii.gz -master $(RESTEXAMPLE) -prefix $@
# 20240611
$(GlasserMNI):
	3dresample -rmode NN -inset '3dcalc( -a $(GLASSER_MMP) -short -expr a )' -master $(RESTEXAMPLE) -prefix $@

# 20240605: schaefer volumetric 
#  02_hurst_to_surface.bash makes withheader
schaefer200_17N_2mm.nii.gz:
	3dresample\
	  -prefix schaefer200_17N_2mm.nii.gz \
	  -inset /opt/ni_tools/atlas/schaefer2018/Schaefer2018_LocalGlobal/Parcellations/MNI/Schaefer2018_200Parcels_17Networks_order_FSLMNI152_2mm.nii.gz\
	  -master hurst_nii/10129_20180917/dencrct_matlab_H-withheader.nii.gz

txt/schaefer200_17N_volumetric-matlab.tsv: schaefer200_17N_2mm.nii.gz
	3dROIstats -1DRformat \
	  -nzmean -nomeanout \
	  -mask schaefer200_17N_2mm.nii.gz \
	  hurst_nii/1*_2*/dencrct_matlab_H-withheader.nii.gz \
	  > txt/schaefer200_17N_volumetric-matlab.tsv

txt/schaefer200_17N_volumetric-pydfa.tsv: schaefer200_17N_2mm.nii.gz
	3dROIstats -1DRformat \
	  -nzmean -nomeanout \
	  -mask schaefer200_17N_2mm.nii.gz \
	  hurst_nii/1*_2*/py_dencrct_brnaswdkm_dfa.nii.gz \
	  > $@

# 20240607 - not used. voxelwise?
txt/schaefer100_17N_volumetric-pydfa.tsv: atlas/schaefer100_17N_2mm.nii.gz
	3dROIstats -1DRformat \
	  -nzmean -nomeanout \
	  -mask atlas/schaefer100_17N_2mm.nii.gz \
	  hurst_nii/1*_2*/py_dencrct_brnaswdkm_dfa.nii.gz \
	  > $@

# 20240606
txt/schaefer200_17N_surface-tsavg-pydfa.csv:
	./xcpd_surface_hurst.py

### 20240611 - PET mMR
all-pet: stats/pet/dfa_mean-roi_atlas-schaefer1000_17N_2mm.csv stats/pet/dfa_mean-roi_atlas-glasser.csv stats/rac2/dfa_mean-roi_atlas-schaefer1000_17N_2mm.csv stats/rac2/dfa_mean-roi_atlas-glasser.csv stats/pet/dfa_mean-roi_brnasw4_atlas-glasser.csv stats/pet/dfa_mean-roi_brnasw4_atlas-schaefer1000_17N_2mm.csv

PET_EXAMPLE := /Volumes/Hera/preproc/petrest_rac1/brnsuwdktm_rest/10195_20160317/brnswudktm_func_5.nii.gz
SHAEFER1000 := /opt/ni_tools/atlas/schaefer2018/Schaefer2018_LocalGlobal/Parcellations/MNI/Schaefer2018_1000Parcels_17Networks_order_FSLMNI152_2mm.nii.gz
GLASSER_MMP := /opt/ni_tools/atlas/MMP_1.0_MNI-Glasser2016/MMP_in_MNI_corr.nii.gz

# make atlases. "notdir" name of these used to make ts/ files and dfa_mean-roi
atlas/pet/schaefer1000_17N_2mm.nii.gz : | atlas/pet/
	3dresample -rmode NN -inset $(SHAEFER1000) -master $(PET_EXAMPLE) -prefix $@
atlas/pet/glasser.nii.gz: | atlas/pet/
	3dresample -rmode NN -inset '3dcalc( -a $(GLASSER_MMP) -short -expr a )' -master $(PET_EXAMPLE) -prefix $@

ts/pet/atlas-%: atlas/pet/%.nii.gz | ts/pet/
	./01_roi-meants.bash -outdir $@ -atlas $^ -- /Volumes/Hera/preproc/petrest_rac1/brnsuwdktm_rest/1*_2*/brnswudktm_func_5.nii.gz

#stats/pet/dfa_mean-roi_atlas-%.csv: ts/pet/atlas-% | stats/pet/
#	$(DATALAD) ./02_roimean_hurst.bash -indir $^/ -atlas atlas/pet/$(subst atlas-,,$(notdir $^)).nii.gz  -output $@ -method dfa

ts/pet/brnasw4_atlas-%: atlas/pet/%.nii.gz | ts/pet/
	./01_roi-meants.bash -outdir $@ -atlas $^ -- /Volumes/Hera/preproc/petrest_rac1/MHRest_FM_ica/1*_2*/brnaswudktm_func_4.nii.gz

stats/pet/dfa_mean-roi_%.csv: ts/pet/% | stats/pet/
	$(DATALAD) ./02_roimean_hurst.bash -indir $^/ -atlas atlas/pet/$(subst brnasw4_,,$(subst atlas-,,$(notdir $^))).nii.gz  -output $@ -method dfa


# pet rac2 (glasser and schaefer1000_17N_2mm)
ts/rac2/atlas-%: atlas/pet/%.nii.gz | ts/pet/
	./01_roi-meants.bash -outdir $@ -atlas $^ -- /Volumes/Hera/preproc/petrest_rac2/brnsuwdktm_rest/1*_2*/brnswudktm_func_5.nii.gz
stats/rac2/dfa_mean-roi_atlas-%.csv: ts/rac2/atlas-% | stats/rac2/
	$(DATALAD) ./02_roimean_hurst.bash -indir $^/ -atlas atlas/pet/$(subst atlas-,,$(notdir $^)).nii.gz  -output $@ -method dfa

%/:
	mkdir -p $@

