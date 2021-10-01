#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

# run hc_populate.m for each subject  
#  20211001WF  init
scriptdir=$(cd "$(dirname "$0")"; pwd)
SPECDIR=/Volumes/Hera/Projects/7TBrainMech/scripts/mri/Hc/spectrum
MATLAB="/opt/ni_tools/MATLAB/R2014a/bin/matlab -nodesktop -nosplash"
echo using "$MATLAB"

[ $# -eq 0 ] && echo "USAGE: $0 [all|list|YYYYMMDDLunaT]" && exit 1

# todo. check against finished
list_all(){ ls -d $SPECDIR/*/|sed s:/$::; }
case $1 in
   all) SUBJS=($(list_all));;
   list) list_all | sed s:.*/::; exit 0;;
   *) sdir=$SPECDIR/$1
      [ ! -r $sdir ] && echo "$1: $sdir does not exist!" && exit 1
      SUBJS=($sdir);;
esac
for sdir in ${SUBJS[@]}; do
   subj=$(basename $sdir)
   echo "$(tput setaf 2)FYI: type quit() when done with subject!$(tput sgr0)"
   cd $sdir
   $MATLAB -r "try, addpath('$scriptdir'); f=hc_populate('$subj'), catch e, disp(e), quit(), end"
   cd -
done
