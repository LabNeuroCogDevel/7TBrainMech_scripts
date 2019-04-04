#!/usr/bin/env bash
set -e
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
# get values from functional (finn) atlas
#

matlab -nodisplay -r "try, run('subj_db.m'); end; quit" # csi_roi_max_values.txt
