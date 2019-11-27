#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
# organize files to send to victor
# copy of 030_send_files.bash, but for newer 24 roi
# makes e.g. 
#  14M	spectrum_out/20191127_24specs.zip
#
# 20191127 - copy from 030_send_files.bash, base on time instead of lunaid

newer=20191100 # files should be newer than 8 digit date
nspecfiles=24  # number of coords
version=20191127 # outputfoldername version
[[ $# -eq 0 || "$1" =~ help|-h ]] && echo "change hardcoded date in $0; change output name maybe" && exit 1

root_out=spectrum_out/${version}_${nspecfiles}specs
[ ! -d $root_out ] && mkdir -p $root_out

subj_root=$(cd $(pwd)/../../../subjs/; pwd)
find $subj_root/*/slice_PFC/MRSI_roi/raw/ -iname '*spectrum.[0-9]*' -exec stat -c "%y %n" {} \+ |
   # eg 2019-11-26 17:03:31.155522625 -0500 /Volumes/Hera/Projects/7TBrainMech/subjs/11752_20190315/slice_PFC/MRSI_roi/raw/spectrum.100.121
   sed 's/-//;s/-//' | # 2019-11-21 -> 20191121
   # extract lunaid from path when first column (date) is newer than 8 digit "$newer" value
   perl -slane 'next unless m:(/.*(\d{5}_\d{8}).*):; print "$2 $1 $F[0]" if $F[0] > '"$newer" |
while read ld8 f d; do
   ld8mr=$(grep $ld8 ../MRSI/txt/ids.txt |sed 's/ /-/;1q') # could maybe have done this with 'join'
   [ -z "$ld8mr" ] && echo "unknown MRID for $ld8 " && continue
   outdir="$root_out/$ld8mr"
   [ ! -d $outdir ] && mkdir $outdir
   [ ! -r $root_out/$ld8mr/$(basename $f) ] && ln -s $f $outdir/ # && echo $f 
   continue
done

zip -r $root_out.zip $root_out

#check
for d in $root_out/1*/; do
   n=$( find $d -type l |wc -l )
   [ $n -ne $nspecfiles ] && echo "$outdir has $n (not $nspecfiles) files"
done

