#!/usr/bin/env bash
[ -v DRYRUN ] && DRYRUN=echo || DRYRUN=

export SUBJECTS_DIR="/Volumes/Hera/preproc/7TBrainMech_rest/FS"
bidsroot="/Volumes/Hera/Projects/7TBrainMech/BIDS/"

# setup jobs
export MAXJOBS=15 WAITTIME=60 JOBCFGDIR="$(dirname $0)/.jobcfg"
source /opt/ni_tools/lncdshell/utils/waitforjobs.sh # waituntildone waitforjobs

find $bidsroot/sub* -iname '*T1*.nii.gz' -not -iname '*lowres*' -not -iname '*bold.nii.gz' |
   while read t1; do
   ld8=$(ld8 ${t1//\//_})
   [ -z "$ld8" ] && echo "ERROR: no id in $t1" && continue
   [[ $ld8 == "11681_20181012" ]] && echo "# skipping $ld8, known bad!" && continue
   logfile=$SUBJECTS_DIR/$ld8/scripts/recon-all.log 
   grep -q finished\ without $logfile 2>/dev/null && echo "# complete $logfile" && continue
   pgrep -af "recon-all.*$ld8" && echo "$ld8: already running" && continue
   if [ ! -r $logfile ]; then
      $DRYRUN recon-all -subjid $ld8 -i $t1 -all &
   else
      echo "# $t1"
      $DRYRUN recon-all -subjid $ld8 -all -no-isrunning &
   fi
   waitforjobs
done

waituntildone
wait
