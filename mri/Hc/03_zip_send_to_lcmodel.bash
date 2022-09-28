#!/usr/bin/env bash

# zip position-QC'ed spectrum files for VY to get LCModel output back
zip send_to_lcmodel/LunaHc_spectrum_20220701.zip -@ < <(
 for good in $(cat qc/good_2022-07-01.txt); do
    ls spectrum/$good/spectrum*[0-9]
 done)
