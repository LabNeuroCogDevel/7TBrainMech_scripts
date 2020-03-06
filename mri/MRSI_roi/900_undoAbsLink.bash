#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
# make absolute links relative
#  20200305WF  init

stat -c "%N"  /Volumes/Hera/Projects/7TBrainMech/subjs/*/slice_PFC/MRSI_roi/raw/{seg.7,siarray.1.1,mprage_middle.mat,rorig.nii} |
   perl -slane '
    next if m:\.\./\.\.: or !$F[2];
    $F[2] =~ s:/Volumes/Hera/:../../../../../../../:;
    print "rm $F[0]; ln -s $F[2] $F[0];"' |
   bash -x -
