#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
cd $(dirname $0)

#
# 20200402WF - init - make pdfs of first page
#

pg=1
newer=2020-04-19
tmpdir=$(mktemp -d /tmp/mrsi-pdfs-XXXX)
test -d $tmpdir || mkdir $_
#find /Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/HPC/ProcessedHc20200422/20*/spectrum*.dir -type f -name csi.ps -newermt $newer | while read f; do
find /Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/20*/*_20*/spectrum*.dir -type f -name csi.ps -newermt $newer | while read f; do

  #name=$(basename $(dirname $(dirname $f)))
  #pos=$(echo $f|perl -lne 'print $1 if /(\d+.\d+\.[LR])/')
  #out=$tmpdir/$name-$pos-pg$pg.pdf
  out=$tmpdir/$(ld8 $f)-$(echo $f|perl -lne 'print $1 if /spectrum.(\d+.\d+).dir/')-pg$pg.pdf
  [ -r "$out" ] && continue
  echo $out
  gs -q -dSAFER -dBATCH -dFirstPage=$pg -dLastPage=$pg -sDEVICE=pdfwrite -o "$out" $f
done

# make bookmark file
ls $tmpdir/*-pg$pg.pdf |
 sed "s:.*/::;s:-pg$pg.pdf$::" |
 perl -lne 'print "[/Page ", ++$i, " /View [/XYZ null null null] /Title ($_) /OUT pdfmark"' > $tmpdir/bookmarks-pg$pg.ps

echo "combining"
[ ! -d pdf ] && mkdir $_
finalout=pdf/csi_all-gt$newer-pg$pg.pdf 
gs -q -dSAFER -dBATCH -sDEVICE=pdfwrite -o $finalout $tmpdir/bookmarks-pg$pg.ps -f $tmpdir/*pg$pg.pdf
#gs -q -dSAFER -dBATCH -sDEVICE=pdfwrite -o pdf/hpc-$(date +%F)-pg$pg.pdf $tmpdir/bookmarks-pg$pg.ps -f $tmpdir/*pg$pg.pdf
echo made $finalout

rm -r "$tmpdir"
