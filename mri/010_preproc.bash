#!/usr/bin/env bash
set -e
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
if [ $(whoami) != "lncd" ]; then
   sudo -u lncd $0
   exit
fi
source $HOME/.bashrc
#export PATH="$PATH:/opt/ni_tools/preproc_pipelines:/opt/ni_tools/fmri_processing_scripts"

#
# preprocess using 'pp' preprocess pipeline
# /opt/ni_tools/preproc_pipelines/
#   /opt/ni_tools/preproc_pipelines/sources/7TBrainMech_mgsencmem
#   /opt/ni_tools/preproc_pipelines/sources/7TBrainMech_rest
#   /opt/ni_tools/preproc_pipelines/pipes/MHTask_nost

# ln -s /Volumes/Zeus/preproc/7TBrainMech_rest/MHT1_2mm/ /Volumes/Zeus/preproc/7TBrainMech_mgsencmem/MHT1_2mm
# also  /Volumes/Zeus/preproc/7TBrainMech_rest/FS/ is SUBJECTS_DIR

export MAXJOBS=5 # pp should wait for all to finish. otherwise might end up with 2*MAXJOBS running when one finishs
pp 7TBrainMech_rest  MHT1_2mm all   # 20211025 - rest should pick this up, but not all w/T1 have rest
pp 7TBrainMech_rest  MHRest_nost all
pp 7TBrainMech_mgsencmem  MHTask_nost all
pp 7TBrainMech_mgsencmem  MHTask_nost_nowarp all
#pp 7TBrainMech_rest  MHRest_nost_ica # not sure why we dont like ica
