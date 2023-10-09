#!/usr/bin/env bash
#
# create coord placement mask and extract all FS labels from it
#
# 20230201WF - init
#

IDV_R_LABEL="/Volumes/Hera/Projects/7TBrainMech/scripts/mri/Hc/fs_label_idv.R"


undump_and_label(){
  hcdir="$1";
  cd "$hcdir" || return 1
  test -r hc_aseg_roirat.csv -a -r hc_HBT_roirat.csv -a -r hc_gm_rat.csv && return 0
  ! test -r hc_loc_unrotated.1d && echo "ERROR: missing '$hcdir/$_'!" && return 1
  ! test -r FS_warp/*_aseg_scout.nii.gz && echo "ERROR: missing '$hcdir/$_'!" && return 1
  ! test -r FS_warp/*_HBTlr500_scout.nii.gz  &&
     echo "ERROR: missing '$hcdir/$_' see ./01.2.2_FS72_roimasks.bash spectrum/$(basename "$hcdir")" &&
     return 1
  nk=$(3dinfo -nk FS_warp/*_aseg_scout.nii.gz)
  awk  -v nk="$nk" '{print $2,216-$1,nk/2,$5}' hc_loc_unrotated.1d | drytee hc_loc_ijk_afni.1d
  dryrun 3dUndump -overwrite \
     -prefix placements.nii.gz \
     -master FS_warp/*_aseg_scout.nii.gz \
     -cubes -ijk -srad 4 \
     hc_loc_ijk_afni.1d
  # hc_aseg_roirat_highest.csv and hc_aseg_roirat.csv
  dryrun $IDV_R_LABEL aseg
  # hc_gm_rat.csv
  dryrun $IDV_R_LABEL gm
  # hc_HBT_roirat_highest.csv
  dryrun $IDV_R_LABEL hbt
}

04_fslabels_main() {
  [ $# -eq 0 ] && echo "USAGE: $0 [all|spectrum/20180216Luna2]" && exit 1
  case "$1" in 
     reoreint)
        dryrun ./view_placements.jl # takes a while to run, makes hc_loc_unrotated.1d
        FILES=("$(pwd)/spectrum"/2*/);;
     all) FILES=("$(pwd)/spectrum"/2*/);;
     *) FILES=("$@")
  esac
  for hcdir in "${FILES[@]}"; do
     undump_and_label "$hcdir" || :
  done
  return 0
}

# if not sourced (testing), run as command
eval "$(iffmain "04_fslabels_main")"

####
# testing with bats. use like
#   bats ./04_fslabels.bash --verbose-run
####
04_fslabels_main_test() { #@test
   local output
   run 04_fslabels_main
   [[ $output =~ ".*" ]]
}
