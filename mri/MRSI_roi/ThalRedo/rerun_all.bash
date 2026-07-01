#!/usr/bin/env bash
export MAXJOBS=20
for d in ../../../../subjs/*/slice_PFC/MRSI_roi/ThalRedo/; do
   dryrun ./gm_cnt_at_mprage.bash "$d" &
   waitforjobs
done
wait
