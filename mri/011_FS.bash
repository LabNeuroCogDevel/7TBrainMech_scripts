#!/usr/bin/env bash
set -e
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
# Run Freesurfer on all -- use tmux
#

SUBJECTS_DIR="/Volumes/Hera/Projects/7TBrainMech/subjs/FS"

# TODO: maybe this should be part of /opt/ni_tools/preproc_pipelines/
# can use the same source as pp to get SUBJECTS DIR?
