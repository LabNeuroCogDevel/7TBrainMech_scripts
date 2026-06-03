#!/usr/bin/env bash
#
# rescue missing siarray links for spectrum subjects
# leaves original script untouched (01_reorg_mrsi_data_links.sh)
#
# 20260402DW 

rawdir=/Volumes/Hera/Raw/MRprojects/7TBrainMech
outdir=$(pwd)/spectrum

for subjdir in "$outdir"/20*Luna*; do
    [ ! -d "$subjdir" ] && continue

    id=$(basename "$subjdir")

    # find raw mrsi data
    siarray=""
    if [ ! -e "$subjdir/siarray.1.1" ]; then
        siarray=$(find -L "$rawdir" \
            -path "*$id*" \
            -iname 'siarray.1.1' \
            2>/dev/null | head -n 1)

        if [ -n "$siarray" ]; then
            echo "Found siarray for $id: $siarray"
            ln -s "$siarray" "$subjdir/siarray.1.1"
        else
            echo "Missing siarray for $id: potentially not a HPC visit"
        fi
    fi

    # find other files
    center=""
    if [ ! -e "$subjdir/recr.1.0.1.1.7" ] || \
       [ ! -e "$subjdir/seg.7" ] || \
       [ ! -e "$subjdir/anat.mat" ]; then

        center=$(find -L "$rawdir" \
            -path "*$id*" \
            \( -iname '1[56789]_7_FlipLR.MPRAGE' -o \
               -iname '*_7_FlipLR.MPRAGE' -o \
               -iname '*_7_FlipLR.MPRAGE.*' \) \
            2>/dev/null | head -n 1)

        if [ -n "$center" ]; then
            echo "Found for $id: $center"

            [ ! -e "$subjdir/recr.1.0.1.1.7" ] && ln -s "$center" "$subjdir/recr.1.0.1.1.7"
            [ ! -e "$subjdir/seg.7" ]          && ln -s "$center" "$subjdir/seg.7"
            [ ! -e "$subjdir/anat.mat" ]       && ln -s "$center" "$subjdir/anat.mat"
        else
            echo "Missing necessary files (anat.mat, seg.7, & recr) for $id"
        fi
    fi
done