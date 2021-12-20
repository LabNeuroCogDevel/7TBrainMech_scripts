#!/usr/bin/env bash
#
# run hipocampal segmentation with FS7.2
# needs ML 2014b runtime (fs_install_mcr R2014b)
# sample run took ~30min
#  20211220WF  init

# before set -u b/c empty vars used by FS source script
source "$(dirname "$0")"/setup_FS72.bash
export MAXJOBS=15 WAITTIME=60 JOBCFGDIR="$(dirname $0)/.jobcfg"
source /opt/ni_tools/lncdshell/utils/waitforjobs.sh # waituntildone waitforjobs

# safe bash scripting
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
# env vars - dryrun to print; redo rerun everything (ignore existing files)
[ -v DRYRUN ] && DRYRUN=echo || DRYRUN=
[ -v REDO ] || REDO=


# find all subjids
all_subjs="$(ls -d $SUBJECTS_DIR/1*_2*|sed 's:.*/::')"

# remove those that have already finished
# unlikely to want to redo but have env var option in case
# could be inside main for loop (originally thought we could give all ids to segmentHA_T1.sh)
[ -z "$REDO" ] &&
   subjs="$(for s in $all_subjs; do [ ! -r  $SUBJECTS_DIR/$s/stats/hipposubfields.rh.T1.v21.stats ] && echo $s; done)" || 
   subjs="$all_subjs"

for s in $subjs; do
   $DRYRUN time segmentHA_T1.sh $s &
   waitforjobs
done

# clean up
wait
waituntildone
