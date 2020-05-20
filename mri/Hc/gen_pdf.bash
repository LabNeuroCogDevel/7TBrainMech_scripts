#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
cd $(dirname $0)

#
# 20200520WF - copy from ../MRSI_roi/gen_pdf.bash
#  make pdf from first page of csi.pdf
#

# depends on manual unzip
# like 
#  cd /Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01
#  unzip -d HPC/ ProcessedHc_20200520_2019-Mar2020.zip

env|grep ^DRYRUN= && DRYRUN=echo || DRYRUN=""

pg=1
newer=2020-04-24
tmpdir=$(mktemp -d /tmp/mrsi-pdfs-XXXX)
test -d $tmpdir || mkdir $_

hpcdirs='/Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/HPC/ProcessedHc*/20*/spectrum*/'
find $hpcdirs -type f,l -name csi.ps -newerct $newer |
while read f; do
  pos=$(echo $f|perl -lne 'print "$3-$2-$1" if /(\d+.\d+)\.([LR])\.(\d+)/')
  [ -z "$pos" ] && echo "# no region info in '$f'" >&2 && continue

  name=$(basename $(dirname $(dirname $f)))
  ld8=$(echo $f|perl -lne 'print $& if m:\d{8}Luna[^/]*:' | xargs -n1 -I{} grep -i {} ../MRSI/txt/ids.txt |cut -f 1 -d ' ' || echo "")
  [ -z "$ld8" ] && echo "# no ld8 using $name '$f'" >&2 && ld8=$name

  out=$tmpdir/$ld8-$pos-pg$pg.pdf
  [ -r "$out" ] && continue
  echo $out
  $DRYRUN gs -q -dSAFER -dBATCH -dFirstPage=$pg -dLastPage=$pg -sDEVICE=pdfwrite -o "$out" $f
done

[ -n "$DRYRUN" ] && exit 0

# make bookmark file
ls $tmpdir/*-pg$pg.pdf |
 sed "s:.*/::;s:-pg$pg.pdf$::" |
 perl -lne 'print "[/Page ", ++$i, " /View [/XYZ null null null] /Title ($_) /OUT pdfmark"' > $tmpdir/bookmarks-pg$pg.ps

echo "combining"
[ ! -d pdf ] && mkdir $_
finalout=pdf/hpc_pg${pg}_${newer}_$(date +%F).pdf
gs -q -dSAFER -dBATCH -sDEVICE=pdfwrite -o $finalout $tmpdir/bookmarks-pg$pg.ps -f $tmpdir/*pg$pg.pdf
echo made $finalout

rm -r "$tmpdir"
