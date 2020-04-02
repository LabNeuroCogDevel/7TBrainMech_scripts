#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
# 20200402WF - init - make pdfs of first page
#


test -d /tmp/pdfs || mkdir $_
find /Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/2020*/*_20*/spectrum*.dir -type f -name csi.ps | while read f; do
  out=/tmp/pdfs/$(ld8 $f)-$(echo $f|perl -lne 'print $1 if /spectrum.(\d+.\d+).dir/').pdf
  echo $out
  gs -q -dSAFER -dBATCH -dFirstPage=1 -dLastPage=1 -sDEVICE=pdfwrite -o $out $f
done
ls /tmp/pdfs/*pdf |
 sed 's:.*/::;s:.pdf::' |
 perl -lne 'print "[/Page 1 /View [/XYZ null null null] /Title ($_) /OUT pdfmark"' > /tmp/pdfs/bookmarks.ps
gs -q -dSAFER -dBATCH -sDEVICE=pdfwrite -o csi_all1.pdf /tmp/pdfs/bookmarks.ps -f /tmp/pdfs/*pdf

