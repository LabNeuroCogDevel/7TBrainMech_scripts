#!/usr/bin/env bash
#
# 20221212WF - init
# supporting functions for 3dDeconvolve
# expect file to be sourced
# also include same-file tests: bats --verbose-run decon_functions.bash
# tasktr from txt/task_trs.txt (see ../Makefile)
#


lookup_tr(){
   local ld8="$1"; shift
   local db="/Volumes/Hera/Projects/7TBrainMech/scripts/mri/txt/task_trs.txt"
   perl -slane '
    BEGIN{$ld8=~s:_:/:;} # orgnized like luna/date instead of luna_date
    print $F[1] and exit if /$ld8/ # print the second column of only the first match
   ' -- -ld8="$ld8" < $db
}

concat_indir(){
  # save output (arg 1) by cating inname (arg 2) for the dirname of each file (arg 3-)
  # drytee works with DRYRUN=1 to not save if dryrun
  # relying on 3dDeconvolve to panic if final file lines != sum of all input volumes
  local output="$1";shift
  local inname="$1";shift
  # printf "%s\n" "$@" | sed s:/.*?nii.gz:motion/motion.par: | xargs cat
  
  # already have and dont want to redo? skip
  [ -r "$output" ] && [ -z "${REDO:-}" ] && echo "$output" && return 0
  for nii in "$@"; do
     cat "$(dirname "$nii")"/"$inname" || return 1
  done | drytee "$output"
  echo "$output"
}
fd_censor(){
 local in="$1"; shift
 local thres="$1"; shift
 local out="$in.cen$thres.1d"
 # already have and dont want to redo? skip
 [ -r "$out" ] && [ -z "${REDO:-}" ] && echo "$out" && return 0
 dryrun 1deval -a "$in" -expr "step($thres-a)" |drytee "$out" 
 echo "$out"
}

check_inputs(){
   local ex1dfile="$1"; shift
   local inputs4d=("$@")
   
   [ ! -r "$ex1dfile" ] &&
      warn "$ld8 ERROR: missing  1d files (no $ex1dfile)" && return 1
   nb1d=$(wc -l < "$ex1dfile") # line per run on 1d file
   nbts=${#inputs4d[@]}
   [ ! -r "${inputs4d[0]}" ] && warn "ERROR: no nii inputs '${inputs4d[*]}'" && return 1
   [ "$nb1d" -ne "$nbts" ] &&
      warn "$ld8 ERROR: have $nb1d block onsets for $nbts files"  && return 1
   return 0
}
check_tr(){
   tr="$1"
   if [ -z "$tr" ] || [ "$tr" == "0" ]; then 
      warn "# no tr for $ld8" 
      return 1
   fi
   return 0
}


# run through all deconds
decon_all_nost() {
  cd "$(dirname "$0"|| pwd)"
  SUBJDIR=$(cd ../../subjs/; pwd)
  [[ ! $SUBJDIR =~ subjs$ ]] && echo "NO SUBJECT DIR?! ($SUBJDIR)" && exit 1
  export SUBJDIR

  [ $# -lt 2 ] && decon_all_usage
  decon_func="$1"; shift

  # all or just what's given
  [ "$1" == "all" ] &&  
    preproc_dirs=(/Volumes/Hera/Projects/7TBrainMech/pipelines/MHTask_nost/1*_2*/) ||
    preproc_dirs=("$@")

  oned_dir=$(pwd)/1d/trial_hasimg_lr/
  warn "# running for ${#preproc_dirs[@]} preproc dirs"
  for predir in "${preproc_dirs[@]}"; do
    $decon_func "$oned_dir" "$predir" || continue
  done
}

decon_all_usage(){
cat <<HEREDOC
Usage: $0 [all|/Volumes/Hera/Projects/7TBrainMech/pipelines/MHTask_nost/10173_2*/]
 arguments:
  "all" to run for all preproc dirs
  otherwise give one or more preproc paths specifically

 globals (e.g. "DRYRUN=1 ./021_deconvolve.bash all"):
    DRYRUN=1 to print decon command
    REDO=1 to not skip if already have output

 20221209 TODO: motion censor and ortvec; single -stim_times_AM1 to model all task activity?
HEREDOC
exit
}


#### TESTS
function lookup_tr_test { #@test
  local output
  run lookup_tr 11875_20220630
  [[ $output == 2.231813 ]]

  run lookup_tr 10129_20180917 
  [[ $output == 2.196749 ]]
}

function fd_cen_test { #@test
   echo -e '.1\n.5\n.49999' > "$BATS_TEST_TMPDIR/fd.txt"
   local output
   outf="$BATS_TEST_TMPDIR/fd.txt.cen.5.1d"
   run fd_censor "$BATS_TEST_TMPDIR/fd.txt" .5
   [[ $output == "$outf" ]]

   run perl -ne 'print $& if m/\d+/' "$outf"
   [[  $output == 101 ]]
}

function concat_indir_test { #@test
  cd "$BATS_TEST_TMPDIR"
  mkdir a b c
  echo 1 > a/1; echo 2 > b/1; echo 3 > c/1
  run concat_indir ./all.txt 1 c/x a/x b/x
  [[ $output == "./all.txt" ]]

  run perl -ne 'print $& if m/\d+/' all.txt
  [[  $output == 312 ]]
}
