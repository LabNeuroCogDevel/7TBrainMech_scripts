#!/usr/bin/env bash
set -e
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
# 20190503 - collect all outputs into one large sheet
#    ZIPS=(/Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/spectrum_out_processed.zip  /Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/20190507processed.zip)
#    for f in ../../../subjs/1*_2*/slice_PFC/MRSI_roi/raw/slice_roi_MPOR20190425_CM_*_16_*_*.txt; do
#       sed "s:\$:  $(basename $f):" $f
#    done
#
#   HEADERS: only two versions: one like ../Cr and the other ../Cre
#    37 Row, Col, Asp, Asp %SD, Asp/Cr , Cho, Cho %SD, Cho/Cr , ...
#   693 Row, Col, Asp, Asp %SD, Asp/Cre, Cho, Cho %SD, Cho/Cre, ...
#
# 20191102 - use 24 roi 
#   coords are in newest
#    mni_examples/warps/1*_2*/*_scout_cm_737720.599140_10173_20180802_MP_for_mni.txt/coords_rearranged.txt; do
#   HEADERS:
#   1721 Row, Col, Asp, Asp %SD, Asp/Cre, Cho, Cho %SD, Cho/Cre, Cre, Cre %SD, ....


[ ! -d txt ] && mkdir txt

# input zip created by victor, copied to rhea by ../001_rsync_MRSI_from_box.bash
#ZIPS=(/Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/spectrum_out_processed.zip  /Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/20190507processed.zip)
ZIPS=(/Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/20191127_24specs_done.zip)
version=24specs_20191102
for inputzip in ${ZIPS[@]}; do
   echo $inputzip >&2
   unzip -l $inputzip|
    grep .csv$ |
    while read size date tm path; do
       # unzip -p puts the file in the path into stdout (for pipeing)
       # sed adds File as the last column of the first line
       # and the path we are printing to every other line
       unzip -p "$inputzip" "$path" |
       sed "1s/$/, File/; 2,\$s:$:, $path:;"
   done
done| tee txt/LCModel_vals_${version}_repheader.csv | 
sed '1p;/^Row/d' > txt/LCModel_vals_${version}.csv

# show headers
echo "headers in txt/LCModel_vals_${version}_repheader.csv"
grep Row txt/LCModel_vals_${version}_repheader.csv | sed 's:/Cr,:/Cre,:g' | sort |uniq -c

# headers are safe.
#    1721 Row, Col, Asp, Asp %SD, Asp/Cre, Cho, Cho %SD, Cho/Cre, Cre, Cre %SD, Cre/Cre, GABA, GABA %SD, GABA/Cre, Glc, Glc %SD, Glc/Cre, Gln, Gln %SD, Gln/Cre, Glu, Glu %SD, Glu/Cre, GPC, GPC %SD, GPC/Cre, GSH, GSH %SD, GSH/Cre, mI, mI %SD, mI/Cre, NAA, NAA %SD, NAA/Cre, NAAG, NAAG %SD, NAAG/Cre, Tau, Tau %SD, Tau/Cre, -CrCH2, -CrCH2 %SD, -CrCH2/Cre, GPC+Cho, GPC+Cho %SD, GPC+Cho/Cre, NAA+NAAG, NAA+NAAG %SD, NAA+NAAG/Cre, Glu+Gln, Glu+Gln %SD, Glu+Gln/Cre, MM20, MM20 %SD, MM20/Cre, File

# Previously had most recent already saved.
#    for f in ../../../subjs/1*_2*/slice_PFC/MRSI_roi/raw/slice_roi_MPOR20190425_CM_*_16_*_*.txt; do
# Newer was hand picked picked by maria. But choosen file should be the most recent
stat -c "%y"$'\t'"%n" $(pwd)/mni_examples/warps/1*_2*/*.txt/coords_rearranged.txt \
   | sort -n \
   | perl -F'\t' -salne '$a{$&}=$F[1] if /\d{5}_\d{8}/; END{print "$a{$_}\t$_" for keys %a}' \
   | while read f ld8; do
       sed "s:\$: $ld8 $f:" $f
    done> txt/pos_$version.txt
