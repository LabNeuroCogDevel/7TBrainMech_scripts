.make/corr-maps.txt: ./mkcorr.bash .make/roi-seeds.txt
	./mkcorr.bash
	mkls $@ 'subjs/1*_2*/conn_mrsi_rest/mxcovsph/*_corr-r.nii.gz'

.make/roi-seeds.txt: ./mkseeds.bash |.make
	./mkseeds.bash
	mkls $@ 'roi-cnt/*_cnt_gm-0.5_mxsph-9.nii.gz'

.make:
	@mkdir -p .make
