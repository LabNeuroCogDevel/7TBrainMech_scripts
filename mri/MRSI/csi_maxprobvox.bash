#!/usr/bin/env bash
set -e
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
# get max gaba 
#
TISSUE_PROB=0.25 # min value to be considerid tissue (all_prob.nii.gz)
ROI_PROB=0.1  # min value to be consider part of roi (all_prob.nii.gz)
CRLB_THRES=.1  # invertted (for afni thresholding)
# .1 => 10 == bad
#.05 => 20 == the worst
METRIC=median # median, mean, max (passed to 3dBrickStat)

cd $(dirname $0) # go to script dir
scriptdir=$(pwd)
outfile=$scriptdir/txt/roi-crlb_${CRLB_THRES}-tissue_${TISSUE_PROB}-roi_${ROI_PROB}_$METRIC.txt
getlabel(){ 3dinfo -label all_csi.nii.gz |tr \| '\n' |grep $1; }


echo -e "Subj\troi\tnvox\tmaxprob\tfractionGM\tvx_in_thres\tmeasure\tmaxvox_mean\tmaxvox_crlb\tgm_roi\tallvox_mean" | tee $outfile

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
      3dcalc -overwrite -prefix /tmp/thres.nii.gz \
         -t "$crlb_brik" \
         -a "$cre_only"  \
         -v "$ratio_brik" \
         -b "all_probs.nii.gz[MaxTissueProb]" \
         -expr "step(t-$CRLB_THRES)*step(a-$CRLB_THRES)*step(b-$TISSUE_PROB)*v "

      for roi in AGM BGA BS CACGM CSFP FGM IGM OGM PGM PICGM RACGM SCGM THA TLGM TMGM; do
         echo "# $ld $measure $roi"
         # find best in roi
         roi_brick="all_probs.nii.gz[$roi]"
         maxval=$(3dBrickStat -max $roi_brick)

         # make voxel mask
         voxmask=/tmp/vox_mask_$roi.nii.gz
         3dcalc  -overwrite -prefix $voxmask \
            -r $roi_brick -expr "step(.01-abs(r-$maxval))"

         3dcalc -overwrite -prefix /tmp/roi_mask.nii.gz \
            -r $roi_brick -expr "step(r-$ROI_PROB)"

         # get metrics
         nvox=$(3dBrickStat -non-zero -count $voxmask)
         FractionGM=$(3dBrickStat -mask $voxmask -non-zero -mean "all_probs.nii.gz[FractionGM]")
         vox_in_thres=$(3dBrickStat -mask $voxmask -non-zero -count /tmp/thres.nii.gz)
         val=$(3dBrickStat -mask $voxmask -non-zero -mean "$ratio_brik")
         val_crlb=$(3dBrickStat -mask $voxmask -non-zero -mean "$crlb_brik" || echo -nan)

         GM_roi=$(3dBrickStat -mask /tmp/roi_mask.nii.gz -non-zero -mean "all_probs.nii.gz[FractionGM]"||echo -nan)
         mean=$( (3dBrickStat -mask /tmp/roi_mask.nii.gz  -non-zero -$METRIC /tmp/thres.nii.gz||echo -nan)|awk '{print $NF}'  )
         # echo it
         echo -e "$ld\t$roi\t$nvox\t$maxval\t$FractionGM\t$vox_in_thres\t$measure\t$val\t$val_crlb\t$GM_roi\t$mean" |tee -a $outfile
      done
   done
done

