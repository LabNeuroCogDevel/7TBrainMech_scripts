#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error $e"' EXIT

#
# warp yesMT/noMT both to T1. calc MTR
#
# 20191121WF - copied from /Volumes/Phillips/mMR_PETDA/scripts/MT/04_warpMTs+pdiff.bash
# 20220221WF - revisit. put into 7T subject folder

shot(){
 f=$1
 [ -z "$f" -o ! -r "$f" ] && warn "shots given bad input file" && return 1
 [ ! -d img ] && mkdir img
 output=img/$(basename $f .nii.gz).png
 [ -r $output ] && return 0

 slicer $f -a >( convert - -background white label:$(basename $f .nii.gz) -gravity center -append $output)
}
align() {
  infix=$(basename "$1" +orig.)

  final=${infix}al.nii.gz
  [ -r "$final" ] && return 0

  dset1=$1;shift
  dset2=$1;shift
  suffix=$1;shift

  align_epi_anat.py \
   -dset1 "$dset1" -dset2 "$dset2" \
   -dset2_strip None \
   -suffix "$suffix" \
   -overwrite \
   "$@" \
   -rigid_body  \

   #-cost lpc+ZZ 

  out=${infix}${suffix}+orig.HEAD
  3dcopy "$out" "${final}"
  shot "$final"
}
calcmtr() {
  local MT noMT anat prefix
  # argument list 
  for arg in MT noMT anat prefix; do
     [ -z "$1" ] && warn "${FUNCNAME[0]} needs 4 inputs: $arg is empty" && return 1
     printf -v $arg "$1"
     shift

     if [ $arg != "prefix" ] && [ ! -r ${!arg} ] && [ ! -r ${!arg}.HEAD ];then
        warn "$arg ('${!arg}' @ $(pwd)) DNE!"
        return 1
     fi
  done
  [ -r "$prefix" -o -r "$prefix.HEAD" ] && return 0

  3dcalc -overwrite \
      -prefix __MTR_epidim.nii.gz \
      -m "$MT" \
      -n "$noMT" \
      -expr '1-m/n'

  3dresample -inset __MTR_epidim.nii.gz -master "$anat" -prefix __MTR_anatdim.nii.gz -overwrite 

  3dcalc -prefix "$prefix" \
      -m __MTR_anatdim.nii.gz \
      -a "$anat" \
      -exp 'm*bool(a)' 

  #cleanup
  rm __MTR_anatdim.nii.gz __MTR_epidim.nii.gz
}

_mtr(){
  [ $# -ne 3 ] && echo "ERROR: _mtr needs yes.nii.gz no.nii.gz anat.nii.gz" >&2 && return 1
  yes="$1"; shift
  no="$1"; shift
  anat="$1"; shift
  for f in $yes $no $anat; do
     [ ! -r "$f" ] && echo "$f DNE" >&2 && return 1
  done

  # using afni +orig b/c lazy. "align" function expects "+orig." names
  3dcopy "$yes" MT1+orig.
  3dcopy "$no" MT2+orig.
  test ! -r $(basename "$anat") && ln -s "$anat" $_

  align MT1+orig. "$anat" _al2anat1 -giant_move  
  align MT2+orig. MT1_al2anat1+orig. _al2M1anat -giant_move  
  convert img/MT[12]al.png img/noMT[12]al.png img/all.gif
  calcmtr MT1al.nii.gz noMT1al.nii.gz anat+orig MTR1.nii.gz
}
bids_id() { perl -plne 's/.*?sub-//; s/_.*//;s:/:_:g' <<< "$@";}

# bids session folder with 'mt' folder
if [[ "$(caller)" =~ ^0\ * ]]; then
   [ $# -ne 1 ] && echo "USAGE: $0 bid_subj_dir" && exit 1

   # want absolute path that exists and has mt directory
   subdir="$1"; shift
   test ! -d "$subdir/mt"  && echo "$_ must exist" >&2 && exit 1
   subdir="$(cd "$subdir"; pwd)"

   # put into 7T 'subjs' folder as sibling to e.g tat2, slicePFC
   test -d "/Volumes/Hera/Projects/7TBrainMech/subjs/$(bids_id "$subdir")/mt" ||
      mkdir -p "$_"
   cd "$_"

   # run
   _mtr "$subdir"/mt/*_MT_acq-yes.nii.gz "$subdir"/mt/*_MT_acq-no.nii.gz  "$subdir"/anat/*_T1w.nii.gz
fi
