all: stats/MRSI_pfc13_H.csv datatable.tsv stats/schaefer2018N17_H.csv

txt/nolds_dfa.csv:
	python3 hurst_nolds.py

datatable.tsv:
	./mkDataTable.R

../MRSI_roi/13MP20200207_covcentered.nii.gz:
	make -C ../MRSI_roi/ $@
stats/voxelwise_meanH_dlpfc-acc-mpfc.csv: ../MRSI_roi/13MP20200207_covcentered.nii.gz 
	./02_grpmaskave_voxhurst.bash ../MRSI_roi/13MP20200207_covcentered.nii.gz $@

# original ROI locations
stats/voxelwise_meanH_origMNIatlas-dlpfc-acc-mpfc.csv: ../MRSI_roi/roi_locations/ROI_mni_13MP20200207.nii.gz
	./02_grpmaskave_voxhurst.bash $< $@

stats/voxelwise_meanH_mancov-dlpfc-acc-mpfc.csv: ../MRSI_roi/13MP20200207_mancov-centered.nii.gz
	./02_grpmaskave_voxhurst.bash $< $@

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


.make/:
	mkdir -p $@
