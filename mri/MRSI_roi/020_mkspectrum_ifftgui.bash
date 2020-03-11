#!/usr/bin/env bash
set -e
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
cd $(dirname $0)

# launch matlab with CSI GUI from MRRC on a given subject
#
# 20190416 - init
#
[ $# -lt 1 ] && echo "USAGE: $0 luna_date [interactive]" && exit 1

if [ $# -eq 1 ] ; then
   \matlab -nodesktop -nosplash -r "try, [f, coords] = siarray_ifft_gui('$1'); catch e,disp(e); quit; end; uiwait(f); quit();"
else
   \matlab -nodesktop -nosplash -r "[f, coords] = siarray_ifft_gui('$1')"
fi
