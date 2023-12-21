#!/usr/bin/env bash
#
# model MGS task with dmblock
#
# may need new 1d files. see 020_task_onsets.R and output name
# see 'CHANGE ME' comments
# 20221212WF - copy of 021a_deconvolve_block.bash but intended to model with dmblock instead of block

# dryrun, iffmain defined in /opt/ni_tools/lncdtools/ (should be in path)
source decon_functions.bash # decon_all_nost concat_indir fd_censor list_inputs
FD_THRES=0.5 # how much motion is acceptable?

decon_one_dmblock(){
   # remove this line to actually run. search CHANGE ME in this file
   # see 'DRYRUN=1 ./023b_deconvolve_dmblock_nosmooth.bash /Volumes/Hera/Projects/7TBrainMech/pipelines/MHTask_nost/10173_20180802/' to test

   # GLOBAL: likely set by 'decon_all_nosmooth'
   [[ ! "$SUBJDIR" =~ subjs/?$ ]] && echo "NO SUBJECT DIR?! ('$SUBJDIR')" && return 1

   local predir="$1"; shift
   # id should be in folder name. Extract and store
   [[ ! $predir =~ 1[0-9]{4}_2[0-9]{7} ]] && echo "no id in $predir" && return
   ld8="${BASH_REMATCH[0]}"

   # 20230105: add W prefix. mprage aligned functions from 011_nowarp_to_t1.bash
   mapfile -t inputs4d < <(list_inputs "$predir/0[1-4]")

   # check we have 1d files for each run and have at least 1 4d file
   # (1d file has as many rows as number 4d files)
   # CHANGE ME
   local oned_dir_bydur=/Volumes/Hera/Projects/7TBrainMech/scripts/mri/1d/trial_hasimg_lr/
   local oned_dir_single=/Volumes/Hera/Projects/7TBrainMech/scripts/mri/1d_onsetOnly/trial_hasimg_lr/
   ex1dfile=${oned_dir_bydur}/${ld8}_img_Left_dly.1d
   check_inputs "$ex1dfile" "${inputs4d[@]}" || return

   # create subject directory and go there
   decon_dir="$(decon_dir "${inputs4d[0]}")"
   subj_task_dir=$SUBJDIR/$ld8/${decon_dir:-MGSEncMem/unknown} # want sub-dir for tent? CHANGE ME
   [ ! -d "$subj_task_dir" ] && mkdir -p "$subj_task_dir"
   cd "$subj_task_dir"

   
   # 20230105 use regressors and not motion. still  creating motion file, but not used in decon
   # use reg_names to put what preprocessfunctional thinks is in regerssors into output files history (3dNotes)
   mot_concat=$(concat_indir ./all_motion.par motion.par      "${inputs4d[@]}") || return
   reg_concat=$(concat_indir ./all_nuisance_regs.txt  nuisance_regressors.txt     "${inputs4d[@]}") || return
   test ! -s all_nuisance_regs.txt && warn "$ld8 ERROR: '$_' empty" && return 1

   reg_names=$(regressors_in_use "${inputs4d[@]}")

   fd_concat=$(concat_indir ./all_fd.txt motion_info/fd.txt "${inputs4d[@]}") || return
   fd_censor_file=$(fd_censor "$fd_concat" "$FD_THRES") || return

   # check if we have an output
   outfile=${ld8}_lrimg_nuis_deconvolve_dmblock_nosmooth.nii.gz
   [ -r ${outfile} -a -z "${REDO:-}" ] &&
      echo "Output file ($(pwd)/${outfile}) exists, SKIPPING" && return

   # show what we're working on
   pwd

   tr=$(lookup_tr "$ld8")
   check_tr "$tr" || return

   # 'dryrun' echos if $DRYRUN set, otherwise actually runs
#1d/trial_hasimg_lr/11867_20210424_img_Left_cue.1d
   dryrun 3dDeconvolve  \
    -force_TR "$tr" \
    -overwrite \
    -censor "$fd_censor_file" \
    -ortvec "$reg_concat" "$reg_names" \
    -polort 3 \
    -jobs 32 \
    -prefix ${subj_task_dir}/${outfile} \
    -input "${inputs4d[@]}" \
    -num_stimts 12 \
    -stim_times 1 "${oned_dir_single}/${ld8}_img_Left_cue.1d" 'GAM' -stim_label 1 cue_img_left \
    -stim_times 2 "${oned_dir_single}/${ld8}_img_Right_cue.1d" 'GAM' -stim_label 2 cue_img_right \
    -stim_times 3 "${oned_dir_single}/${ld8}_noimg_Left_cue.1d" 'GAM' -stim_label 3 cue_noimg_left \
    -stim_times 4 "${oned_dir_single}/${ld8}_noimg_Right_cue.1d" 'GAM' -stim_label 4 cue_noimg_right \
    -stim_times_AM1 5 "${oned_dir_bydur}/${ld8}_img_Left_dly.1d" 'dmBLOCK' -stim_label 5 dly_img_left \
    -stim_times_AM1 6 "${oned_dir_bydur}/${ld8}_img_Right_dly.1d" 'dmBLOCK' -stim_label 6 dly_img_right \
    -stim_times_AM1 7 "${oned_dir_bydur}/${ld8}_noimg_Left_dly.1d" 'dmBLOCK' -stim_label 7 dly_noimg_left \
    -stim_times_AM1 8 "${oned_dir_bydur}/${ld8}_noimg_Right_dly.1d" 'dmBLOCK' -stim_label 8 dly_noimg_right \
    -stim_times 9 "${oned_dir_single}/${ld8}_img_Left_mgs.1d" 'GAM' -stim_label 9 mgs_img_left \
    -stim_times 10 "${oned_dir_single}/${ld8}_img_Right_mgs.1d" 'GAM' -stim_label 10 mgs_img_right \
    -stim_times 11 "${oned_dir_single}/${ld8}_noimg_Left_mgs.1d" 'GAM' -stim_label 11 mgs_noimg_left \
    -stim_times 12 "${oned_dir_single}/${ld8}_noimg_Right_mgs.1d" 'GAM' -stim_label 12 mgs_noimg_right \
    -num_glt 9 \
    -gltsym 'SYM:.25*cue_img_left +.25*cue_noimg_left +.25*cue_img_right +.25*cue_noimg_right' -glt_label 1 cue_all \
    -gltsym 'SYM:.25*cue_img_left +.25*cue_noimg_left -.25*cue_img_right -.25*cue_noimg_right' -glt_label 2 cue_LvR \
    -gltsym 'SYM:.25*cue_img_left +.25*cue_img_right -.25*cue_noimg_left -.25*cue_noimg_right' -glt_label 3 cue_IMGvNOIMG \
    -gltsym 'SYM:.25*dly_img_left +.25*dly_noimg_left +.25*dly_img_right +.25*dly_noimg_right' -glt_label 4 dly_all \
    -gltsym 'SYM:.25*dly_img_left +.25*dly_noimg_left -.25*dly_img_right -.25*dly_noimg_right' -glt_label 5 dly_LvR \
    -gltsym 'SYM:.25*dly_img_left +.25*dly_img_right -.25*dly_noimg_left -.25*dly_noimg_right' -glt_label 6 dly_IMGvNOIMG \
    -gltsym 'SYM:.25*mgs_img_left +.25*mgs_noimg_left +.25*mgs_img_right +.25*mgs_noimg_right' -glt_label 7 mgs_all \
    -gltsym 'SYM:.25*mgs_img_left +.25*mgs_noimg_left -.25*mgs_img_right -.25*mgs_noimg_right' -glt_label 8 mgs_LvR \
    -gltsym 'SYM:.25*mgs_img_left +.25*mgs_img_right -.25*mgs_noimg_left -.25*mgs_noimg_right' -glt_label 9 mgs_IMGvNOIMG \
    -errts "${subj_task_dir}/${ld8}_lrimg_dmblock_task_errts_nosmooth.nii.gz" \
    -x1D X.xmat.1D \
    -rout \
    -tout
}

eval "$(iffmain decon_all_nost decon_one_dmblock)"
