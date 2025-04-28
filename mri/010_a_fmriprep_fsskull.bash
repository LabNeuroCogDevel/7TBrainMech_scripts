#!/usr/bin/env bash
#
# run fmriprep but with freesurfer skull strip
#
# 20250428WF - init
#


BIDS_ROOT=/Volumes/Hera/Projects/7TBrainMech/scripts/mri/BIDS/FST1
OUT_DIR="/Volumes/Hera/Projects/7TBrainMech/scripts/mri/fmriprep-25.0.0-FST1/"
get_sesnum(){
  local ld8="$1";shift
  # 20260112WF/DW - match top.mri.date for session
  # b/c sipfc or mp2rage might have been a different date
  mlr --csv --ho \
     filter "\$lunaid==${ld8/_*/}" \
     then filter "\${rest.date}==${ld8/*_/} || \${top.mri.date}=~\".*${ld8/*_/}.*\"" \
     then cut -f "visitno" ../txt/merged_7t.csv |
  sed 1q
}
test_getsesnum() { #@test
 local output
 run get_sesnum 10195_20180129
 [[ $output == 1 ]]
 run get_sesnum 10195_20191205
 [[ $output == 2 ]]
}


setup_subj_files(){
  # NOT USED -- want to pull out some of the giant function below. but too many shared variables?
  local subjroot=${1:?subj root. like bid/ses-y/sub-x}
  local vdate=${2:?session visit date YYYYMMDD}
  [[ $subjroot =~ ses-(\d)/sub-(\d) ]] && echo "ERROR: $subjroot is not like bids/ses-y/sub-x!" && return 1
  local ses=${BASH_REMATCH[1]}
  local id=${BASH_REMATCH[2]}

}

fmriprep_FS() {
  # given a lunaid_vdate: run fmriprep with FS
  local ld8=${1:?lunaid_8digitdate}
  ! [[ $ld8 =~ ([0-9]{5})_([0-9]{8}) ]] && echo "ERROR: '$ld8' not a valid lunaid_date!" && return 1
  local id=${BASH_REMATCH[1]}
  local vdate=${BASH_REMATCH[2]}

  test -d "$BIDS_ROOT" || dryrun mkdir -p "$BIDS_ROOT"
  ses="$(get_sesnum "$ld8")"
  [ -z "$ses" ] && echo "ERROR: no sesnum for $id $vdate (see grep $id.*$vdate ../txt/merged_7t.csv)" && return 1

  local bids_ses_root=$BIDS_ROOT/ses-$ses
  local ses_out_dir=$OUT_DIR/ses-$ses
  local subjroot=$bids_ses_root/sub-$id

  html_outfile=$ses_out_dir/sub-$id.html
  [ -r "$html_outfile" ] && echo "$id $vdate $ses: have $html_outfile! skipping" && return 0
  echo "# making $html_outfile"


  dryrun mkdir -p "$ses_out_dir" "$bids_ses_root/FS" "$subjroot"/{anat,func}/ 

  # UNICORT=/Volumes/Hera/Projects/corticalmyelin_development/BIDS
  # ln -s $UNICORT/sub-10129/ses-20180917/anat/sub-10129_ses-20180917_UNIT1.nii.gz input/FSisT1/ses-1/sub-10129/ 
  # get FS anat into BIDS
  FS="/Volumes/Hera/preproc/7TBrainMech_rest/FS7.4.1_long/sub-${id}_ses-$vdate"
  FS_brain="$FS/mri/brain.mgz"

  # 20250814: try FS7.2 if val's UNIDEN 7.4.1 doesn't exist
  if [ ! -r "$FS_brain" ]; then
     # search both highres lowres
     FS_brains=(/Volumes/Hera/preproc/7TBrainMech_rest/FS7.2/[hl]*/"${id}_$vdate/"/mri/brain.mgz)
     echo "WARNING: ${id}_$vdate: no FS7.4 MP2RAGE '$FS_brain'. Trying FS7.2 MPRAGE '${FS_brains[*]}'."
     [[ ${FS_brains[*]} =~ highres ]] && echo "WARNING!!: ${id}_$vdate: no 7.4.1 but have mp2rage in 7.2!? no $FS, have ${FS_brains[*]}; SKIPPING" && return 1
     FS_brain=${FS_brains[0]}
     FS="${FS_brain/mri\/brain.mgz/}"
  fi
  [ ! -r "$FS_brain" ] && echo "ERROR: ${id}_$vdate: missing $FS_brain" && return 1

  
  fs_as_bids="$subjroot/anat/sub-${id}_T1w.nii.gz"
  test -r "$fs_as_bids" || dryrun niinote "$fs_as_bids" \
     mri_convert "$FS_brain" "$fs_as_bids"
  
  # reuse FS in fmriprep
  dryrun ln -sf "$FS" "$bids_ses_root/FS/sub-${id}"
  
  # get rest into BIDS func
  for rest in "/Volumes/Hera/Raw/BIDS/7TBrainMech/sub-$id/$vdate/func/sub-${id}_task-rest_run-01_bold."*; do
     dryrun ln -sf "$rest" "$subjroot/func/$(basename "$rest")"
  done
  
  # get anat json from original (FS doesn't have json side car)
  json="/Volumes/Hera/Raw/BIDS/7TBrainMech/sub-$id/$vdate/anat/sub-${id}_T1w.json"
  [[ $FS =~ lowres ]] && json="/Volumes/Hera/Raw/BIDS/7TBrainMech/sub-$id/$vdate/anat/sub-${id}_acq-lowres_T1w.json"
  ! test -r "$json" && echo "ERROR: missing json file '$json'" && return 1
  dryrun ln -sf "$json" \
     "$subjroot/anat/sub-${id}_T1w.json"

  # run
  dryrun \
   docker run \
     --rm -v /Volumes:/Volumes \
     -v /opt/ni_tools/freesurfer/license.txt:/opt/ni_tools/freesurfer/license.txt \
     nipreps/fmriprep:25.0.0 \
     --skip-bids-validation \
     --fs-license-file /opt/ni_tools/freesurfer/license.txt  \
     --fs-subjects-dir "$bids_ses_root/FS/"  \
     --task-id rest \
     "$bids_ses_root" \
     "$ses_out_dir" participant \
     --participant-label $id \
     --ignore slicetiming \
     --cifti-output \
     --skull-strip-t1w skip
    return $?
}
010_a_fmriprep_fsskull_main(){
  export MAXJOBS=5
  for rest in /Volumes/Hera/Raw/BIDS/7TBrainMech/sub-*/*/anat; do
    [[ $rest =~ [0-9]{5}/[0-9]{8} ]] || continue
    ld8=${BASH_REMATCH[0]/\//_}
    #run_one "$ld8"
    fmriprep_FS "$ld8" &
    waitforjobs
  done
  wait
}

# if not sourced (testing), run as command
eval "$(iffmain "010_a_fmriprep_fsskull_main")"

####
# testing with bats. use like
#   bats ./010_a_fmriprep_fsskull.bash --verbose-run
####
##  add native space option
## TODO: remove bad nii but keep html
