#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

# set verbose if not in environment
env |grep -q '^VERBOSE=' || VERBOSE=""
# ONLYID to tust just one luna_date
env |grep -q '^ONLYID=' || ONLYID=""
env |grep -q '^DRYRUN=' || DRYRUN=""
[ -n "$DRYRUN" ] && DRYRUN="echo"

# CHANGE ME
#unzipfolder="/Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/20200224_13specs_processed/"
#unzipfolder="/Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/20200311_13specs_processed/"
unzipfolder="/Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/2020*processed/"
atlas=13MP20200207
#
# copy LCmodel output to subject MRSI_roi directory (MRSI_roi/LCModel/v1)
# prereq:
#  - position rois ./coord_builder.bash build rois
#  - generate spectrum ./020_mkspectrum_ifftgui.bash
#  - sent to victor ./030_send_files_13.bash
#  - rsync pulled nightly and unziped (e.g. /Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/20200224_13specs_processed.zip)
#  20200310WF  init

# subject root directory
S="/Volumes/Hera/Projects/7TBrainMech/subjs/"

showkeep(){
   # give me spectrum dir and picked.txt
   local d="$1";shift
   local c="$1";shift
   # diff spec folders and expected coords
   # show only similiar
   # -- why not use `comm -12` ?
   diff -y \
      <(ls $d | sed 's:spectrum.::;s:.dir::'|tr . ' ' |sort) \
      <(awk '{print 216+1-$3,216+1-$2}' $c|sort)  |
      egrep -v '[|<>]' | awk '{print "spectrum."$1"."$2".dir"}' || : 
}

for d in $unzipfolder/*/; do
   ld8=$(ld8 "$d")
   # where to put things
   M=$S/$ld8/slice_PFC/MRSI_roi/LCModel/v2idxfix

   [ -z "$ld8" ] && echo "ERROR: no lunadate in $d" && continue
   [ -n "$ONLYID" -a "$ONLYID" != "$ld8" ] && continue
   o=$S/$ld8/slice_PFC/MRSI_roi/$atlas
   [ ! -d $o ] && echo "ERROR: no out dir $o for $d" && continue
   cs=($(find $o/ \
      -mindepth 2 -maxdepth 2 \
      -iname picked_coords.txt \
      -not -ipath  '*/WF*' \
      -exec stat -c "%Y %n" {} \+ |
      while read t f; do
         echo $(showkeep $d $f|wc -l):::$t:::$f;
      done|sort -nr))
   # \( -ipath '*/MP/*' -or -ipath '*/JJ/*' -or -ipath '*/LT/*' -or -ipath '*/OR/*' \) \
   [ -z "$cs" ] && echo "ERROR: no $o/*/picked_coords.txt" && continue
   ncs=${#cs[@]}; neq13=$(for x in ${cs[@]}; do echo ${x/:::*}; done|grep 13 -c)
   [ $neq13 -ne 1 ] && echo "WARNING: have $ncs coord files ($neq13 w/13): ${cs[@]}"
   c=${cs[0]}; c=${c/*:::/} # remove timestamp
   

   keep=($(showkeep "$d" "$c"))

   # if we want to see whats going on
   [ -n "$VERBOSE" ] && echo "# $ld8 found ${#keep[@]} matching $c"

   # show difference
   if [ ${#keep[@]} -ne $(wc -l < $c) ]; then
      echo "WARNING: $ld8 have ${#keep[@]}/$(ls $d|wc -l) match $(wc -l < $c) (using $c in $M); see ./check_speccoord $ld8" 
    diff -y --suppress-common-lines -W 25 \
       <(ls $d | sed 's:spectrum.::;s:.dir::'|tr . ' ' |sort) \
       <(awk '{print $3,$2}' $c|sort)  | sed 's/^/\t/' || :
    
   fi

   # nothing to copy? do nothing
   [ ${#keep[@]} -eq 0 ] && continue

   # copy
   test ! -r $M && $DRYRUN mkdir -p $_
   test ! -r $M/${atlas}_picked_coords.txt && $DRYRUN ln -s $c $_
   for kd in ${keep[@]}; do
      [ -r $M/$kd/spreadsheet.csv ] && continue
      echo "copying to $M/$kd"
      $DRYRUN rsync -ravhi --size-only $d/$kd $M/
   done

   [ -n "$DRYRUN" ] && continue

   test ${#keep[@]} -ne $(find $M -iname 'spreadsheet.csv'|wc -l) && 
      echo "ERROR: $ld8 has $_ instead of expected ${#keep[@]} in $M (see $d)" || :
  
done
