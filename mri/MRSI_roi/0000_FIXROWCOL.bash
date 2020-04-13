for f in /Volumes/Hera/Projects/7TBrainMech/subjs/1*_2*/slice_PFC/MRSI_roi/LCModel/v1/13MP20200207_picked_coords.txt; do
   ld8=$(ld8 $f)
   siarray="/Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/MRSI_roi/raw/siarray.1.1"
   [ ! -r $siarray ] && echo "$ld8: no $siarray" && continue
   newdir=/Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/MRSI_roi/raw-v2idxfix
   echo $newdir
   test ! -d $newdir &&  mkdir $_
   test ! -r $newdir/coords_from && ln -s "$(dirname $(readlink -f "$f"))"  $_
   test ! -r $newdir/siarray.1.1 && ln -s "$(readlink -f $siarray)" $_
   out=$newdir/row_col.txt
   awk '{print 216-$2+1, 216-$1+2}' < $f > $out
   echo -e "\n%%$ld8\npos=load('$out');\ngen_spectrum('$siarray',216,pos,'$newdir');" > $newdir/gen.m
done


echo "addpath('/opt/ni_tools/MRSIcoord.py/matlab')" > mkall_spectrums.m
cat /Volumes/Hera/Projects/7TBrainMech/subjs/*/slice_PFC/MRSI_roi/raw-v2idxfix/gen.m >> mkall_spectrums.m
