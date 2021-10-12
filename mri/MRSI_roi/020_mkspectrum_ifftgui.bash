#!/usr/bin/env bash
set -e
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
cd $(dirname $0)

# launch matlab with CSI GUI from MRRC on a given subject
#
# 20190416 - init
#    \matlab -nodesktop -nosplash -r "try, [f, coords] = siarray_ifft_gui('$lunaid'); catch e,disp(e); quit; end; uiwait(f); quit();"
# 20211012 - changed w/new ROIs (13) need to launch gui twice
#
[ $# -lt 1 ] && echo "USAGE: $0 luna_date [interactive]" && exit 1
lunaid=$1

if [ $# -eq 1 ] ; then
   files=(/Volumes/Hera/Projects/7TBrainMech/subjs/$lunaid/slice_PFC/MRSI_roi/13MP20200207/*/coords_rearranged.txt)
   test ! -r ${files[0]} && echo "missing file like $_; did you already place rois for $lunaid?" && exit 1
   [ ${#files[@]} -eq 1 ] && coord_file=", '$files'" || coord_file=""

   cat<<HERE
   RUNNING:
   matlab -nodesktop -nosplash 
       f = mkspectrum('$1')
       [f, coords, coord_file] = mkspectrum_roi(f, 0 $coord_file)
       [f, coords, coord_file] = mkspectrum_roi(f, 12,coord_file)

   COORD FILES:
     ${files[@]}
HERE

   \matlab -nodesktop -nosplash -r "try, f = mkspectrum('$1'); [f, coords, coord_file]=mkspectrum_roi(f, 0 $coord_file); disp('HIT ENTER for next');input('');[f, coords, coord_file]=mkspectrum_roi(f, 12, coord_file); catch e,disp(e); quit; end; uiwait(f); quit();"
else
   echo "currently only handle 1 ID"

   # \matlab -nodesktop -nosplash -r "[f, coords] = siarray_ifft_gui('$1')"
fi
