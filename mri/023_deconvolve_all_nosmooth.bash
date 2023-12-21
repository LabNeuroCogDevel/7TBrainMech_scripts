#!/usr/bin/env bash
#
# 20221212WF - run all 021[a-z]*bash files
#

# makes ../../subjs/$ld8/MGSEncMem/{mni,nowarp}/${ld8}*_errts.nii.gz
./023a_deconvolve_block_nosmooth.bash all
./023b_deconvolve_tent_nosmooth.bash all
