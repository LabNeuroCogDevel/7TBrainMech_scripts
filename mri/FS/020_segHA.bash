#!/usr/bin/env bash
#
# run hipocampal segmentation with FS7.2
# needs ML 2014b runtime (fs_install_mcr R2014b)
# sample run took ~30min
#  20211220WF  init
#  20230319WF  LOWRES env var

# before set -u b/c empty vars used by FS source script
source "$(dirname "$0")"/setup_FS72.bash
[ -v LOWRES ] && SUBJECTS_DIR="${SUBJECTS_DIR/highres/lowres}"
export MAXJOBS=15 WAITTIME=60 JOBCFGDIR="$(dirname "$0")/.jobcfg"
source /opt/ni_tools/lncdshell/utils/waitforjobs.sh # waituntildone waitforjobs

# safe bash scripting
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error $e"' EXIT
# env vars - dryrun to print; redo rerun everything (ignore existing files)
[ -v DRYRUN ] && DRYRUN=echo || DRYRUN=
[ -v REDO ] || REDO=

all_FS(){ ls -d "$SUBJECTS_DIR"/1*_2*|sed 's:.*/::'; }

isrunning(){ 
   local s="$1"
   runfile="$SUBJECTS_DIR/$s/scripts/IsRunningHPsubT1.lh+rh"
   [ ! -e "$runfile" ] && return 1
   echo "# have runfile $SUBJECTS_DIR/$s/scripts/IsRunningHPsubT1.lh+rh" >&2
   pgrep -af "segmentHA_T1.sh $s" >&2|| echo "but '$_' is not running!" >&2
   return 0
}
missing_segHA(){ 
   for s in "$@"; do
      [ -r  "$SUBJECTS_DIR/$s/stats/hipposubfields.rh.T1.v21.stats" ] && continue 
      isrunning $s && continue
      echo "$s"
   done
}

# find all subjids
mapfile -t all_subjs < <(all_FS)

# remove those that have already finished
# unlikely to want to redo but have env var option in case
# could be inside main for loop (originally thought we could give all ids to segmentHA_T1.sh)
if [ -z "$REDO" ]; then
   mapfile -t subjs < <(missing_segHA "${all_subjs[@]}")
else
   subjs=("${all_subjs[@]}")
fi

echo "Found ${#all_subjs[@]} FS recons; ${#subjs[@]} need segmentHA"
for s in "${subjs[@]}"; do
   echo "# $s"
   $DRYRUN time segmentHA_T1.sh "$s" &
   waitforjobs
done

# clean up
jobs
wait
