#!/usr/bin/env bash
#
# make timeseries from MRSI roi. used by hurst.m
# also see
# /Volumes/Hera/Projects/Maria/7Trest_mrsi/02_makeTS_roi.sh

#   for f in /Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_nowarp/1*_2*/bgrnsdkm_func_4.nii.gz; do
#   using no-warp rest preproc. w/ Hc and ACC seeded
#
# 20230508WF - init
#


find_mrsi_roi(){
   local rest="$1"; shift
   restdir=$(dirname "$rest")
   mrsi_roi="$restdir/mrsipfcMP13_func.nii.gz"
   if test -r "$mrsi_roi"; then 
      echo "$mrsi_roi"
      verb "# have $mrsi_roi; reusing"
      return 0
   fi

   ld8=$(ld8 "$rest") # 10129_20180917
   roi_dir="/Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/MRSI_roi/13MP20200207"
   # shellcheck disable=SC2012,SC2010 # ls to sort rather than find+stat+sort
   roi="$(ls -t "$roi_dir"/*/coords_mprage.nii.gz|grep -v WF|sed 1q)"
   ! test -r "$roi" && warn "# $ld8: no $roi_dir/*/coords_mprage.nii.gz" && return 2
   # using mprage as common space. could warp epi->scout 
   # use other preproc to get warp to mprage
   to_func="${restdir/MHRest_nost_nowarp/MHRest_nost_ica}"/transforms/struct_to_func.mat

   niinote "$mrsi_roi" \
      flirt \
      -interp nearestneighbour \
      -in "$roi" \
      `#-ref "$restdir/mc_target.nii.gz"` \
      `#-ref "$rest"` \
      -ref "${rest/func_4.nii.gz/mean_func_4.nii.gz}" \
      -applyxfm -init "$to_func"\
      -out "$mrsi_roi" >&2

   # for checking the warp
   #anat2func="$restdir/anat_to_func.nii.gz"
   #mprage=${restdir//MHRest_nost_nowarp/MHRest_nost_ica}/mprage_bet.nii.gz
   #niinote "$anat2func" \
   #   flirt \
   #   -interp nearestneighbour \
   #   -in "$mprage" \
   #   -ref "$restdir/mc_target.nii.gz" \
   #   -applyxfm -init "$to_func"\
   #   -out "$anat2func" >&2

   test -r "$mrsi_roi" && echo "$mrsi_roi" || return 2
}

mkTS_roi_main() {
   export AFNI_NO_OBLIQUE_WARNING=YES

  rest_glob='/Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_nowarp/*/brnsdkm_func_4.nii.gz'
  [ $# -eq 0 ] && echo "USAGE: $0 ['all'|$rest_glob]" && exit 22
  mapfile -t FILES < <(args-or-all-glob "$rest_glob" "$@")
   
  for rest in "${FILES[@]}"; do
     tsout="$(dirname "$rest")"/mrsipfc13_nzmean_ts.1D
     test -r "$tsout" && verb "# have $tsout; skipping" && continue
     echo "# $rest"
     roi=$(find_mrsi_roi "$rest" || echo -n)
     ! test -n "$roi" -a -r "$roi" && continue
     verb "# writting $tsout"
     3dROIstats -nomeanout -1DRformat -quiet -numROI 13 -nzmean -mask "$roi" "$rest" > "$tsout"
  done
}

# if not sourced (testing), run as command
eval "$(iffmain "mkTS_roi_main")"

####
# testing with bats. use like
#   bats ./mkTS_roi.bash --verbose-run
####
mkTS_roi_main_test() { #@test
   run mkTS_roi_main
   [[ $output =~ ".*" ]]
}
