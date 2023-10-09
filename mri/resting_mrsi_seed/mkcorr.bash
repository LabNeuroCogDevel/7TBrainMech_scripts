#!/usr/bin/env bash
#
# generate timeseries for a subject @ seed roi num
# use 3dTcorr1D to generate a corr map for each given seed (argument -roi)
#
# 20221010WF - init
#

get_blob(){
   local roimask=blob-mni
   # use picked coords to find which picker (e.g AG) directory matches the used LCmodel output
   # we're using "blob". the nonlin warp-to-mni of coord placed in t1 space 
   # might want to use cmsphere instead, but blob is probably truer to cordinate placement
  local ld8="$1"; shift
  [ $# -gt 0 ] && roimask="$1"; shift
  # shellcheck disable=SC2086 # want to expand if given a glob
  readlink /Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/MRSI_roi/LCModel/v2idxfix/13MP20200207_picked_coords.txt|
     perl -pe "s:[^/]*?$:$roimask.nii.gz:"
}
get_rest(){
   local ld8="$1"; shift
   # rest could be  brnaswdkm (no global signal)
   echo /Volumes/Hera/Projects/7TBrainMech/subjs/"$ld8"/preproc/rest/bgrnaswdkm_func_4.nii.gz
}

roimask-blob(){
   local ld8="$1"; shift
   local roi_num="$1"; shift
   f=$(get_blob "$ld8")
   [ ! -r "$f" ] && warn "ERROR: no roi blob '$f'" && return 1
   echo "$f<$roi_num>"
}

roimask-grp-sphere(){
   local ld8="$1"; shift
   local roi_num="$1"; shift
   f=$(find roi-cnt -iname "$(printf "%02d" "$roi_num")-*-0.5_mxsph-9.nii.gz" -print -quit)
   [ ! -r "$f" -o -z "$f" ] && warn "ERROR: no roi blob '$f' for $roi_num ($ld8)" && return 1
   echo "$f"
}

mkts(){
   local ld8="$1"; shift
   local mask="$1"; shift
   local outname="$1"; shift
   # TODO: should use mni gm mask?
   rest=$(get_rest "$ld8")
   [ ! -r "$rest" ] && warn "ERROR: no rest '$rest'" && return 1
   out=/Volumes/Hera/Projects/7TBrainMech/subjs/"$ld8"/conn_mrsi_rest/$outname
   ! test -d "$(dirname "$out")" && dryrun mkdir -p "$_"

   # might want to ignore this if we need to redo (e.g. added mni gm mask)
   ! test -r "$out" &&
     dryrun 3dmaskave -quiet -mask "$mask" "$rest" | drytee "$out"
   echo "$out"
}

gld8(){ grep -Po '\d{5}_\d{8}' |sort -u; }

ld8_mrsi_rest(){
   # has both pfc mrsi and rest
   sdir=/Volumes/Hera/Projects/7TBrainMech/subjs
   comm -12 \
    <(ls $sdir/1*_2*/slice_PFC/MRSI_roi/LCModel/v2idxfix/13MP20200207_picked_coords.txt | gld8) \
    <(ls $sdir/1*_2*/preproc/rest/bgrnaswdkm_func_4.nii.gz | gld8)
}

make_corr(){
  local ld8="$1"; shift
  local roi="$1"; shift
  # 20221012
  # earlier used roimask-blob and out to blob/ instead of mxcovsph
  mask=$(roimask-grp-sphere "$ld8" "$roi")
  [ ! -r "$mask" ] && warn "# no mask '$mask' for $roi $ld8" && return 1
  outname=$(basename "$mask" .nii.gz)
  roi_name=${outname/[<_]*/}
  roits=$(mkts "$ld8" "$mask" "mxcovsph/$roi_name.1d")
  test ! -r "$roits"  && warn "ERROR: failed to make '$_'" && return 1
  corr_out=$(dirname "$roits")/${roi_name}_deconreml-r.nii.gz
  test -r "$corr_out" && warn "# skip '$_'. already have" && return 1

  # 20221014 - using decon + reml (via 3dSeedCorr)  instead of 3dTcorr1D
  # prev had:
  #corr_out=$(dirname "$roits")/${roi_name}_corr-r.nii.gz
  #dryrun 3dTcorr1D -prefix "$corr_out" "$(get_rest "$ld8")" "$roits"

  ts=$(get_rest "$ld8")
  censor=$(dirname "$ts")/motion_info/censor_custom_fd_0.3_dvars_Inf.1d
  [ ! -r "$censor" ] && warn "missing censor '$censor'" && return 1
  dryrun 3dSeedCorr -jobs 32 -reml -prefix "$corr_out" -ts "$ts" -seed "$roits" -cen "$censor"
}

usage(){ echo "USAGE: $0 [-roi 2] {all|ld8 ld8 ld8}"; }
# if not sourced (testing), run as command
if ! [[ "$(caller)" != "0 "* ]]; then
  [ $# -eq 0 ] && usage >&2 && exit 1
  set -euo pipefail
  trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error $e"' EXIT

  # TODO: which ROIs to use? (by default at least)
  ROIS=(7 8 9 10)
  SUBJS=()
  while [ $# -gt 0 ]; do
    case "$1" in
       -h|help) usage; exit;;
       all) mapfile -t SUBJS < <(ld8_mrsi_rest); shift 1;;
       -roi) ROIS=("$2") ;shift 2 ;;
       1*_2*) SUBJS+=("$1"); shift;;
       *) warn "ERROR: uknown input '$1'"; exit 1;;
    esac
   done

   # for every subject and roi
   # generate timeseries
   for ld8 in "${SUBJS[@]}"; do
     for roi in "${ROIS[@]}"; do
        make_corr "$ld8" "$roi" || continue
     done
   done

  exit $?
fi

####
# testing with bats. use like
#   bats ./mkseed.bash --verbose-run
####
function init_test { #@test 
   [ 0 -eq 1 ]
}
