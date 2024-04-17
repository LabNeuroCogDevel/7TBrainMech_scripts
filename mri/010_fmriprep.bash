#!/usr/bin/env bash
#
# 20221114WF - init
# 20221118WF - session id, lowacq
# run fmriprep for 7T
#
# avoid longitudinal pipeline
#  1) FS into subject only sub folder
#  2) bids filter file to limit to single session
#  3) use session as timepoint instead of visitdate for outputs
#
# Notes:
#  dryrun and drytee are noop (echo only) if DRYRUN=1
#  for additional processsing see preprocessFunctional
#    -4d fmrirep_out.nii.gz -no_mc -no_st -no_warp -hp_filter 40 -rescaling_method 10000_globalmedian
# TODO:
#  * test bids filter with '*'. otherwise 'lowres' if [[ $origfs =~ lowres ]]
#  * use working directory switch in docker/frmirep for easy restart
set -euo pipefail
set -x
cd "$(dirname "$0")" || exit 1

# 
FSlic=/opt/ni_tools/freesurfer/license.txt

# use ses-1 to ses-3 so we can group sessions together
# initially using visit date instead of timepoint: ses-yyyymmdd 
get_sesnum(){
  local ld8="$1";shift
  find "/Volumes/Hera/Raw/BIDS/7TBrainMech/sub-${ld8/_*}/"2*/func/*rest_run-01_bold.nii.gz |
     perl -salne 'BEGIN{$ld8=~s/_/./} print $. if m:$ld8:' -- -ld8="$ld8"
}

#ld8=11681_20200731 # no physio

fmriprep_one(){
  local ld8="$1"
  id=sub-${ld8/_*}
  vdate=${ld8/*_}
  
  ## find session
  ses_num=$(get_sesnum "$ld8")
  PREPOUT=$(pwd)/fmriprep/ses-$ses_num/ # like ses-1 not ses-20191231

  # /Volumes/Hera/Projects/7TBrainMech/scripts/mri/fmriprep/ses-1/sub-11821/ses-20210521/func/sub-11821_ses-20210521_task-rest_run-1_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz
  final_out="$PREPOUT/$id/func/${id}_task-rest_run-01_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz"
 test -r "$final_out"  && echo "have $_" && return 0
 echo "# making $final_out"

  dryrun mkdir -p "$PREPOUT/filters"
  
  ## FS with same id as BIDS input (no session)
  # some only have lowres T1
  FS=$PREPOUT/FS/
  # /Volumes/Hera/preproc/7TBrainMech_rest/FS7.4.1_long/sub-11716_ses-2022111
  origfs="/Volumes/Hera/preproc/7TBrainMech_rest/FS7.4.1_long/${id}_ses-$vdate"
  [ ! -d "$origfs" ] && origfs="/Volumes/Hera/preproc/7TBrainMech_rest/FS_lowres/$ld8"
  [ ! -d "$origfs" ] && warn "$ld8 has no FS? last checked '$origfs'" &&
     return 1

  dryrun mkdir -p "$FS"
  ! test -r "$FS/$id" && dryrun ln -s "$origfs" "$_"
  
  # filter file stops us from running all sessions
  # alternative is to link in just the single session like we do for FS
  # NB. not sure if "*" will work. or what happens when there is _acq-lowres and the normal MP2Rage
  filter=$PREPOUT/filters/$ld8.json
  bids-filter "$vdate" "*" rest | drytee "$filter"

  func_dir=/Volumes/Hera/Raw/BIDS/7TBrainMech/$id/$vdate/func
  #/Volumes/Hera/Projects/corticalmyelin_development/BIDS/sub-11945/ses-20230721/anat/sub-11945_ses-20230721_UNIT1.nii.gz
  ! [ -r "$func_dir" ] && 
     warn "no func dir '$func_dir'" && return 1
  uniden=/Volumes/Hera/Projects/corticalmyelin_development/BIDS/$id/ses-$vdate/anat/${id}_ses-${vdate}_UNIT1.nii.gz
  ! [ -r "$uniden" ] && 
     warn "no uniden '$uniden'" && return 1

  SINGLEBIDS="$PREPOUT/BIDS/$ld8"
  dryrun mkdir -p  "$SINGLEBIDS/$id/anat"
  test -e "$SINGLEBIDS/dataset_description.json" ||
     echo '{"Name": "Example dataset", "BIDSVersion": "1.0.2"}' |drytee "$_"

  test -e "$SINGLEBIDS/$id/anat/${id}_T1w.nii.gz" ||
     dryrun ln -s "$uniden" "$_"
  test -e "$SINGLEBIDS/$id/anat/${id}_T1w.json" ||
     dryrun ln -s "${uniden/.nii.gz/.json}" "$_"
  test -e "$SINGLEBIDS/$id/func" ||
     dryrun ln -s "/Volumes/Hera/Raw/BIDS/7TBrainMech/$id/$vdate/func"  "$_"
  
  
  # use DRYRUN=1 so just see
  dryrun docker \
     run \
     --rm \
     -v /Volumes:/Volumes  \
     -v "$FSlic:$FSlic" \
     nipreps/fmriprep:23.2.1 \
      --skip_bids_validation \
      `#--bids-filter-file "$filter"` \
      --fs-license-file "$FSlic" \
      --fs-subjects-dir "$FS" \
      --task-id "rest" \
      "$SINGLEBIDS" "$PREPOUT" participant \
      --participant-label "${ld8/_*/}" \
      --ignore slicetiming  \
      --skip-bids-validation \
      --cifti-output
}
usage(){ echo -e "USAGE:\n  $0 [all|ld8 ld8 ...]\n  DRYRUN=1 $0 all"; }
fmriprep_main(){
   #ld8=11821_20210521
   [[ $# -eq 0 || "$*" =~ ^--?h ]] && usage && exit
   [[ "${1:-}" == "all" ]] &&
      mapfile -t all_id < <(find /Volumes/Hera/preproc/7TBrainMech_rest/FS7.4.1_long/sub-1*_ses-2*[0-9] -maxdepth 0 -type d |sed '/long\.sub/d;s:.*/::;s/sub-\|ses-//g') ||
      all_id=("$@")

   for ld8 in "${all_id[@]}"; do
      fmriprep_one "$ld8" &
      waitforjobs
   done
   wait
}

eval "$(iffmain fmriprep_main)"
