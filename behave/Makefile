.PHONY: alwaysrun all

# all daw (pet and 7t)
all: all_daw.csv

.make:
	mkdir .make

# single file to represent all the raw task data
.make/task_mats.ls: alwaysrun | .make
	mkls $@ "/Volumes/L/bea_res/Data/Temporary*Raw*Data/7T/1*_2*/*_task.mat"

# convert mats to txt files
.make/task_txt.ls: .make/task_mats.ls daw2csv.m | .make
	matlab -nodisplay -nojvm -r 'try,daw2csv,end;quit'
	mkls $@ '/Volumes/Hera/Projects/7TBrainMech/subjs/*/daw/daw_*.txt'

# collapse all into one file
all_daw.csv: daw.R .make/task_txt.ls
	./daw.R
