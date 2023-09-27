all: stats/MRSI_pfc13_H.csv datatable.tsv stats/schaefer2018N17_H.csv

txt/nolds_dfa.csv:
	python3 hurst_nolds.py

datatable.tsv:
	./mkDataTable.R

stats/schaefer2018N17_H.csv: .make/schaefer1d.ls
	ml hurst_schaefer.m

stats/MRSI_pfc13_H.csv: ../resting_mrsi_seed/.make/mrsipfc13_ts.ls
	matlab -nodisplay -r 'try, run hurst; catch e; disp(e); end; quit'

.make/schaefer1d.ls: atlas/schaefer2018_17N_1000.nii.gz $(wildcard /Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost/1*_2*/brnswdkm_func_4.nii.gz) | .make/
	./mk1d_schaefer.bash all
	mkls $@ 'txt/*1D'
../resting_mrsi_seed/.make/mrsipfc13_ts.ls: 
	make -C ../resting_mrsi_seed/ .make/$(notdir $@)

RESTEXAMPLE := /Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost/11868_20211025/brnswdkm_func_4.nii.gz
atlas/schaefer2018_17N_1000.nii.gz: /opt/ni_tools/atlas/schaefer2018/Schaefer2018_LocalGlobal/Parcellations/MNI/Schaefer2018_1000Parcels_17Networks_order_FSLMNI152_2mm.nii.gz
	3dresample -inset $< -master $(RESTEXAMPLE) -prefix $@ 
	3drefit -space MNI $@

.make/:
	mkdir -p $@
