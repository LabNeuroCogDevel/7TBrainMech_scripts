#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
# run all the things that dont need interaction
#  20211011WF  init
# this is here to remind me to use 'make' :)

#./0001_get_slices.bash all
#DISPLAY= NOCSV=1 ../MRSI/02_label_csivox.bash ALL
cd $(dirname 0)
make

