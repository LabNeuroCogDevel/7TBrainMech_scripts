#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
# 20190911WF - init


comm -23 \
   <(ls /Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Alethia/Prep/filtered/|cut -f1-2 -d_)  \
   <(ls /Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Alethia/Prep/rejected_epochs|cut -f1-2 -d_)
