#!/usr/bin/env bash

for f in /Volumes/Hera/Projects/7TBrainMech/subjs/*/slice_PFC/MRSI_roi/raw/siarray.1.1; do
  echo $(ld8 $f) $(readlink -f $f) $f
done | sort -t_ -k2,2n

