#!/usr/bin/env bash
#
# 20230622WF - init
#
# run preprocessing without warping or smoothing
# '-no_smooth' so neighboring voxel correlation isn't inflated
#
# '-no_warp' means not spatially normalized to MNI 09c template via non-linear warp
# affine transform (alignment) to participants anatomical T1 weighted image (mp2rage) considered okay
# and makes using FreeSurfer's GM mask (or fsl's fast) easier
#
# actual instructions for preprocessing in pipeline file:
#   /opt/ni_tools/preproc_pipelines/pipes/MHRest_nost_nowarp_nosmooth
#
# writes files like
# /Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_nowarp_nosmooth/10129_20180917/Wbgrndkm_func.nii.gz
#   see Makefile and .make/preproc.ls

pp 7TBrainMech_rest MHRest_nost_nowarp_nosmooth


