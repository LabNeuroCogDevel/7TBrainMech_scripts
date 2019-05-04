#!/usr/bin/env bash
set -e
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
# 20190503 - collect all outputs into one large sheet
#

[ ! -d txt ] && mkdir txt

# input zip created by victor, copied to rhea by ../001_rsync_MRSI_from_box.bash
inputzip=/Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/spectrum_out_processed.zip
unzip -l $inputzip|
 grep .csv$ |
 while read size date tm path; do
    # unzip -p puts the file in the path into stdout (for pipeing)
    # sed adds File as the last column of the first line
    # and the path we are printing to every other line
    unzip -p "$inputzip" "$path" |
    sed "1s/$/, File/; 2,\$s:$:, $path:;"
done | tee txt/csv_vals_20190503_repheader.csv | 
sed '1p;/^Row/d' > txt/csv_vals_20190503.csv

# headers are safe: only to versions, one liek ../Cr and the other ../Cre
#  37 Row, Col, Asp, Asp %SD, Asp/Cr , Cho, Cho %SD, Cho/Cr , Cre, Cre %SD, Cre/Cr , GABA, GABA %SD, GABA/Cr , Glc, Glc %SD, Glc/Cr , Gln, Gln %SD, Gln/Cr , Glu, Glu %SD, Glu/Cr , GPC, GPC %SD, GPC/Cr , GSH, GSH %SD, GSH/Cr , mI, mI %SD, mI/Cr , NAA, NAA %SD, NAA/Cr , NAAG, NAAG %SD, NAAG/Cr , Tau, Tau %SD, Tau/Cr , -CrCH2, -CrCH2 %SD, -CrCH2/Cr , GPC+Cho, GPC+Cho %SD, GPC+Cho/Cr , NAA+NAAG, NAA+NAAG %SD, NAA+NAAG/Cr , Glu+Gln, Glu+Gln %SD, Glu+Gln/Cr , MM20, MM20 %SD, MM20/Cr , File
# 693 Row, Col, Asp, Asp %SD, Asp/Cre, Cho, Cho %SD, Cho/Cre, Cre, Cre %SD, Cre/Cre, GABA, GABA %SD, GABA/Cre, Glc, Glc %SD, Glc/Cre, Gln, Gln %SD, Gln/Cre, Glu, Glu %SD, Glu/Cre, GPC, GPC %SD, GPC/Cre, GSH, GSH %SD, GSH/Cre, mI, mI %SD, mI/Cre, NAA, NAA %SD, NAA/Cre, NAAG, NAAG %SD, NAAG/Cre, Tau, Tau %SD, Tau/Cre, -CrCH2, -CrCH2 %SD, -CrCH2/Cre, GPC+Cho, GPC+Cho %SD, GPC+Cho/Cre, NAA+NAAG, NAA+NAAG %SD, NAA+NAAG/Cre, Glu+Gln, Glu+Gln %SD, Glu+Gln/Cre, MM20, MM20 %SD, MM20/Cre, File

for f in ../../../subjs/1*_2*/slice_PFC/MRSI_roi/raw/slice_roi_MPOR20190425_CM_*_16_*_*.txt; do
   sed "s:\$:  $(basename $f):" $f
done > txt/pos_20190425.txt
