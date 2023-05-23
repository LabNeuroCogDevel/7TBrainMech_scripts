#!/usr/bin/env bash
#
# whole brain analysis
#
# 20230518WF - init
#


# Subj	vdate	visitno	vtype	age	sex	visitno_r	InputFile
#   1        2       3      4   5     6           7           8

3dMVM \
 -prefix mvm_age.nii.gz \
 -bsVars 'sex'      \
 -wsVars 'age'         \
 -qVars 'age' \
 -jobs 32 \
 -dataTable "$(cut -f 1,5,6,8 datatable.tsv)" \

# -num_glt 1\
# -gltLabel 1 'F' -gltCode 1 'sex : 1*F age : 0' \
