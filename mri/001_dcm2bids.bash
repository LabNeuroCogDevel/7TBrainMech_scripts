#!/usr/bin/env bash
set -e
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
# 1) link 10000s of dcms into protocol folders
# 2) run dcm2nii on protcols we have identified (020_mkBIDS.R)
#

cd /Volumes/Hera/Raw/BIDS/7TBrainMech/ 
./010_gen_raw_links.bash all 
./020_mkBIDS.R
