# see ../Makefile
.PHONY:always
all:  .make/nosmooth_nowarp_toT1.list

txt/missing_scans.txt: always
	./db_scanlog_restacq.bash |awk -F'\t' '$$2==""{print}' > $@

.make/nosmooth_nowarp_toT1.list: | .make
	# pp 7TBrainMech MHTask_nost_nowarp_nosmooth
	./011_nowarp_to_t1.bash /Volumes/Hera/Projects/7TBrainMech/pipelines/MHTask_nost_nowarp_nosmooth/1*_2*/0*
	mkls $@ '/Volumes/Hera/Projects/7TBrainMech/pipelines/MHTask_nost_nowarp_nosmooth/1*_2*/0*/Wnfsdkm_func_4.nii.gz'

%/:
	mkdir -p $@

