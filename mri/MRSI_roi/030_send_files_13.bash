#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
env |grep -q "^DRYRUN=" && DRYRUN="echo" || DRYRUN=""

#
#
# organize files to send to victor
# copy of 030_send_files.bash, but for newer 24 roi
# makes e.g. 
#  14M	spectrum_out/20191127_24specs.zip
#
# 20200225 - copy from 030_send_files_24.bash 

nspecfiles=13  # number of coords
atlas=13MP20200207
INPICKONLY=1   # only copy if in pick_coords.txt?, ="" to disable

subj_root=$(cd $(pwd)/../../../subjs/; pwd)
# change me - outputfoldername version
# version=20200224      # init
# version=20200311      # second pass
version=$(date +%Y%m%d) 
rawversion="-v2idxfix" # 20200413 - fix bad coords!

_findspecs(){
   # default to "newer" find
   local newer="-newermt $2"
   local id="*"
   [ "$1" == "id" ] && id="$2" && newer=""
   # pre 2020-04-13 - when coord_mover didn't also mkspectrum
   #find $subj_root/$id/slice_PFC/MRSI_roi/raw$rawversion/ -iname '*spectrum.[0-9]*' $newer -exec stat -c "%y %n" {} \+ 
   # now coord mover makes it's own spectrum files
   find $subj_root/$id/slice_PFC/MRSI_roi/$atlas/ -iname '*spectrum.[0-9]*' $newer -exec stat -c "%y %n" {} \+ 
}
usage(){ echo "USAGE: $0 new OR $0 20yy-mm-dd OR $0 ld8list.txt" && exit 1; }

[[ $# -eq 0 || "$1" =~ help|-h ]] && usage
if [[ "$1" == "new" ]]; then
   # didn't start creating 13 ROI spectrum files until after feb 24
   # will also check already recieved files
   findspecs(){ _findspecs newer 2020-04-20;}
elif [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
   cmpdate="$1"
   findspecs(){ _findspecs newer $cmpdate;}
elif [ -r "$1" ]; then
   subjlist="$1"
   findspecs(){ for ld8 in $(cat $subjlist|xargs ld8); do _findspecs id $ld8; done; }
else
   usage
fi

root_out=spectrum_out/${version}_${atlas}specs
[ ! -d $root_out ] && mkdir -p $root_out

findspecs |
   grep -v 'spectrum.0.0' |
   # eg 2019-11-26 17:03:31.155522625 -0500 /Volumes/Hera/Projects/7TBrainMech/subjs/11752_20190315/slice_PFC/MRSI_roi/raw/spectrum.100.121
   sed 's/-//;s/-//' | # 2019-11-21 -> 20191121
   # extract lunaid from path when first column (date) is newer than 8 digit "$newer" value
   perl -slane 'next unless m:(/.*(\d{5}_\d{8}).*):; print "$2 $1 $F[0]" '|
while read ld8 f d; do
   ld8mr=$(grep $ld8 ../MRSI/txt/ids.txt |sed 's/ /-/;1q') # could maybe have done this with 'join'
   [ -z "$ld8mr" ] && echo "# unknown MRID for $ld8" >&2 && continue
   specyx=$(basename $f)

   # test where we might have downloaded
   prevlcm="$( (ls /Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/*/$ld8mr/$specyx.dir 2>/dev/null || echo -n) |sed 1q)"
   test -n "$prevlcm" -a -r "$prevlcm" && echo "# SKIP: have $_" >&2 && continue

   # test for were we want it
   prevlcm=/Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/MRSI_roi/LCModel/v2idxfx/$specyx.dir 
   test -r $prevlcm && echo "# SKIP: have $_" >&2 && continue

   if [ -n "$INPICKONLY" ]; then
      xy=$(echo $specyx| awk -F\. '{print (216+1-$3)"\t"(216+1-$2)}')
      ! grep -q "$xy" /Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/MRSI_roi/$atlas/*/picked_coords.txt &&
         echo "# SKIP: $ld8 $(basename $f) '$xy' not in $_ (INPICKONLY='' to ignore)" >&2 && 
         continue
   fi

   # link to directory
   outdir="$root_out/$ld8mr"
   [ ! -d $outdir ] && mkdir $outdir
   [ ! -r $root_out/$ld8mr/$(basename $f) ] && $DRYRUN ln -s $f $outdir/ # && echo $f 

   # if last fails, would result in an error
   continue
done

[ -n "$DRYRUN" ] && exit
zip -r $root_out.zip $root_out

#check
for d in $root_out/1*/; do
   n=$( find $d -type l |wc -l )
   [ $n -ne $nspecfiles ] && echo "$d has $n (not $nspecfiles) files" || :
   continue
done

