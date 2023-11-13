#!/usr/bin/env bash
set -x
#
# rerun preproc for only the last steps with smoothing removed
# extends 011_nowarp_to_t1.bash, reusing mprage_2mm_zeros.nii.gz
# 
# 20231113WF - init
dt(){ date +"[%FT%H:%M]"; }

usage(){
   echo "USAGE:
   $0 [all|rundir|glob]

   OPTIONS:
    if first argument is 'all', runs on
     /Volumes/Hera/preproc/7TBrainMech_mgsencmem/MHTask_nost_nowarp/1*_2*/0[1-3]/
    otherwise specify your own rundir or dir pattern/glob. eg.
     /Volumes/Hera/preproc/7TBrainMech_mgsencmem/MHTask_nost_nowarp/10129_20180917/01/
     /Volumes/Hera/preproc/7TBrainMech_mgsencmem/MHTask_nost_nowarp/10129_20180917/0*/

   SYNOPSIS:
$(sed -n '1,/^# 20/s/^# /    /p' "$0"|sed '$d')" # sed here puts the top desc into the usage
}
011b_main() {
  [ $# -eq 0 ] && usage && exit 1
  [ "$1" == "all" ] && 
     rundirs=(/Volumes/Hera/preproc/7TBrainMech_mgsencmem/MHTask_nost_nowarp/1*_2*/0[1-3]/) ||
     rundirs=("$@")

  for rundir in "${rundirs[@]}"; do
     redopreproc "$rundir/nosmooth" &
     # shellcheck disable=SC2119  # no args to external function
     waitforjobs
  done
  echo "$(dt) all submitted. waiting"
  wait
  return 0
}
redopreproc(){
   finalfile=Wnfdkm_func.nii.gz
   test -r "$1/$finalfile" &&
      warn "# have $_; skipping" &&
      return 0
   mkdir -p "${1:?subdir with parent having preproc outputs to remove smoothing from}"
   cd "$1" || return 1

   # all compelete flags but the ones after smoothing
   mapfile -t complete_flags < <(
     find .. -maxdepth 1 -name '.*complete'|
     grep -Pv 'temporal_filt|recaling|preprocessfunctional')

   # can use *func.nii.gz b/c anything after smoothing has an extra suffix '*func_4.nii.gz'
   # also need epi_bet, transforms, and motion files to avoid recomputing things that aren't used anyway
   for f in "${complete_flags[@]}" ../*func.nii.gz ../mc* ../epi_bet.nii.gz ../transforms/; do
      ! test -e "$f"  && warn "ERROR: MISSING '$f' ($PWD)" && return 1
      test -e "$(basename "$f")" || ln -s "$f" ./
   done

   # stop smoothing but otherwise keep args the same 
   sed 's/^/-no_smooth /' ../.preproc_cmd  > .preproc_cmd
   yes | preprocessFunctional
   # and copy ./011_nowarp_to_t1.bash's warp to mni
   niinote "$finalfile" \
      flirt -in nfdkm_func.nii.gz \
            -init ../transforms/func_to_struct.mat \
            -ref ../mprage_2mm_zeros.nii.gz \
            -applyxfm \
            -o "$finalfile"
   return 0
}

# if not sourced (testing), run as command
eval "$(iffmain "011b_main")"

