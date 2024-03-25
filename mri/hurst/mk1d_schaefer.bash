#!/usr/bin/env bash
#
# get timeseries for each atlas/schaefer2018_17N_1000.nii.gz roi
#
# 20230613WF - init
# 20240226WF - allow for alternative atlas file using $ROI global. rename func w/o _schaefer_
#              AO's /Volumes/Hera/Amar/atlas/hurst_rois/nacc_amyg_hpc.nii.gz
#              in Makefile as
#              ROI=atlas/nacc_amyg_hpc.nii.gz NROI=6 ./mk1d_schaefer.bash all

mk1d_main() {
  # default to schaefer2018_17N_1000 -- with 1000 rois
  # alt: ROI=atlas/nacc_amyg_hpc.nii.gz NROI=6 see Makefile
  roi=${ROI:-atlas/schaefer2018_17N_1000.nii.gz}
  nroi=${NROI:-1000}
  # original output didn't exactly match nifti atlas name. no _ between year and network number
  outname=$(basename "${roi/2018_17N/2018N17}" .nii.gz).1D #tsout="txt/${ld8}_schaefer2018N17_1000.1D"
  [ $# -eq 0 ] && warn "USAGE: $0 [all|/Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost/1*_2*/brnswdkm_func_4.nii.gz]" && exit 1

  mapfile -t FILES < <(args-or-all-glob '/Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost/1*_2*/brnswdkm_func_4.nii.gz' "$@")
  echo "# ${#FILES[@]} files"
  [ -d txt ] || mkdir txt
  for rest in "${FILES[@]}"; do
     ld8=$(ld8 "$rest")
     tsout="txt/${ld8}_$outname"
     [ -z "$tsout" ] && continue
     echo "# $tsout"
     (dryrun 3dROIstats -nomeanout -1DRformat -quiet -numROI "$nroi" -nzmean -mask "$roi" "$rest" | drytee "$tsout") &
     waitforjobs -j 32 -s 15
   done
}

# if not sourced (testing), run as command
eval "$(iffmain "mk1d_main")"

####
# testing with bats. use like
#   bats ./mk1d_schaefer.bash --verbose-run
####
mk1d_schaefer_main_test() { #@test
   local output
   run mk1d_main
   [[ "$output" =~ .* ]]
}
