#!/usr/bin/env bash


#
# find slice per subject
#  - no arguments, run for everyone
#  - subject_date as arguments, run for just those
#
# 1. constructs pfc slice (66dicoms, 33 slices)
# 2. get mat for slice <-> mprage  linear warp
# 3. bring slice roi atlas into mprage and slice space (nonlinear)
# depends on preprocessFunctional having been already run

# run as lncd
[ "$(whoami)" != "lncd" ] && echo "run as lncd: sudo su -l lncd $(readlink -f $0) $@" && exit 1
! command -v flirt >/dev/null && echo no fsl, export path && exit 1

# setup sane bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
cd $(dirname $0)


# where are things
subjdir="/Volumes/Hera/Projects/7TBrainMech/subjs"
t1root="/Volumes/Hera/Projects/7TBrainMech/pipelines/MHT1_2mm"
mni_atlas="/Volumes/Hera/Projects/7TBrainMech/slice_rois_mni_extent.nii.gz"
#N.B. need to resample atlas w/ 2mm template so extent matched. bad warp otherwise


# can take a luna_date or directory. if given nothing find all directories
[ $# -gt 0 ] && list=($@) || list=( /Volumes/Hera/Raw/BIDS/7TBrainMech/rawlinks/1*_2*/) 

for sraw in ${list[@]}; do
   # maybe we gave a lunaid_date instead of a directoyr?
   [ ! -d $sraw ] && sraw=/Volumes/Hera/Raw/BIDS/7TBrainMech/rawlinks/$sraw
   [ ! -d $sraw ] && echo "# bad input: no directory like $sraw" >&2 && continue

   # is this a luna_date
   ! [[ $(basename $sraw) =~ [0-9]{5}_[0-9]{8} ]] && echo "# no lunadate in '$sraw'" >&2 && continue
   ld8=$BASH_REMATCH

   # do we have a single scout to work with
   n=$( (ls -d $sraw/*_66 ||echo -n) |wc -l ) 
   [ $n -ne 2 ] && echo "# $ld8: bad slice raw dir num ($n $sraw/*66*)" >&2 && continue
   slice_dcm_dir=$(ls -d $sraw/*_66 |sed 1q)

   # is preprocess mprage done?
   mprage=$t1root/$ld8/mprage.nii.gz
   [ ! -r $mprage ] && echo "# $ld8: no t1. run: 'pp 7TBrainMech MHT1_2mm $ld8' (missing $mprage)" >&2 && continue
   wcoef=$t1root/$ld8/template_to_subject_warpcoef.nii.gz 
   [ ! -r $wcoef ] && echo "# $ld8: no warp coef. rerun 'pp 7TBrainMech MHT1_2mm $ld8' (missing $wcoef)" >&2 && continue

   ## reconstruct slice dicom
   this_dir="$subjdir/$ld8/slice_PFC"
   echo "# $ld8 $slice_dcm_dir to $this_dir"

   # make slice directory if we need to
   [ ! -d $this_dir ] && mkdir -p $this_dir
   cd $this_dir

   # create nifti if we need to
   #[ $(find . -maxdepth 1 -type f  -iname '*.nii.gz' |wc -l ) -gt 0 ] || dcm2niix_afni -o ./ -f slice_pfc $slice_dcm_dir
   cmd="dcm2niix_afni -o ./ -f slice_pfc $slice_dcm_dir"
   [ ! -r slice_pfc.nii.gz ] && eval $cmd && 3dNotes -h "$cmd" slice_pfc.nii.gz
   [ ! -r slice_pfc.nii.gz ] && echo "$ld8: 'dcm2niix $slice_dcm_dir' failed!" >&2 && continue

   ## flirt
   # get preproces mprage eaily accesible (mprage and warpcoef)
   [ ! -d ppt1 ] && ln -s $t1root/$ld8/ ppt1
   # todo: consider
   #[ ! -r slice_pfc_native.nii.gz -o ! -r slice_pfc_to_native.mat ] && 

   [ ! -r mprage_in_slice.nii.gz -o ! -r mprage_to_slice.mat ] && 
     flirt -ref slice_pfc.nii.gz -in ppt1/mprage.nii.gz -o mprage_in_slice.nii.gz -omat mprage_to_slice.mat ||
        echo "# $ld8: have $(pwd)/slice_pfc_native.nii.gz" >&2

   # 3dcalc -a slice_pfc.nii.gz -expr 'equals(k,17) * a' -prefix spfc_17.nii.gz -overwrite
   # provide roi in mprage and slice space. former to check if latter is bad
   if [ ! -r roi_slice.nii.gz ]; then
      applywarp -i $mni_atlas -o roi_mprage.nii.gz -r ppt1/mprage.nii.gz     -w ppt1/template_to_subject_warpcoef.nii.gz --interp=nn
      applywarp -i $mni_atlas -o roi_slice.nii.gz  -r slice_pfc.nii.gz  -w ppt1/template_to_subject_warpcoef.nii.gz --postmat=mprage_to_slice.mat --interp=nn
   fi

done

