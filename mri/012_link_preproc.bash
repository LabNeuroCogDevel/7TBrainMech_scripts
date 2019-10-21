#!/usr/bin/env bash
set -e
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
SUBJROOT=/Volumes/Hera/Projects/7TBrainMech/subjs/

#
# link things done with preproces
#

for d in /Volumes/Zeus/preproc/7TBrainMech_*/*/*/; do
   [[ $d =~ 7TBrainMech_(rest|mgsencmem)/(MHTask_nost|MHRest_nost_ica|MHT1_2mm)/([0-9]{5}_[0-9]{8}) ]] || continue
   task=${BASH_REMATCH[1]}
   preproc=${BASH_REMATCH[2]}
   subj=${BASH_REMATCH[3]}

   subj_dir=$SUBJROOT/$subj/preproc
   [ ! -d $subj_dir ]  && mkdir -p $subj_dir

   # MHT1_2mm is the same in both, so skip mgsenc one
   case "$task+$preproc" in
      mgsencmem+MHT1_2mm) continue;;
      *MHT1_2mm) preproc_name=t1;;
      mgsencmem+*Task*) preproc_name=task;;
      rest+*Rest*) preproc_name=rest;;
      *) echo "dont know what to do with $task+$preproc ($d)";;
   esac

   out_name=$subj_dir/$preproc_name
   [ -r $out_name ] && continue

   ln -s $d $out_name
   
done
