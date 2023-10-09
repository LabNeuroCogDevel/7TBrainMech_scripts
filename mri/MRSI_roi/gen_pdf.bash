#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
cd $(dirname $0)

#
# 20200402WF - init - make pdfs of first page
# 20220221WF - require specify newer than date
# 20221205WF - add dryrun, update find w/ PFC/

pg=1
[ $# -ne 1 ] && echo "USAGE: $0 yyyy-mm-dd
create giant pdf from page $pg of csi.ps newer than provided date for visual QC
written to /tmp/mrsi-pdfs and pdf/csi_all-gt\$date-pg\${pg:-1}.pdf
and includes created 'bookmarks' for each csi.ps file
" >&2 && exit 1
#newer=2020-04-19
newer="$1"
[[ ! $newer =~ ^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$ ]] && echo "BAD DATE '$newer'. want yyyy-mm-dd" >&2 && exit 1

[ -n "${TMPDIR:-}" ] &&  tmpdir=$TMPDIR || tmpdir=$(mktemp -d /tmp/mrsi-pdfs-XXXX)
test -d "$tmpdir" || dryrun mkdir "$_"
#find /Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/HPC/ProcessedHc20200422/20*/spectrum*.dir -type f -name csi.ps -newermt $newer | while read f; do
#mapfile -t FILES < <(find /Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/{20*,PFC/20*/spectrum_out/20*}/*_20*/spectrum*.dir \
#   -type f -name csi.ps -newermt "$newer")

# 20231002 - change with 030a_lcmodel_diy.bash -- we run lcmodel ourselves
mapfile -t FILES < <(find /Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/DIY/PFC/1*_2*/spectrum.*.dir/ \
   -type f -name csi.ps -newermt "$newer")

# range
range=$(grep -Po '(?<=_)\d{8}' <<< "${FILES[*]}" | sort -u | sed -n '1p;$p'|paste -sd- )
nvisits=$(ld8 "${FILES[@]}"|sort -u|wc -l)

warn "# found ${#FILES[@]} csi.ps files newer than $newer ($range)"
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


finalout="pdf/csi_all-gt${newer}_n-${nvisits}_d8-${range}_slice-PFC_pg$pg.pdf"
echo "# combining to make $finalout"
test ! -d pdf && mkdir "$_"
gs -q -dSAFER -dBATCH -sDEVICE=pdfwrite -o "$finalout" "$tmpdir/bookmarks-pg$pg.ps" -f "$tmpdir/"*pg$pg.pdf
#gs -q -dSAFER -dBATCH -sDEVICE=pdfwrite -o pdf/hpc-$(date +%F)-pg$pg.pdf $tmpdir/bookmarks-pg$pg.ps -f $tmpdir/*pg$pg.pdf
echo "made $finalout"

rm -r "$tmpdir"
