#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
# get coordinates into mni space to make rois
# uses txt/subj_label_val_20190503.csv
#  20190508WF  init
#

# make sure we have subjects
SUBJROOT="/Volumes/Hera/Projects/7TBrainMech/subjs/"
[ ! -d $SUBJROOT ] && echo "cannot find subjects root $SUBJROOT" >&2 && exit 1

# find most recent labeling like txt/subj_label_val_20190503.csv
# use that to get list of files like slice_roi_MPOR20190425_CM_11323_20180316_16_737541.477512_OR.txt
coord_file="$(\ls txt/subj_label_val_*.csv | tac |sed 1q)"
[ -z "$coord_file" -o ! -r "$coord_file" ] && echo 'no txt/subj_label_val_*.csv' && exit 1
# PULLVERSION=pulled$(basename ${coord_file/*_/} .csv)

# get id and file like
# 11323_20180316 slice_roi_MPOR20190425_CM_11323_20180316_16_737541.477512_OR.txt
perl -lne 'print "$2 $1" if m/,"?([^,]+(\d{5}_\d{8})[^,]+.txt)/' "$coord_file" |sort |uniq |
 while read ld8 coord; do

    ## Check files
    subjdir=$SUBJROOT/$ld8/slice_PFC/MRSI_roi/
    [ ! -r $subjdir ] && echo "no $subjdir! how is that possible" >&2 && continue

    # define files
    coord=$subjdir/raw/$coord
    rorig=$subjdir/raw/rorig.nii
    tmplbrain=/Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/ppt1/template_brain.nii
    fs=/Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/MRSI/parc_group/orig.nii
    mpragepp=/Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/ppt1/mprage.nii.gz
    warpcoef=/Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/ppt1/mprage_warpcoef.nii.gz 
    mp2slice=/Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/mprage_to_slice.mat

    # make sure we have files
    for v in coord rorig tmplbrain fs mp2slice mpragepp warpcoef; do
       # set v to full path
       printf -v $v "$(readlink -f ${!v})"
       [ -z "${!v}" -o ! -r "${!v}" ] && echo "no $v (${!v})!" >&2 &&
          continue 2 # leave this file checking loop and go to the next subject
    done

    [ ! -d $subjdir/spectrum/ ] && mkdir $subjdir/spectrum/
    cd $subjdir/spectrum/



    for v in rorig tmplbrain fs mpragepp; do
       [ ! -r "$(basename "${!v}")" ] && ln -s $(readlink -f "${!v}") ./
    done

    # did we already run?
    [ -r finish_mniwarp.flag ] && echo "finished $(pwd) $(cat finish_mniwarp.flag)" &&  continue

    ### DO STUFF
    set -x

    # dump coordinates as cubes in slice space (registared orig)
    awk '{print $2,$3,$4,$1}' $coord  > coords_rearranged.txt
    3dUndump \
        -overwrite -prefix coords_slicespace.nii.gz  \
        -master $rorig\
        -srad 4.5 \
        -cubes \
        -ijk coords_rearranged.txt

    # reverse affine transfor for slice to mprage
    convert_xfm -omat slice_to_mprage.mat -inverse $mp2slice
    # apply to get slice coords into mprage (used for gm mask count)
    flirt -interp nearestneighbour -in coords_slicespace.nii.gz -ref $mpragepp -applyxfm -init slice_to_mprage.mat -out coords_mprage.nii.gz
    # it's orig not TLRC (fsl looses this info)
    3drefit -space ORIG coords_mprage.nii.gz
    # send coords from slice to mni (using t1 as intermidate: warpcoef + slice->t1 premat)
    # useful for connectivity
    cmd="
    applywarp -o coords_mni.nii.gz \
        -i coords_slicespace.nii.gz \
        -r "$tmplbrain" \
        -w "$warpcoef" \
        --premat=slice_to_mprage.mat \
        --interp=nn "
    eval $cmd
    3dNotes -h "$cmd" coords_mni.nii.gz
    [ -r coords_mni.nii.gz ] && echo "$(date) $0" > finish_mniwarp.flag || echo "failed to warp!"

    set +x
    # # testing premat vs postmat and comparing to freesurfer
    # applywarp -o coords_mni_dontuse_2xintroplate.nii.gz \
    #     -i coords_mprage.nii.gz \
    #     -r "$tmplbrain" \
    #     -w "$warpcoef" \
    #     --interp=nn 

    ## MATLAB import/export of Freesurfer has a voxel shift down and left
    # # orig (FS) used by matlab is slightly different than mprage shift just a bit -- result of matlab import/export
    # flirt -dof 6 -ref orig.nii -in mprage.nii.gz -omat mprage_to_fs.mat -out mprage_to_fs.nii.gz

    # # convert_xfm -omat <outmat_AtoC> -concat <mat_BtoC> <mat_AtoB>
    # # A=slice B=mprage C=fs
    # convert_xfm -omat slice_to_fs.mat -concat mprage_to_fs.mat slice_to_mprage.mat

    # # to see trasformation for FS as registared to slice
    # # flirt -interp nearestneighbour -in $rorig -ref $mpragepp -applyxfm -init slice_to_mprage.mat -out orig_mprage.nii.gz
    # # 3drefit -space ORIG orig_mprage.nii.gz

    # flirt -interp nearestneighbour -in coords_slicespace.nii.gz -ref $fs -applyxfm -init slice_to_fs.mat -out coords_fs.nii.gz
    # 3drefit -space ORIG coords_fs.nii.gz

    # # double interpolation
    # 3dresample -master $mpragepp -inset coords_fs.nii.gz -prefix coords_fs_t1dim.nii.gz -overwrite
    # applywarp -o coords_fs_mni.nii.gz \
    #      -i coords_fs_t1dim.nii.gz \
    #      -r "$tmplbrain" \
    #      -w "$warpcoef" \
    #      --interp=nn 

    
done

# afni -com 'SWITCH_OVERLAY coords_mni.nii.gz' -com 'OPEN_WINDOW B' -com 'OPEN_WINDOW B.axialimage' -com 'SWITCH_OVERLAY B.coords_fs_mni.nii.gz' -com 'SET_PBAR_ALL +99 12 ROI_i32'  -com 'SET_PBAR_ALL B.+99 12 ROI_i32' -com 'SET_FUNC_RANGE 12' ~/standard/mni_icbm152_nlin_asym_09c/mni_icbm152_t1_tal_nlin_asym_09c.nii coords_mni.nii.gz coords_fs_mni.nii.gz coords_mni_dontuse_2xintroplate.nii.gz
# afni -com 'SWITCH_OVERLAY coords_mprage.nii.gz' -com 'OPEN_WINDOW B.axialimage' -com 'SWITCH_OVERLAY B.coords_fs.nii.gz' -com 'SET_PBAR_ALL +99 12 ROI_i32'  -com 'SET_PBAR_ALL B.+99 12 ROI_i32' -com 'SET_FUNC_RANGE 12'  mprage.nii.gz orig.nii coords_mprage.nii.gz coords_fs_t1dim.nii.gz coords_fs.nii.gz

