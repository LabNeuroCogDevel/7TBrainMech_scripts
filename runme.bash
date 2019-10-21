#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
cd $(dirname $0)

#
# run all things 
#

eeg/00_raw_from_box.bash
mri/001_rsync_MRSI_from_box.bash
mri/001_dcm2bids.bash
mri/010_preproc.bash
mri/012_link_preproc.bash
mri/MRSI/90_doall.bash
