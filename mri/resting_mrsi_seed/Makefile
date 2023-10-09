.make/corr-maps.txt: ./mkcorr.bash .make/roi-seeds.txt
	./mkcorr.bash all
	#mkls $@ 'subjs/1*_2*/conn_mrsi_rest/mxcovsph/*_corr-r.nii.gz'
	mkls $@ 'subjs/1*_2*/conn_mrsi_rest/mxcovsph/*_deconreml-r.nii.gz'

.make/roi-seeds.txt: ./mkseeds.bash |.make
	./mkseeds.bash
	mkls $@ 'roi-cnt/*_cnt_gm-0.5_mxsph-9.nii.gz'

roi-cnt/all_cube-4.5.nii.gz: onemask.bash
	# Not chmod +x b/c run and done (?)
	bash ./onemask.bash

.make/mrsipfc13_ts.ls: mkTS_roi.bash $(wildcard /Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_nowarp/*/brnsdkm_func_4.nii.gz)
	./mkTS_roi.bash all
	mkls $@ '/Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_nowarp/*/mrsipfc13_nzmean_ts.1D'

# 20230927 - want no bandpass version
.make/mrsipfc13_nsdkm_ts.ls: $(wildcard /Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_nowarp/*/nsdkm_func_4.nii.gz)
	TSSUFFIX=_nsdkm ./mkTS_roi.bash $^
	mkls $@ '/Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_nowarp/*/mrsipfc13_nzmean_nsdkm_ts.1D'

.make:
	@mkdir -p .make
