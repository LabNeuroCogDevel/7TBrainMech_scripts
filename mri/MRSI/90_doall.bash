#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
cd $(dirname $0)

#
# run all steps for Luna data
#

# run freesurfer
echo ../FS/001_toPSC.bash
echo ../FS/002_fromPSC.bash
./001_rsync_MRSI_from_box.bash  # not really rsync, but rclone
./01_get_slices.bash all
./02_label_csivox.bash all
./03_func_atlas.bash
