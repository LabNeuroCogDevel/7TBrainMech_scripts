#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
# wrapper around runme.m
#  20190917WF  init

matlab -nodesktop -nosplash -r "try, parpool(8); run('runall.m'); catch, end; quit()"


