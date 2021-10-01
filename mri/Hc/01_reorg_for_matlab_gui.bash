#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
[ -v DRYRUN ] && DRYRUN=echo || DRYRUN=""

#
# reorganize files to for spectrum gui
#  20210825WF  init

# most coreg and siarray are in Recon. but a few are in Shim
for rdir in /Volumes/Hera/Raw/MRprojects/7TBrainMech/202*/Recon \
   $(ls /Volumes/Hera/Raw/MRprojects/7TBrainMech/202*/Shim/CoregH[cC] | xargs dirname); do
   [[ $rdir =~ 20[0-9]{6}Luna[1-9] ]] || continue
   id=${BASH_REMATCH}
   siarray=$(find $rdir/ -maxdepth 2 -type f,l -iname siarray.1.1 -ipath '*CSIHC*' -print -quit)
   # scout might be larger or smaller, but we want middle of 13, so always 7th slice
   center=$(find $rdir/ -maxdepth 3 -type f,l  -iname '1[6789]_7_FlipLR.MPRAGE' -ipath '*CoregHC*' -print -quit)
   [ -z "$siarray" -o ! -s "$siarray" ] && echo "$id: missing siarray.1.1 -- probably not a HC visit ($rdir)" >&2 && continue
   [ -z "$center" -o ! -s "$center" ] && echo "$id: missing 17_7_FlipLR.MPRAGE -- maybe different res scout (e.g. need 21_10) ($rdir)" >&2 && continue
   outdir=$(pwd)/spectrum/$id 
   test -d $outdir || $DRYRUN mkdir $outdir
   test -e $outdir/siarray.1.1 || $DRYRUN ln -s $siarray $_
   test -e $outdir/recr.1.0.1.1.7 || $DRYRUN ln -s $center $_
   test -e $outdir/seg.7          || $DRYRUN ln -s $center $_
   test -e $outdir/anat.mat       || $DRYRUN ln -s $center $_

done


