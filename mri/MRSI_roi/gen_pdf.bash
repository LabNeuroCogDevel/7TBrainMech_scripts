#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
cd $(dirname $0)

#
# 20200402WF - init - make pdfs of first page
#

pg=1

test -d /tmp/pdfs || mkdir $_
find /Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/2020*/*_20*/spectrum*.dir -type f -name csi.ps | while read f; do
  out=/tmp/pdfs/$(ld8 $f)-$(echo $f|perl -lne 'print $1 if /spectrum.(\d+.\d+).dir/')-pg$pg.pdf
  [ -r "$out" ] && continue
  echo $out
  gs -q -dSAFER -dBATCH -dFirstPage=$pg -dLastPage=$pg -sDEVICE=pdfwrite -o "$out" $f
done

# make bookmark file
ls /tmp/pdfs/*-pg$pg.pdf |
 sed "s:.*/::;s:-pg$pg.pdf$::" |
 perl -lne 'print "[/Page ", ++$i, " /View [/XYZ null null null] /Title ($_) /OUT pdfmark"' > /tmp/pdfs/bookmarks-pg$pg.ps

echo "combining"
[ ! -d pdf ] && mkdir $_
gs -q -dSAFER -dBATCH -sDEVICE=pdfwrite -o pdf/csi_all$pg.pdf /tmp/pdfs/bookmarks-pg$pg.ps -f /tmp/pdfs/*pg$pg.pdf

