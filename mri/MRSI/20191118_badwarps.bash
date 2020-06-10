#!/usr/bin/env bash

# something is wrong with mprage_to_slice.mat -- maybe fls6 issue? maybe they have been accidentaly overwritten?
# see 01_get_slices.bash
# compute new warp and difference with current
# does NOT overwrite old

fsl6warpd="/Volumes/Hera/Projects/7TBrainMech/scripts/mri/txt/fsl6_mprage_to_slice/"

# searlizes 4x4 matrix to single long vector
unnset() { perl -slane 'print $_ for @F' $@; }

for d in /Volumes/Hera/Projects/7TBrainMech/subjs/*/slice_PFC; do
   [[ $d =~ [0-9]{5}_[0-9]{8} ]] || continue
   id="$BASH_REMATCH"
   echo $id $d >&2
   cd $d
   [ ! -r $fsl6warpd/${id}_mprage_to_slice.mat ] &&
     flirt -ref slice_pfc.nii.gz -in ppt1/mprage.nii.gz -o /tmp/${id}_mprage_in_slice.nii.gz -omat $fsl6warpd/${id}_mprage_to_slice.mat 
   echo $id $(paste <(unnset $fsl6warpd/${id}_mprage_to_slice.mat) <(unnset mprage_to_slice.mat ) | awk '{print $1-$2}'|datamash mean 1 sstdev 1)
done | tee $(dirname "$0")/txt/warp_diffs.txt

# head -n80 /Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI/txt/warp_diffs.txt | rio2 'p(d) + a(x=V2) + geom_histogram()'
