#!/usr/bin/env bash
set -e
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
# get MRSI from box
# requires `rclone configure` and setting 'box' to bea's account
#

# where box is setup
[ $(whoami) != "foranw" ] && echo "run as foranw, where rclone 'box' is setup" && exit 1

rclone copy -L box:MRSI_BrainMechR01 /Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01
