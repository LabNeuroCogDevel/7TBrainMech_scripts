#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
# quick list of sessions without mrsi placements
#  20211025WF  init
#  different from './001_inspect_setup.bash list'
#     inspect_setup lists all 'raw' folders (exists)
#     needs_placement shows where '13MP20200207' does not exist
cd $(dirname $0)
for d in ../../../subjs/1*_2*/slice_PFC/; do
   ld8=$(ld8 "$d")
   [ -z "$ld8" ] && continue
   grep "^$ld8.*TODO" known_bad_visit.txt && continue
   grep -q "^$ld8" known_bad_visit.txt && continue
   [ ! -r "$d/MRSI_roi/13MP20200207" ] && echo "$ld8" || :;
done
