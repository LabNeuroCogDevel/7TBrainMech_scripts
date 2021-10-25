#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
# quick list of sessions without mrsi placements
#  20211025WF  init
cd $(dirname $0)
for d in ../../../subjs/1*_2*/slice_PFC/MRSI_roi/; do
   [ ! -r $d/13MP20200207 ] && ld8 $d;
done
