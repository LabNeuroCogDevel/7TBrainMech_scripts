#!/usr/bin/env bash
set -e
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
# visually inspect rois
#
# look at files in e.g
# /Volumes/Hera/Projects/7TBrainMech/subjs/11323_20180316/slice_PFC/MRSI_roi/raw/


[ -v DRYRUN ] && DRYRUN=echo || DRYRUN=

[ $# -ne 1 ] && cat <<HERE && exit 1
USAGE:
  $0 luna_date
EXAMPLES:
  $0 11323_20180316
  $0 list           # show all w/raw directories

SEE ALSO:
  ./needs_placement.bash   # show's only what's not been placed

HERE

if [ "$1" == "list" ]; then
   ls -d /Volumes/Hera/Projects/7TBrainMech/subjs/*/slice_PFC/MRSI_roi/raw | perl -pe 's/.*(\d{5}_\d{8}).*/$1/'
   exit 0
fi
ld8="$1"

# use afni_pick if it exsts
afnicmd=afni
command -v afni_picker >/dev/null && afnicmd=$_

$DRYRUN $afnicmd \
   -com "SWITCH_UNDERLAY mprage_in_slice.nii.gz" \
   -com "SET_FUNCTION slice_pfc.nii.gz" \
   -com 'OPEN_WINDOW A.sagittalimage keypress=$' `# split over and underlay with slicer` \
   -com 'SEE_OVERLAY -' \
   -dset \
   /Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/{mprage_in_slice.nii.gz,slice_pfc.nii.gz} \
   /Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/ppt1/mprage_warp_linear.nii.gz \
   /opt/ni_tools/standard/mni_icbm152_nlin_asym_09c/mni_icbm152_t1_tal_nlin_asym_09c.nii \
   /Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/MRSI/parc_group/rorig.nii \
   /Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/ppt1/mprage_bet.nii.gz \
   /Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/MRSI_roi/raw/csi_rois_slice_$ld8*.nii.gz \
   /Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI_roi/csi_rois_mni_MPRO_20190425.nii.gz \
   /Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/ppt1/mprage.nii.gz

