#!/usr/bin/env bash
#
# nowarp creates func_to_struct.mat but does not apply it
# affine transform for each run is only to that runs average.
# runs will not align to one another.
# move all runs in a visit to match that visit's T1
# NB. using flirt and is slooooow
#
# 20230103WF - init
# 20230105WF - updated 021[ab]* and decon_functions.bash 
#            removed old
#            'rename s/nowarp/nowarp_rmme_not-t1aligned/ /Volumes/Hera/Projects/7TBrainMech/subjs/1*_2*/MGSEncMem/nowarp/'
#
source decon_functions.bash # preroc_final_file
verb() { test -n "${VERBOSE:-}" && warn "$@"; return 0; }
dt(){ date +"[%FT%H:%M]"; }
rundir_to_t1(){
  local rundir="$1"
  local final_file
  final_file="$(preproc_final_file "$rundir")"
  local in4d="$rundir/$final_file"
  local ref="$rundir/mprage_bet.nii.gz"
  #t1dir=$(dirname "${rundir/MHTask_nost_nowarp/MHT1_2mm}")
  t1dir=$(dirname "${rundir}"|perl -pe 's/MHTask[^\/]*/MHT1_2mm/')
  [ ! -r "$ref" ] && ref="$t1dir/mprage_bet.nii.gz"
  local mat="$rundir/transforms/func_to_struct.mat"
  local out="$rundir/Wnfsdkm_func_4.nii.gz"
  # create Wnfsdkm_func_4.nii.gz using func_to_struct.mat
  #applyxfm4D <input volume> <ref volume> <output volume> <transformation matrix file/[dir]> [-singlematrix/-fourdigit/-userprefix <prefix>]]
  for fvar in in4d ref mat; do
     test ! -r ${!fvar} && warn "cannot read $fvar: '${!fvar}'" && return 1
  done 
  [ -r "$out" ] && verb "# $(dt) skipping. have '$out'" && return 0
  echo "# $(dt) creating $out"
  tic=$(date +%s)
  ref2mm=${ref/mprage_bet/mprage_2mm_zeros}
  ! test -r "$ref2mm" && 3dresample -inset "$ref"'<0>' -prefix "$ref2mm" -dxyz 2 2 2 
  niinote "$out"\
     flirt -in "$in4d" -init "$mat" -ref "$ref2mm" -applyxfm -o "$out" 
  3dNotes "$out" -h "# via '$0' for post-hoc warping"
     #applyxfm4D "$in4d" "$ref" "$out" "$mat"
  toc=$(date +%s)
  echo "# ... $(dc -e "2 k $toc $tic - 60 / p") minutes; $(dt) $(du -h "$out")"
}
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
011_nowarp_to_t1_main() {
  [ $# -eq 0 ] && usage && exit 1
  [ "$1" == "all" ] && 
     rundirs=(/Volumes/Hera/preproc/7TBrainMech_mgsencmem/MHTask_nost_nowarp/1*_2*/0[1-3]/) ||
     rundirs=("$@")

  source /opt/ni_tools/lncdshell/utils/waitforjobs.sh # waitforjobs
  [ ${#rundirs[@]} -eq 1 ] && MAXJOBS=1 || MAXJOBS=10 # set after sourceing to redef default 4

  for rundir in "${rundirs[@]}"; do
     rundir_to_t1 "$rundir" &
     # shellcheck disable=SC2119  # no args to external function
     waitforjobs
  done
  echo "$(dt) all submitted. waiting"
  wait
  # shellcheck disable=SC2119     # no args to external function
  #waituntildone; wait
  return 0
}

# if not sourced (testing), run as command
eval "$(iffmain "011_nowarp_to_t1_main")"

####
# testing with bats. use like
#   bats ./011_nowarp_to_t1.bash --verbose-run
####
011_nowarp_to_t1_main_test() { #@test
   local output
   run 011_nowarp_to_t1_main
   [[ $output =~ "USAGE" ]]
}
