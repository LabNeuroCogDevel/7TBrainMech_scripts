#!/usr/bin/env bash
#
# resting state connectivity with rois by coverage
# step 1. generate coverage maps per roi
#
# 20220505WF - init
#
[ -v DRYRUN ] && DRYRUN=echo || DRYRUN=
warn(){ echo "$@" >&2; }


get_coverage_files(){
  for f in /Volumes/Hera/Projects/7TBrainMech/subjs/1*_2*/slice_PFC/MRSI_roi/LCModel/v2idxfix/13MP20200207_picked_coords.txt; do
    ls "$(dirname "$(readlink -f "$f")")"/cmsphere-mni.nii.gz
  done
  # TODO: remove subjs that are excluded
}

unique_visit_only(){
  perl -lne 'print "$& $_" if m/\d{5}_\d{8}/'|uniq -w14|cut -f2 -d' '
}

collapse_coverage(){
  local roi="$1"; shift
  # rest are input filenames
  # combine them all as one nifti image (bucket 4d)
  local out=coverage/roi/$roi/coverage_ratio.nii.gz 
  mkdir -p $(dirname $out)
  3dTcat -overwrite -prefix "$out" "$@"
  # remove ROI number so sum is count
  3dcalc -overwrite -a "$out" -expr 'step(a)' -prefix "$out"
  3dTstat -overwrite -prefix "$out" -nzcount "$out"
  # divide by total
  3dcalc -overwrite -a "$out" -expr "a/$#" -prefix "$out"
}

add_roi_selector(){ roi=$1; shift; find "$@"  -maxdepth 0 | sed "s/$/<$roi>/"; }
read_rois(){ perl -lne 's/:.*//;s/ +/_/g;print(sprintf "%02d_%s", $., $_)'< roi_locations/labels_13MP20200207.txt; }

_all_coverage_perroi() {
  echo "# finding all coverage files"
  mapfile -t inputs < <(get_coverage_files | unique_visit_only)
  mapfile -t rois < <(read_rois)
  echo "# making rois"
  for roi in "${rois[@]}"; do
     echo "# $roi"
     $DRYRUN collapse_coverage "$roi" $(add_roi_selector "${roi/_*/}" "${inputs[@]}")
  done
  return 0
}

# if not sourced (testing), run as command
if ! [[ "$(caller)" != "0 "* ]]; then
  set -euo pipefail
  trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error $e"' EXIT
  _all_coverage_perroi "$@"
  exit $?
fi

####
# testing with bats. use like
#   bats ./all_coverage_perroi.bash --verbose-run
####
if  [[ "$(caller)" =~ /bats.*/preprocessing.bash ]]; then
function uniq_visits_test { #@test 
   mapfile -t res < <(echo -e 'a/b/12345_20101231/x\na/b/12345_20101231/y\na/b/55555_99999999/y' | unique_visit_only)
   [ ${#res[@]} -eq 2 ]
   [[ ${res[0]} == a/b/12345_20101231/x ]]
   [[ ${res[1]} == a/b/55555_99999999/y ]]
}
function readroi_test { #@test 
   mapfile -t rois < <(read_rois)
   echo -e "${#rois[@]}\n${rois[0]}" >&2
   [ ${#rois[@]} -eq 13 ]
   [ "${rois[0]}" == "01_R_Anterior_Insula" ]
   [ "${rois[12]}" == "13_R_Thalamus" ]
}
fi


