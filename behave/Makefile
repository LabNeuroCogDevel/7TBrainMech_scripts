.PHONY: alwaysrun all

# all daw (pet and 7t)
all: all_daw.csv txt/upps_scored.csv txt/SR.csv

.make:
	mkdir .make

# single file to represent all the raw task data
.make/task_mats.ls: alwaysrun | .make
	mkls $@ "/Volumes/L/bea_res/Data/Temporary*Raw*Data/7T/1*_2*/*_task.mat"

# convert mats to txt files
.make/task_txt.ls: .make/task_mats.ls daw2csv.m 
	matlab -nodisplay -nojvm -r 'try,daw2csv,end;quit'
	mkls $@ '/Volumes/Hera/Projects/7TBrainMech/subjs/*/daw/daw_*.txt'

# use db to collect CBCL, YSR, ASR. from 7T doc currated by RAs
txt/SR.csv: alwaysrun
	./SR_db.R stdout | mkifdiff $@

# collapse all into one file
all_daw.csv: daw.R .make/task_txt.ls
	./daw.R

.make/qualtrics.ls: alwaysrun |.make
	# ./000_getQualtrics.R
	mkls $@ '/Volumes/L/bea_res/Data/Temporary*Raw*Data/7T/*/*_selfreport.csv'

svys.RData: .make/qualtrics.ls
	# ./000_getQualtrics.R
	
txt/asr_ysr.csv: svys.RData
	./ASRYSR.R
	
txt/upps_scored.csv: .make/qualtrics.ls
	./UPPS.R

txt/ders.csv: .make/qualtrics.ls
	./DERS_DTS.R

txt/dts.csv: txt/ders.csv
	@echo dts.csv and ders.csv bouth from DERS_DTS.R
