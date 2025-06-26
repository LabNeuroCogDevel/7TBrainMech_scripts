#!/usr/bin/env bash
#
# old files links do not work!?
#
# 20250109WF - init
#
#
i=0

find spectrum/2*/{siarray.1.1,anat.mat} \
   -xtype l  \( -iname 'anat.mat' -or -iname 'siarray.1.1' \)  -printf "%p %l\n"|
 while read -r p l; do
  ((++i))
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

  [ -n "${VERBOSE:-}" ] && echo "# $p $l '$new' # $i $(date)"
  if ! [ -r "$new" ]; then
     warn "# missing '$p', '$patt' does not exist. original '$l'" 
     continue
  fi
  dryrun ln -sf "$new" "$p"
done | tee -a txt/fixlinks.log
