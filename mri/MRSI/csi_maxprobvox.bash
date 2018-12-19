#!/usr/bin/env bash
set -e
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
# get max gaba 
#
cd $(dirname $0) # go to script dir
scriptdir=$(pwd)
outfile=$scriptdir/txt/roi_at_best_voxel.txt
getlabel(){ 3dinfo -label all_csi.nii.gz |tr \| '\n' |grep $1; }


echo -e "Subj\troi\tnvox\tmaxprob\tfractionGM\tvx_in_thres\tmeasure\tvalue" | tee $outfile

# for every good file
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
   cre_only="all_csi.nii.gz[$(getlabel Cre_SD)]"

   for measure in GABA Glu; do
      ratio_brik="all_csi.nii.gz[$(getlabel ${measure}_Cre)]"
      crlb_brik="all_csi.nii.gz[$(getlabel ${measure}_SD)]"
      # mask based on 
      3dcalc -overwrite -prefix /tmp/gaba_thres.nii.gz \
         -t "$crlb_brik" \
         -a "$cre_only"  \
         -v "$ratio_brik" \
         -b "all_probs.nii.gz[MaxTissueProb]" \
         -expr 'step(t-.05)*step(a-.05)*step(b-0.25)*v '

      for roi in AGM BGA BS CACGM CSFP FGM IGM OGM PGM PICGM RACGM SCGM THA TLGM TMGM; do
         echo "# $ld $measure $roi"
         # find best in roi
         roi_brick="all_probs.nii.gz[$roi]"
         maxval=$(3dBrickStat -max $roi_brick)

         # make voxel mask
         voxmask=/tmp/vox_mask_$roi.nii.gz
         3dcalc  -overwrite -prefix $voxmask \
            -r $roi_brick -expr "step(.01-abs(r-$maxval))"

         # get metrics
         nvox=$(3dBrickStat -non-zero -count $voxmask)
         FractionGM=$(3dBrickStat -mask $voxmask -non-zero -mean "all_probs.nii.gz[FractionGM]")
         vox_in_thres=$(3dBrickStat -mask $voxmask -non-zero -count /tmp/gaba_thres.nii.gz)
         val=$(3dBrickStat -mask $voxmask -non-zero -mean "$ratio_brik")
         # echo it
         echo -e "$ld\t$roi\t$nvox\t$maxval\t$FractionGM\t$vox_in_thres\t$measure\t$val" |tee -a $outfile
      done
   done
done

