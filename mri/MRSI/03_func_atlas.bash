#!/usr/bin/env bash
set -e
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
# get values from functional (finn) atlas
#
# 20190416WF - add fabio's subjects

if [ $# -eq 0 ]; then
   matlab -nodisplay -r "try, run('subj_db.m'); end; quit" # csi_roi_max_values.txt
elif [ $1 == FF ]; then 
   matlab -nodisplay -r "try, run('FF_subjs.m'); end; quit"
else
   matlab -nodisplay -r "try,addpath('/Volumes/Zeus/DB_SQL'); csi_vox_probcomb(subject_files('$1')) ;catch e, disp(e), end; quit" # csi_roi_max_values.txt

fi
