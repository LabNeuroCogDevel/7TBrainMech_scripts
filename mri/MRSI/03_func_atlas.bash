#!/usr/bin/env bash
set -e
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
# get values from functional (finn) atlas
#
# 20190416WF - add fabio's subjects

if [ $# -eq 0 ]; then
   matlab -nodisplay -r "try, run('subj_db.m'); end; quit" # csi_roi_max_values.txt
else
   [ $1 != FF ] && exit 1
   matlab -nodisplay -r "try, run('FF_subjs.m'); end; quit"
fi
