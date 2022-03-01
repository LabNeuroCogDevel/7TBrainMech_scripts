.PHONY: all
all: maskave.csv

maskave.csv: .make/tat2.list .make/atlas.list
	./02_maskave_roi.bash

.make/atlas.list: |.make
	./make_atlases.bash
	mkls $@ atlas/

.make/tat2.list: $(wildcard /Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_ica/1*_2*[0-9]/wdkm_func.nii.gz ) |.make
	./01_tat2_all.bash
	mkls $@ out/1*_2*tat2.nii.gz

.make:
	mkdir .make

