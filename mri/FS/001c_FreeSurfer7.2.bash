#!/usr/bin/env bash
source "$(dirname "$0")"/setup_FS72.bash
bidsroot="/Volumes/Hera/Projects/7TBrainMech/BIDS/"

[ -v DRYRUN ] && DRYRUN=echo || DRYRUN=

# setup jobs
export MAXJOBS=15 WAITTIME=60 JOBCFGDIR="$(dirname $0)/.jobcfg"
source /opt/ni_tools/lncdshell/utils/waitforjobs.sh # waituntildone waitforjobs

run_from_t1(){
   local t1="$1"
   local ld8=$(ld8 ${t1//\//_})
   [ -z "$ld8" ] && echo "ERROR: no id in $t1" && return
   [[ $ld8 == "11681_20181012" ]] && echo "# skipping $ld8, known bad!" && return
   logfile=$SUBJECTS_DIR/$ld8/scripts/recon-all.log 
   grep -q finished\ without $logfile 2>/dev/null && echo "# complete $logfile" && return
   pgrep -af "recon-all.*$ld8" && echo "$ld8: already running" && return
   if [ ! -r $logfile ]; then
      echo "# $ld8 init from $t1"
      $DRYRUN recon-all -subjid $ld8 -i $t1 -all -cm
   else
      echo "# $ld8 resume (have $logfile)"
      $DRYRUN recon-all -subjid $ld8 -all -no-isrunning -cm
   fi
}

# highres
find_high_res(){
  find $bidsroot/sub* -iname '*T1*.nii.gz' -not -iname '*lowres*' -not -iname '*bold.nii.gz';
}
find_low_res(){
  find $bidsroot/sub* -iname '*T1*.nii.gz' -iname '*lowres*' -not -iname '*bold.nii.gz'|
  while read f; do 
    test -r "${f/_acq-lowres/}" &&
     echo "# low res $f has high res $_, not including" >&2 &&
     continue
  echo "$f"
done
}


T1FILES=()
[ $# -eq 0 ] && echo -e "USAGE: $0 [all|ld8 ld8 ...]\nalso DRYRUN=1 $0 all" && exit
while [ $# -gt 0 ]; do
 ld8="$1"; shift
 case "$ld8" in 
    all)
       [ $# -gt 0 -o -n "$T1FILES" ] && echo "use 'all' by itself!" && exit
       T1FILES=( $(find_high_res));; 
    low) 
       [ $# -gt 0 -o -n "$T1FILES" ] && echo "use 'low' by itself!" && exit
       export SUBJECTS_DIR="/Volumes/Hera/preproc/7TBrainMech_rest/FS7.2/lowres/"
       test -d $SUBJECTS_DIR || mkdir $_
       echo "switching SUBJECTS_DIR to $SUBJECTS_DIR"
       T1FILES=( $(find_low_res));; 

    1*_2*[0-9]) 
       sesdir=$bidsroot/sub-${ld8//_2*/}/${ld8//1*_/}
       # TODO: look to USE_LOWRES or similiar to find loweres
       file=$(find $sesdir -iname '*T1*.nii.gz' -not -iname '*lowres*' -not -iname '*bold.nii.gz')
       [ -z "$file" ] && echo "WARNING: no file for '$sesdir' ($ld8)" && continue
       T1FILES=(${T1FILES[@]} $file)
       ;;
   *) echo "bad id/option '$1'"; exit;;
 esac
done


for t1 in "${T1FILES[@]}"; do
  run_from_t1 $t1 &
  waitforjobs
done

echo done submitting
jobs
date
#[ -z "$DRYRUN" ] && waituntildone
wait
