#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
cd $(dirname $0)

#
# run all steps for Luna data
#
# 20200309 - add NOCSV and remove func_atlas -- only running depends for MRSI_roi

# run freesurfer
echo "NOT RUNNING update functions (run by hand)"
echo ../FS/001_toPSC.bash
echo ../FS/002_fromPSC.bash
echo ../001_rsync_MRSI_from_box.bash  # not really rsync, but rclone
./01_get_slices.bash all
NOCSV=1 ./02_label_csivox.bash all
# ./03_func_atlas.bash
