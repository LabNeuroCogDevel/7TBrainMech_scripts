#!/usr/bin/env bash
#
# 20200720WF - init
#  find (orma's) subjects that are still missing generated specturm files
#  and generate them
#  currently ony looking at files from after july 1 2020
# 20211103WF - find AG (undergrad anna).
#    write to tempfile instead of launching a bunch of matlabs
#    update to use lncd renamed matlab oneliner m->ml
WHO="OR"; WHEN=2020-07-01 # 20200720
WHO="NW"; WHEN=2020-10-01 # 20220118 # previously missing, back in time to catch
WHO="AG"; WHEN=2021-10-01 # 20211103
WHO="AO"; WHEN=2022-11-01 # 20221201

mkspecdir=$(cd $(dirname $0);pwd)
tmp_ml=$(mktemp /tmp/genspecXXXX.m)
trap "test -r $tmp_ml && rm $tmp_ml" EXIT

echo "addpath('/opt/ni_tools/MRSIcoord.py/matlab');" > $tmp_ml
find /Volumes/Hera/Projects/7TBrainMech/subjs/*/slice_PFC/MRSI_roi/13MP20200207/$WHO/ \
   -maxdepth 1 -newermt $WHEN -type d|
 while read d; do
  test 0 -ne $(ls $d/spectrum* 2>/dev/null| wc -l) &&
     echo "# have $d $_" >&2 &&
     continue
  test ! -r $d/sid3_picked_coords.txt  && echo "missing $_" >&2 && continue
  echo "cd('$mkspecdir'); mkspec_indir('$d');"
done  >> $tmp_ml

if [ -n "$DRYRUN" ]; then
   echo "# $tmp_ml"
   wc -l < $tmp_ml
   cat $tmp_ml
else
   ml $tmp_ml
fi
