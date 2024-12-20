.PHONY: alwaysrun all

# all daw (pet and 7t)
all: all_daw.csv txt/upps_scored.csv txt/SR.csv

.make:
	mkdir .make

txt/7T_packet.xlsx:
	wget 'https://docs.google.com/spreadsheets/d/e/2PACX-1vR2-clq04Tnw0BWICY5PiEP5DlHoKuEsPuuaOnT3TKeSjfwpYxMViaw8LxVipq0NQ/pub?output=xlsx'
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
	echo ./000_getQualtrics.R # this takes a long time. unlikely to have new data
	
txt/puberty.csv: svys.RData
	./puberty_from_rdata.R

txt/asr_ysr.csv: svys.RData
	./ASRYSR.R
	
txt/upps_scored.csv: .make/qualtrics.ls
	./UPPS.R

txt/ders.csv: .make/qualtrics.ls
	./DERS_DTS.R

txt/dts.csv: txt/ders.csv
	@echo dts.csv and ders.csv bouth from DERS_DTS.R

# CANTAB finished. no depedencies b/c will not change
txt/SSP.csv: 
	Rscript SSP_Cantab_spatial.R

.make/anti_scored.ls: $(shell find "/Volumes/L/bea_res/Data/Temporary Raw Data/7T/" -iname '*anti*.eyd' | sed 's/ /\\ /g')
	"/Volumes/L/bea_res/Data/Temporary Raw Data/copy7T.bash"
	-/Volumes/Hera/Projects/autoeyescore/runme.bash -t anti
	mkls $@ "/Volumes/L/bea_res/Data/Tasks/Anti/Basic/1*/2*/Scored/txt/1*.2*.1.summary.txt"

txt/anti_scored.csv: .make/anti_scored.ls # $(wildcard  /Volumes/L/bea_res/Data/Tasks/Anti/Basic/1*/2*/Scored/txt/1*.2*.1.summary.txt)
	Rscript anti_behave.R

# added 20240314
txt/rt18.csv: .make/qualtrics.ls
	./RT18.R

txt/all_recall_summary.csv: txt/all_recall.csv
txt/all_recall.csv:
	./mgs_recall.R
