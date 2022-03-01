#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
# run native space tsnr on initial
#  20200305WF  init
#  20211208WF also run for MHRest_nost_ica (maybe primary rest preproc?)
#             see snr/t2_tsnr.bash (20190524)

for f in /Volumes/Hera/preproc/7TBrainMech_{rest/MHRest_nost{,_ica}/1*_2*/,mgsencmem/MHTask_nost/1*_2*/*}/wdkm_func.nii.gz; do
   echo $f
   cd $(dirname $f)
   #ppf_tsnr -n -O _func.nii.gz -c || continue
   ppf_tsnr -O wdkm_func.nii.gz || continue
done
