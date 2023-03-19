#!/usr/bin/env bash
#
# run thalmus segmentation with FS7.2
# 20230313 copy of 020_segHA.bash, for OR

# before set -u b/c empty vars used by FS source script
source "$(dirname "$0")"/setup_FS72.bash
[ -v LOWRES ] && SUBJECTS_DIR="${SUBJECTS_DIR/highres/lowres}"
export MAXJOBS=15 WAITTIME=60 JOBCFGDIR="$(dirname "$0")/.jobcfg"
source /opt/ni_tools/lncdshell/utils/waitforjobs.sh # waituntildone waitforjobs

RUNNING=IsRunningThalamicNuclei_mainFreeSurferT1
STATS=thalamic-nuclei.rh.v12.T1.stats
SCRIPT=segmentThalamicNuclei.sh

# safe bash scripting
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error $e"' EXIT
# env vars - dryrun to print; redo rerun everything (ignore existing files)
[ -v REDO ] || REDO=

all_FS(){ ls -d "$SUBJECTS_DIR"/1*_2*|sed 's:.*/::'; }

isrunning(){ 
   local s="$1"
   runfile="$SUBJECTS_DIR/$s/scripts/$RUNNING"
   [ ! -e "$runfile" ] && return 1
   warn "# have runfile $runfile"
   pgrep -af "$SCRIPT $s" >&2 || warn "but '$_' is not running!"
   return 0
}
missing_segThal(){ 
   for s in "$@"; do
      [ -r  "$SUBJECTS_DIR/$s/stats/$STATS" ] && continue 
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
   mapfile -t subjs < <(missing_segThal "${all_subjs[@]}")
else
   subjs=("${all_subjs[@]}")
fi

echo "Found ${#all_subjs[@]} FS recons; ${#subjs[@]} need $SCRIPT"
for s in "${subjs[@]}"; do
   echo "# $s"
   dryrun time $SCRIPT "$s" &
   waitforjobs
done

# clean up
jobs
wait
