#!/usr/bin/env bash
set -e
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
cd $(dirname $0)

# launch matlab with gui to move rois
#
# 20190429 - init
#
[ $# -lt 1 ] && echo "USAGE: $0 luna_date [interactive]" && exit 1

cmd="[f, coords] = coord_mover('$1')"
if [ $# -eq 1 ] ; then
   \matlab -nodesktop -nosplash -r "try, $cmd; catch e,disp(e); quit; end; uiwait(f); quit();"
else
   \matlab -nodesktop -nosplash -r "$cmd"
fi
