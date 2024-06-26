#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
cd $(dirname $0)

#
# 20200520WF - copy from ../MRSI_roi/gen_pdf.bash
#  make pdf from first page of csi.ps
#  searches in spectrum.xx.yy.dir within /Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/HPC/
#  saves to pdf/hpc_pg${pg}_${newer}_$(date +%F).pdf
# 20230201 
# prev run was pdf/hpc_pg1_2020-04-24_2020-05-20.pdf


# depends on manual unzip
# like 
#  cd /Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01
#  unzip -d HPC/ ProcessedHc_20200520_2019-Mar2020.zip

# 20230302 - major change
# using local spectrum/*/*.dir files
# and exclude any already in a pdf

pg=1 # first page of csi.ps has spectrum we want to QA/QC

tmpdir=$(mktemp -d /tmp/mrsi-pdfs-XXXX)
test -d $tmpdir || mkdir $_
  
old_find_mrrc_provided(){
  #newer=2020-04-24  # set 20200520
  newer=2020-05-20   # set 20230201
  hpcdirs='/Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/HPC/ProcessedHc*/20*/spectrum*/'
  find $hpcdirs -type f,l -name csi.ps -newerct $newer |
   while read -r f; do

    pos=$(echo $f|perl -lne 'print "$3-$2-$1" if /(\d+.\d+)\.([LR])\.(\d+)/')
    [ -z "$pos" ] && echo "# no region info in '$f'" >&2 && continue

    name=$(basename $(dirname $(dirname $f)))
    ld8=$(echo $f|perl -lne 'print $& if m:\d{8}Luna[^/]*:' |
       xargs -n1 -I{} grep -i {} ../MRSI/txt/ids.txt |
       cut -f 1 -d ' ' || echo "")
    [ -z "$ld8" ] && echo "# no ld8 using $name ('$f')" >&2 && ld8=$name
    out=$tmpdir/$ld8-$pos-pg$pg.pdf
    echo "$f $out"
done
}
find_local_without_pdf(){
   perl -lne 'print $1 if m/Title\(([^\)]+)/' pdf/hpc_*.pdf  > $tmpdir/prev_blist.txt

  hpcdirs='spectrum/20*/*.dir/'
  find $hpcdirs -type f,l -name csi.ps | while read f; do

    # new input like
    # spectrum.89.113.dir
    # prev output: 20191216LUNA1-2-R-71.112
    # new output:               --71.12
    pos=$(perl -lne 'print "-$1" if /(\d+.\d+).dir/' <<< "$f")
    [ -z "$pos" ] && echo "# no region info in '$f'" >&2 && continue

    # ld8 or 202YMMDDLunaN
    name=$(basename $(dirname $(dirname $f)))
    ld8=$(perl -lne 'print $& if m:\d{8}Luna[^/]*:' <<< "$f" |
       xargs -r -I{} grep -i {} ../MRSI/txt/ids.txt |
       cut -f 1 -d ' ' || echo "")

    # mutliple lunaids
    [ -n "$ld8" ] && [ ${#ld8} -gt 14 ] &&
       ld8="${ld8// /,}"
       warn "$name matche more than one ld8! '$ld8'" &&

    [ -z "$ld8" ] &&
       warn "# no ld8 using $name ('$f')" && ld8=$name
     title="$ld8-$pos"
     out=$tmpdir/$title-pg$pg.pdf
     title_regx="$ld8.*-${pos/-/}"
     verb -level 2 "# checking '$title_regx' in $tmpdir/prev_blist.txt" >&2
     grep -Pq "$title_regx" "$tmpdir/prev_blist.txt" &&
        verb "# have $title. skipping" >&2 && continue
     echo "$f $out"
  done
}

find_local_without_pdf | while read f out; do
  [ -r "$out" ] && continue
  echo "$out"
  dryrun gs -q -dSAFER -dBATCH -dFirstPage=$pg -dLastPage=$pg -sDEVICE=pdfwrite -o "$out" $f
done

[ -n "${DRYRUN:-}" ] && exit 0

# make bookmark file
ls $tmpdir/*-pg$pg.pdf |
 sed "s:.*/::;s:-pg$pg.pdf$::" |
 perl -lne 'print "[/Page ", ++$i, " /View [/XYZ null null null] /Title ($_) /OUT pdfmark"' > $tmpdir/bookmarks-pg$pg.ps

echo "combining"
[ ! -d pdf ] && mkdir $_
finalout=pdf/hpc_pg${pg}_$(date +%F).pdf
gs -q -dSAFER -dBATCH -sDEVICE=pdfwrite -o "$finalout" "$tmpdir/bookmarks-pg$pg.ps" -f "$tmpdir"/*pg$pg.pdf
echo made $finalout

rm -r "$tmpdir"
