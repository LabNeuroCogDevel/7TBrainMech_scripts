#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
# warp yesMT/noMT both to T1. calc MTR
#
# 20191121WF - copied from /Volumes/Phillips/mMR_PETDA/scripts/MT/04_warpMTs+pdiff.bash

align() {
  infix=$(basename $1 +orig.)

  final=${infix}al.nii.gz
  [ -r $final ] && return 0

  dset1=$1;shift
  dset2=$1;shift
  suffix=$1;shift

  align_epi_anat.py \
   -dset1 $dset1 -dset2 $dset2 \
   -dset2_strip None \
   -suffix $suffix \
   -overwrite \
   $@ \
   -rigid_body  \

   #-cost lpc+ZZ 

  out=${infix}${suffix}+orig.HEAD
  3dcopy $out ${final}
  shot $final
}
calcmtr() {
  # argument list 
  for arg in MT noMT anat prefix; do
     [ -z "$1" ] && warn "$FUNCNAME needs 4 inputs: $arg is empty" && return 1
     printf -v $arg $1
     shift

     if [ $arg != "prefix" ] && [ ! -r ${!arg} -a ! -r ${!arg}.HEAD ];then
        warn "$arg ('${!arg}' @ $(pwd)) DNE!"
        return 1
     fi
  done
  [ -r $prefix -o -r $prefix.HEAD ] && return 0

  3dcalc -overwrite \
      -prefix __MTR_epidim.nii.gz \
      -m $MT \
      -n $noMT \
      -expr '1-m/n'

  3dresample -inset __MTR_epidim.nii.gz -master $anat -prefix __MTR_anatdim.nii.gz -overwrite 

  3dcalc -prefix $prefix \
      -m __MTR_anatdim.nii.gz \
      -a $anat \
      -exp 'm*bool(a)' 

  #cleanup
  rm __MTR_anatdim.nii.gz __MTR_epidim.nii.gz
}

# look to /Volumes/Hera/Projects/7TBrainMech/scripts/mri/BIDS/bids_folder/*/mt/*

align MT1+orig. anat+orig. _al2anat1 -giant_move  
align MT2+orig. MT1_al2anat1+orig. _al2M1anat -giant_move  
convert img/MT[12]al.png img/noMT[12]al.png img/all.gif
calcmtr MT1al.nii.gz noMT1al.nii.gz anat+orig MTR1.nii.gz
