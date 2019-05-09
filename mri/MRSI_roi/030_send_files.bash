#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
# organize files to send to victor
#

# 20190502 - init
# 20190507 - 10 more subjects, saved in a different directory for easy zipping (and then sending to MRRC)

SUBJS="*" # 20190502
SUBJS="{10129_20180917,10173_20180802,10997_20180818,11299_20180511,11664_20180712,11682_20180907,11703_20181019,11706_20190322,11726_20190111,11751_20190228,11752_20190315}" #20190507

version=20190507
root_out=spectrum_out/$version
[ ! -d $root_out ] && mkdir -p $root_out

subj_root=$(cd $(pwd)/../../../subjs/; pwd)
eval find $subj_root/$SUBJS/slice_PFC/MRSI_roi/raw/ -iname "'*spectrum*'" |
while read f; do
   [[ $f =~ [0-9]{5}_[0-9]{8} ]] || continue
   ld8=${BASH_REMATCH}
   ld8mr=$(grep $ld8 ../MRSI/txt/ids.txt |sed 's/ /-/;1q')
   [ -z "$ld8mr" ] && echo "unknown MRID for $ld8 " && continue
   outdir="$root_out/$ld8mr"
   [ ! -d $outdir ] && mkdir $outdir
   [ ! -r $root_out/$ld8mr/$(basename $f) ] && ln -s $f $outdir/ && echo $f 
   n=$( find $outdir -type l |wc -l )
   [ $n -ne 13 ] && echo "$outdir has $n (not 13) files"
   continue
done

zip -r $root_out.zip $root_out
