#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
# run all steps for FF data
#

# run freesurfer
/Volumes/Hera/Projects/Collab/7TFF/scripts/030_FS.bash
./01_get_slices.bash STUDY=FF all
./02_label_csivox.bash STUDY=FF all
./03_func_atlas.bash FF
