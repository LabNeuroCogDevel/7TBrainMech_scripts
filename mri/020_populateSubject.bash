#!/usr/bin/env bash
set -e
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
# setup subject directories
#  subjs/<id>/
#     <tp>_<date>/
#        anat/
#           mprage.nii.gz
#           mprage_warp.nii.gz
#           template.nii.gz
#        rest/
#           nfswm_*.nii.gz
#           template.nii.gz
#        mgs/<runno>/
#           nfswm_*.nii.gz
#           template.nii.gz
