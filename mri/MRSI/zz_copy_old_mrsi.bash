find /Volumes/Hera/Raw/MRprojects/7TBrainMech/2*/{LCM/PFC/SI,SI}*/ -iname 'spreadsheet.csv'|
 while read f; do
    n=/Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/2018_to07/$(dirname ${f##*Mech/})
    newf="$n/$(basename $f)"
    [ -r $newf ] && echo "# have $newf" && continue
    [ ! -d $n ]  && mkdir -p $n
    cp $f $n
 done
