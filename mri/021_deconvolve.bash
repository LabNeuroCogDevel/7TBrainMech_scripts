#!/usr/bin/env bash

cd $(dirname $0)
SUBJDIR=$(cd ../../subjs/; pwd)
[[ ! $SUBJDIR =~ subjs$ ]] && echo "NO SUBJECT DIR?! ($SUBJDIR)" && exit 1
oned_dir=$(pwd)/1d/trial_hasimg_lr/

for predir in /Volumes/Hera/Projects/7TBrainMech/pipelines/MHTask_nost/1*_2*/; do
   [[ ! $predir =~ 1[0-9]{4}_2[0-9]{7} ]] && echo "no id in $predir" && continue
   ld8=$BASH_REMATCH

   # check we have 1d files
   ex1dfile=$oned_dir/${ld8}_img_Left.1d 
   [ ! -r $ex1dfile ] && echo "$ld8 ERROR: missing  1d files (no $ex1dfile)" && continue
   nb1d=$(wc -l < $ex1dfile)
   nbts=$(ls $predir/0[1-4]/nfswdkm_func_4.nii.gz |wc -l)

   [ $nb1d -ne $nbts ] && echo "$ld8 ERROR: have $nb1d block onsets for $nbts files"  && continue

   # TODO: motion

   # create subject directory and go there
   subj_task_dir=$SUBJDIR/$ld8/MGSEncMem
   [ ! -d $subj_task_dir ] && mkdir -p $subj_task_dir
   cd $subj_task_dir
   pwd
   # run
   echo 3dDeconvolve  \
    -prefix LR_img_deconvolve.nii.gz \
    -input $predir/0[1-4]/nfswdkm_func_4.nii.gz \
    -num_stimts 4 \
    -stim_times_AM1  1 $oned_dir/${ld8}_img_Left.1d 'dmBLOCK'\
    -stim_label 1 img_left \
    -stim_times_AM1  2 $oned_dir/${ld8}_img_Right.1d 'dmBLOCK'\
    -stim_label 2 img_right \
    -stim_times_AM1  3 $oned_dir/${ld8}_noimg_Left.1d 'dmBLOCK'\
    -stim_label 3 noimg_left \
    -stim_times_AM1  4 $oned_dir/${ld8}_noimg_Right.1d 'dmBLOCK'\
    -stim_label 4 noimg_right \
    -x1D X.xmat.1D
done
