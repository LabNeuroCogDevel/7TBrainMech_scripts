#!/usr/bin/env bash
#
# get timeseries for each atlas/schaefer2018_17N_1000.nii.gz roi
#
# 20230613WF - init
#

mk1d_schaefer_main() {
  roi="atlas/schaefer2018_17N_1000.nii.gz"
  nroi=1000
  [ $# -eq 0 ] && warn "USAGE: $0 [all|/Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost/1*_2*/brnswdkm_func_4.nii.gz]" && exit 1

  mapfile -t FILES < <(args-or-all-glob '/Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost/1*_2*/brnswdkm_func_4.nii.gz' "$@")
  echo "# ${#FILES[@]} files"
  [ -d txt ] || mkdir txt
  for rest in "${FILES[@]}"; do
     ld8=$(ld8 "$rest")
     tsout="txt/${ld8}_schaefer2018N17_1000.1D"
     [ -z "$tsout" ] && continue
     echo "# $tsout"
     (dryrun 3dROIstats -nomeanout -1DRformat -quiet -numROI $nroi -nzmean -mask "$roi" "$rest" | drytee "$tsout") &
     waitforjobs -j 32 -s 15
   done
}

# if not sourced (testing), run as command
eval "$(iffmain "mk1d_schaefer_main")"

####
# testing with bats. use like
#   bats ./mk1d_schaefer.bash --verbose-run
####
mk1d_schaefer_main_test() { #@test
   local output
   run mk1d_schaefer_main
   [[ "$output" =~ .* ]]
}
