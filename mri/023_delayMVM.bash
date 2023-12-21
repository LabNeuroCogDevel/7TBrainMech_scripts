#!/usr/bin/env bash

# build data table
REDO=false
dtfile=datatable_tent_dly.txt
starttr=2
endtr=6

# /Volumes/Hera/Projects/7TBrainMech/subjs/11757_20190322/MGSEncMem/11757_20190322_lrimg_deconvolve_tent.nii.gz

#  -- At sub-brick #26 'dly_tent#0_Coef' datum type is float:     -694.985 to       677.578
#  -- At sub-brick #28 'dly_tent#1_Coef' datum type is float:     -1193.96 to       691.295
#  -- At sub-brick #30 'dly_tent#2_Coef' datum type is float:      -1492.2 to       602.571
#  -- At sub-brick #32 'dly_tent#3_Coef' datum type is float:     -1654.75 to        904.36
#  -- At sub-brick #34 'dly_tent#4_Coef' datum type is float:     -1819.34 to       685.297
#  -- At sub-brick #36 'dly_tent#5_Coef' datum type is float:     -1543.57 to       1215.67
#  -- At sub-brick #38 'dly_tent#6_Coef' datum type is float:     -770.378 to       1450.35
#  -- At sub-brick #40 'dly_tent#7_Coef' datum type is float:     -459.747 to       1606.55
#  -- At sub-brick #42 'dly_tent#8_Coef' datum type is float:      -415.48 to       1691.03
#  -- At sub-brick #44 'dly_tent#9_Coef' datum type is float:     -415.705 to        1392.1
#  -- At sub-brick #46 'dly_tent#10_Coef' datum type is float:     -407.595 to       977.857
#  -- At sub-brick #48 'dly_tent#11_Coef' datum type is float:     -332.809 to       779.252
#  -- At sub-brick #50 'dly_tent#12_Coef' datum type is float:     -369.976 to       971.934
#  -- At sub-brick #52 'dly_tent#13_Coef' datum type is float:     -298.201 to       935.549
#  -- At sub-brick #54 'dly_tent#14_Coef' datum type is float:     -417.164 to        395.76


if [ ! -f $dtfile ] || [ $REDO = true ]; then
	echo -e "Subj\tTR\tInputFile" > $dtfile
	for tentfile in /Volumes/Hera/Projects/7TBrainMech/subjs/1*_2*/MGSEncMem/1*_2*_lrimg_deconvolve_tent.nii.gz; do

		predir=$(basename $tentfile)

		[[ ! $predir =~ 1[0-9]{4}_2[0-9]{7} ]] && echo "no id in $predir" && continue
		ld8="${BASH_REMATCH[0]}"

		for ((i = starttr; i <= endtr; i++)); do
			echo -e "$ld8\t$i\t$tentfile<dly_tent#${i}_Coef>" >> $dtfile
		done
	done
fi

# run 3dMVM
    3dMVM -prefix lrimg_tent_dly_hrfmvm.nii.gz \
        -wsVars 'TR' \
        -bsVars '1' \
        -jobs 4 \
        -dataTable @${dtfile} \
        -overwrite
