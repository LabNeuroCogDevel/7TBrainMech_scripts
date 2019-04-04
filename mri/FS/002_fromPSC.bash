#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
# put all t1s on pittsburgh super computer
#
if [ $(whoami) != "lncd" ]; then
   sudo -u lncd $0
   exit
fi
rsync -azvhir luna@bridges.psc.xsede.org:scratch/FS  /Volumes/Hera/preproc/7TBrainMech_rest/  

