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
regressors_in_use(){
   # given list of preproc file nifti files
   # find the regressors_in_use and list those
   # use to put what preprocessfunctional thinks is in regerssors into output files history (3dNotes)
   printf '%s\n' "$@"|
      sed 's:/[^/]*\?$:/.regressors_in_use:g' |
      xargs sed 's/ /,/g;s/\[\([0-9]\)\]/_\1/g;s/\.//g'|uniq|paste -sd:o
}

list_inputs(){
   # 20230105: look for either W prefix (_nowarp) for mprage aligned functional (from 011_nowarp_to_t1.bash)
   #           or standard nfswdkm with warp to mni (default preprocessFunctional)
   local preproc_glob="$1"; shift
   # nfswdkm for warp,Wnfsdkm for nowarp T1-aligned 
   # shellcheck disable=SC2086,SC2010 # want globbing, so no quote
   ls $preproc_glob/*nfs*dkm_func_4.nii.gz | grep -Pi 'Wn|wd'
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
      warn "$ld8 ERROR: missing  1d files (no $ex1dfile, see './020_task_onsets.R $ld8' and 'tree /Volumes/L/bea_res/Data/Tasks/MGSEncMem/7T/$ld8')" && return 1
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

decon_dir(){
   case $1 in
      */MHTask_nost_nowarp/*) echo MGSEncMem/nowarp;;
      */MHTask_nost/*) echo MGSEncMem/mni;;
      *) warn "don't know how to derive decon dir from '$1'"; return 1;;
   esac
}


# run through all deconds
decon_all_nost() {
  cd "$(dirname "$0"|| pwd)"
  SUBJDIR=$(cd ../../subjs/; pwd)
  [[ ! $SUBJDIR =~ subjs$ ]] && echo "NO SUBJECT DIR?! ($SUBJDIR)" && exit 1
  export SUBJDIR

  [ $# -lt 2 ] && decon_all_usage
  decon_func="$1"; shift

  # can give 'all', 'mni', 'nowarp', 'procdir' or work on explict preproc dirs what's given
  # like /Volumes/Hera/Projects/7TBrainMech/pipelines/MHTask_nost_nowarp/10195_20191205/
  case "$1" in
     all) preproc_dirs=(/Volumes/Hera/Projects/7TBrainMech/pipelines/MHTask_nost{,_nowarp}/1*_2*/);;
     nowarp) preproc_dirs=(/Volumes/Hera/Projects/7TBrainMech/pipelines/MHTask_nost_nowarp/1*_2*/);;
     mni) preproc_dirs=(/Volumes/Hera/Projects/7TBrainMech/pipelines/MHTask_nost/1*_2*/);;
     procdir) preproc_dirs=(/Volumes/Hera/Projects/7TBrainMech/pipelines/"$PROCDIR"/1*_2*/);;
     *) preproc_dirs=("$@");;
  esac
    

  warn "# running for ${#preproc_dirs[@]} preproc dirs"
  for predir in "${preproc_dirs[@]}"; do
    $decon_func "$predir" || continue
  done
}

decon_all_usage(){
cat <<HEREDOC
USAGE:
 $0 [all|mni|nowarp|/Volumes/Hera/Projects/7TBrainMech/pipelines/MHTask_nost/10173_2*/]

SYNOPSIS:
 Arguments
   "all" to run for all preproc dirs (MHTask_nost, MHTask_nost_nowarp)
   "mni" - just MHTask_nost
   "nowarp" - just MHTask_nost_nowarp
   "procdir" - use whatever \$PROCDIR is (e.g export PROCDIR=MHTask_nost)
  otherwise give one or more preproc paths specifically, e.g.
  /Volumes/Hera/Projects/7TBrainMech/pipelines/MHTask_nost/10173_2*/

 Globals
    DRYRUN=1    print decon command(s) but do not actually run
    REDO=1      run even if already have output (just print if DRYRUN)

NOTES:
 20221228
  - add MHTask_nost_nowarp and decon_dir to set output approprately. arg opts mni, nowarp, procdir
  TODO: use regressors.txt instead of all_motion.par
 20221209
  - see decon_functions.bash for supporting code
  - added tr and concat censor/fd. TODO: other models, 'waitforjobs' for parallel processing

EXAMPLES:
 $0 all
 DRYRUN=1 $0 /Volumes/Hera/Projects/7TBrainMech/pipelines/MHTask_nost/10173_2*/

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

function decon_dir_test { #@test
  run decon_dir /Volumes/Hera/Projects/7TBrainMech/pipelines/MHTask_nost/10173_20180802/
  [[  $output == MGSEncMem/mni ]]

  run decon_dir /Volumes/Hera/preproc/7TBrainMech_mgsencmem/MHTask_nost_nowarp/10173_20180802/
  [[  $output == MGSEncMem/nowarp ]]
}
function list_inputs_test { #@test
   run list_inputs  "/Volumes/Hera/Projects/7TBrainMech/pipelines/MHTask_nost_nowarp/10173_20180802/0*/" 
   [[ $(grep -c '\n' <<< "$output") == 3 ]]
   [[ $output =~ Wnfsdkm_func_4.nii.gz ]]
   run list_inputs  "/Volumes/Hera/Projects/7TBrainMech/pipelines/MHTask_nost/10173_20180802/0*/" 
   [[ $(grep -c '\n' <<< "$output") == 3 ]]
   [[ $output =~ nfswdkm_func_4.nii.gz ]]
   
}
function regressors_in_use_test { #@test
   run regressors_in_use /Volumes/Hera/Projects/7TBrainMech/pipelines/MHTask_nost_nowarp/10173_20200221/0*/W*nii.gz
   [[ $output == "motion_demean_0,motion_demean_1,motion_demean_2,motion_demean_3,motion_demean_4,motion_demean_5,csf_ts,motion_deriv_0,motion_deriv_1,motion_deriv_2,motion_deriv_3,motion_deriv_4,motion_deriv_5,csf_ts_deriv,wm_ts_deriv,wm_ts" ]]
}
