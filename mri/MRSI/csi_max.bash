#!/usr/bin/env bash
set -e
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
# get max gaba 
#
cd $(dirname $0) # go to script dir
scriptdir=$(pwd)
echo -n > $scriptdir/txt/gaba.txt # clear file before for loop appends stuff


# for every good file
i=0;
for csifile in  /Volumes/Hera/Projects/7TBrainMech/subjs/*/slice_PFC/MRSI/all_csi.nii.gz; do
   # go to subject directory
   cd $(dirname $csifile)
   # extract luna_date (5 digits _ 8 digits)
   [[ $csifile =~ subjs/([0-9]{5}_[0-9]{8})/ ]] || continue
   ld=${BASH_REMATCH[1]}

   # switching names halfway through! D'oh. 
   # could be ..._inv or inv_....
   # figure out which one
   inv_=""; _inv=""
   3dinfo -label all_csi.nii.gz |grep inv_ >/dev/null && inv_="inv_" || _inv="_inv"

   # mask value
   3dcalc -overwrite -prefix /tmp/gaba_thres.nii.gz \
      -t "all_csi.nii.gz[${inv_}GABA_SD${_inv}.[0]]" \
      -a "all_csi.nii.gz[${inv_}Cre_SD${_inv}.n[0]]"  \
      -v "all_csi.nii.gz[GABA_Cre.nii[0]]" \
      -b "all_probs.nii.gz[MaxTissueProb]" \
      -expr 'step(t-.05)*step(a-.05)*step(b-0)*v '
      #-f "all_probs.nii.gz[FractionGM]" \

   # no header for anything other than first run
   let ++i;
   [ $i -gt 1 ] && nohdr="1d;" || nohdr="1,1s/^/Subj\t/;" 

   # get stats
   3dROIstats -zerofill 0 -numROI 14 -minmax -mask 'all_probs.nii.gz[ParcelCSIvoxel]' /tmp/gaba_thres.nii.gz | 
     sed "$nohdr 2,\$ s/^/$ld\t/" |tee -a $scriptdir/txt/gaba.txt
done

# read.table('gaba.txt',header=T) %>% select(matches('File|Max'))

