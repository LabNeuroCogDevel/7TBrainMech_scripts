#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
cd $(dirname $0)
finalout=pdf/putamen_all.pdf 

# 20230321WF - copy of gen_pdf.bash. 
# TODO: use bmark logic in ../Hc/gen_pdf.bash

pg=1
[ $# -eq 0 ] && echo "USAGE: $0 [all|/*/csi.pdf]
create giant pdf from page $pg of csi.ps
written to /tmp/mrsi-pdfs and pdf/csi_all-gt\$date-pg\${pg:-1}.pdf
and includes created 'bookmarks' for each csi.ps file
" >&2 && exit 1

[ -n "${TMPDIR:-}" ] &&  tmpdir=$TMPDIR || tmpdir=$(mktemp -d /tmp/mrsi-pdfs-putamen-XXXX)
test -d "$tmpdir" || dryrun mkdir "$_"
#find /Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/HPC/ProcessedHc20200422/20*/spectrum*.dir -type f -name csi.ps -newermt $newer | while read f; do

if [ $1 == all ]; then
mapfile -t FILES < <(find /Volumes/Hera/Projects/7TBrainMech/subjs/1*_2*/slice_PFC/MRSI_roi/putamen2/*/spectrum.*dir/ \
   -type f -name csi.ps)
else
   FILES=("$@")
fi

warn "# running for ${#FILES[@]} csi.ps files"
[ -n "${DRYRUN:-}" ] && echo "# ${FILES[*]}" && exit 0

for f in "${FILES[@]}"; do
  #name=$(basename $(dirname $(dirname $f)))
  #pos=$(echo $f|perl -lne 'print $1 if /(\d+.\d+\.[LR])/')
  #out=$tmpdir/$name-$pos-pg$pg.pdf
  out=$tmpdir/$(ld8 "$f")-$(echo "$f"|perl -lne 'print $1 if /spectrum.(\d+.\d+).dir/')-pg$pg.pdf
  [ -r "$out" ] && continue
  echo "$out"
  gs -q -dSAFER -dBATCH -dFirstPage=$pg -dLastPage=$pg -sDEVICE=pdfwrite -o "$out" "$f"
done


# make bookmark file
ls "$tmpdir/"*-pg$pg.pdf |
 sed "s:.*/::;s:-pg$pg.pdf$::" |
 perl -lne '
   print "[/Page ", ++$i, " /View [/XYZ null null null] /Title ($_) /OUT pdfmark"
  ' > "$tmpdir/bookmarks-pg$pg.ps"

echo "# combining to make $finalout"
test ! -d pdf && mkdir "$_"
gs -q -dSAFER -dBATCH -sDEVICE=pdfwrite -o "$finalout" "$tmpdir/bookmarks-pg$pg.ps" -f "$tmpdir/"*pg$pg.pdf
echo "made $finalout"

rm -r "$tmpdir"
