#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
# 
#
cd $(dirname $0)
sshpass -f mesonpass.txt ssh 7t 'ls -dtlc 7t/*/ |head'
