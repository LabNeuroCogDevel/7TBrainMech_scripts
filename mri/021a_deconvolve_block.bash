#!/usr/bin/env bash
#
# decon to generate errts for background connectivity
# using 1d files from ./020_task_onsets.R
# and tasktr from txt/task_trs.txt (see ../Makefile)
# saving to ../../subjs/$ld8/MGSEncMem/${ld8}_task_errts.nii.gz
#
# 20221209WF - rearrange into functions using DRYRUN=1/dryrun and mainiff.
#              so can test 'lookup_tr' with bats
# 20221212WF - refactor most functions into decon_functions.bash
#              easy copy into additional decon functions
#

# dryrun, iffmain defined in /opt/ni_tools/lncdtools/ (should be in path)
source decon_functions.bash # decon_all_nost concat_indir fd_censor
FD_THRES=0.5 # how much motion is acceptable?

decon_one_block(){
   # GLOBAL: likely set by 'decon_all_nost'
   [[ ! "$SUBJDIR" =~ subjs/?$ ]] && echo "NO SUBJECT DIR?! ('$SUBJDIR')" && return 1

   local oned_dir="$1"; shift
   local predir="$1"; shift
   # id should be in folder name. Extract and store
   [[ ! $predir =~ 1[0-9]{4}_2[0-9]{7} ]] && echo "no id in $predir" && return
   ld8="${BASH_REMATCH[0]}"

   inputs4d=("$predir"/0[1-4]/nfswdkm_func_4.nii.gz)

   # check we have 1d files for each run and have at least 1 4d file
   # (1d file has as many rows as number 4d files)
   ex1dfile=$oned_dir/${ld8}_img_Left.1d 
   check_inputs "$ex1dfile" "${inputs4d[@]}" || return

   # create subject directory and go there
   subj_task_dir=$SUBJDIR/$ld8/MGSEncMem
   [ ! -d "$subj_task_dir" ] && mkdir -p "$subj_task_dir "
   cd "$subj_task_dir"

   mot_concat=$(concat_indir ./all_motion.par motion.par      "${inputs4d[@]}") || return
   fd_concat=$(concat_indir ./all_fd.txt motion_info/fd.txt "${inputs4d[@]}") || return
   fd_censor_file=$(fd_censor "$fd_concat" "$FD_THRES") || return

   # check if we have an output
   [ -r LR_img_deconvolve.nii.gz -a -z "${REDO:-}" ] &&
      echo "Output file ($(pwd)/LR_img_deconvolve.nii.gz) exists, SKIPPING" && return

   # show what we're working on
   pwd

   tr=$(lookup_tr "$ld8")
   check_tr "$tr" || return

   # run
   # when e.g. DRYRUN=1 will echo, otherwise will run
   dryrun 3dDeconvolve  \
    -force_TR "$tr" \
    -overwrite \
    -censor "$fd_censor_file" \
    -ortvec "$mot_concat" motion \
    -prefix LR_img_deconvolve.nii.gz \
    -input "${inputs4d[@]}" \
    -num_stimts 4 \
    -stim_times_AM1  1 "$oned_dir/${ld8}_img_Left.1d" 'dmBLOCK'\
    -stim_label 1 img_left \
    -stim_times_AM1  2 "$oned_dir/${ld8}_img_Right.1d" 'dmBLOCK'\
    -stim_label 2 img_right \
    -stim_times_AM1  3 "$oned_dir/${ld8}_noimg_Left.1d" 'dmBLOCK'\
    -stim_label 3 noimg_left \
    -stim_times_AM1  4 "$oned_dir/${ld8}_noimg_Right.1d" 'dmBLOCK'\
    -stim_label 4 noimg_right \
    -errts "${ld8}_task_errts.nii.gz" \
    -x1D X.xmat.1D
}

# only run if launched like: ./021a_deconvolve_block.bash.
# this allows for 'source ./021a_deconvolve_block.bash' or 'bats ./021a_deconvolve_block.bash'
eval "$(iffmain decon_all_nost decon_one_block)"
