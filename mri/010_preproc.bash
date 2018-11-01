#!/usr/bin/env bash
set -e
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
if [ $(whoami) != "lncd" ]; then
   sudo -u lncd $0
   exit
fi
export PATH="$PATH:/opt/ni_tools/preproc_pipelines:/opt/ni_tools/fmri_processing_scripts"

#
# preprocess using 'pp' preprocess pipeline
# /opt/ni_tools/preproc_pipelines/

# ln -s /Volumes/Zeus/preproc/7TBrainMech_rest/MHT1_2mm/ /Volumes/Zeus/preproc/7TBrainMech_mgsencmem/MHT1_2mm

pp 7TBrainMech_rest  MHRest_nost_ica
pp 7TBrainMech_mgsencmem  MHTask_nost
