#!/usr/bin/env bash
#
# create /Volumes/Hera/preproc/7TBrainMech_rest/FS7.2/*/1*_2*/mri/gmmask.nii.gz
# uses Makefile. documenting in script too
#
# 20230622WF - init
#
make -kj 10 gmmasks_res
