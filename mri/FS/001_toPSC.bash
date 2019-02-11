#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

# lncd has ssh keys
if [ $(whoami) != "lncd" ]; then
   sudo -u lncd $0
   exit
fi

#
# put all t1s on pittsburgh super computer
#
cd /Volumes/Hera/Projects/7TBrainMech/BIDS/
rsync -azvhir ./ luna@bridges.psc.xsede.org:scratch/T1 --files-from=<(find sub-1* -iname '*T1*.nii.gz')

# need login shell to load sbatch and squeue
ssh luna@bridges.psc.xsede.org -t 'bash -lc ./run.bash'
