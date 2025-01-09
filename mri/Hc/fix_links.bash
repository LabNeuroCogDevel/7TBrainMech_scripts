#!/usr/bin/env bash
#
# old files links do not work!?
#
# 20250109WF - init
#
#

find spectrum/2*/anat.mat \
   -xtype l  -iname 'anat.mat' -printf "%p %l\n"|
 while read -r p l; do
  new=$(sed -E 's:/7TBrainMech/2[0-9]+/:/7TBrainMech/duplicate-folders-collected-20240328/:' <<< "${l}")
  # /Volumes/Hera/Raw/MRprojects/7TBrainMech/duplicate-folders-collected-20240328/20180913Luna1-fromHCCollection
  if ! [ -r "$new" ]; then
     patt=$(sed -E 's:/HCCollection/(2[0-9]+[^/]+):/duplicate-folders-collected-20240328/\1-fromHCCollection:' <<< "${l}")
     new=$(ls $patt 2>/dev/null | sed 1q || : )
  fi
  if ! [ -r "$new" ]; then
     patt=$(sed -E 's:7TBrainMech/2[0-9]+/(2[0-9]+[^/]+):7TBrainMech/duplicate-folders-collected-20240328/\1-from*:' <<< "${l}")
     new=$(ls $patt 2>/dev/null | sed 1q || : )
  fi
  if ! [ -r "$new" ]; then
     warn "# missing '$p', '$patt' does not exist. original '$l'" 
     continue
  fi
  dryrun ln -sf "$new" "$p"
done
