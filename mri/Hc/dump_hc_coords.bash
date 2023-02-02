#!/usr/bin/env bash
# use view_placements.jl output 'hc_loc_unrotated.1d' to create nifti roi masks
# and count the number of voxels that are in Hc

# TODO:
#  high res FS has sub parcilations. could use that for more info (different $aseg and $hc_rois)
#  might care more about the labels of what's not in Hc. need to use differt roi idxes
#  problem with -cubes -srad 4.5? not getting 9**3 voxel counts (all nii.gz are 1x1x1mm)
#  - also consider $aseg<17> $aseg<53> as separate inputs to 3dROIstats for more fine grain count
#     would have caught accidental 52 instead of 53 when all right was 0
#     will be useful for high res labeling too

# 20221111WF - init

hc_rois=17,53  # left and right. value selectors given to roistats



#  https://surfer.nmr.mgh.harvard.edu/fswiki/FsTutorial/AnatomicalROI/FreeSurferColorLUT
# 17  Left-Hippocampus 
# 53  Right-Hippocampus

# # HiRes Hippocampus labeling
# 500 right_CA2_3              
# 501 right_alveus             
# 502 right_CA1                
# 503 right_fimbria            
# 504 right_presubiculum       
# 505 right_hippocampal_fissure
# 506 right_CA4_DG             
# 507 right_subiculum          
# 508 right_fornix             
# 
# 550 left_CA2_3               
# 551 left_alveus              
# 552 left_CA1                 
# 553 left_fimbria             
# 554 left_presubiculum        
# 555 left_hippocampal_fissure 
# 556 left_CA4_DG              
# 557 left_subiculum           
# 558 left_fornix              


for T1_hc in /Volumes/Hera/Projects/7TBrainMech/scripts/mri/Hc/spectrum/20*/FS_warp/*_T1-HcScout_Warped.nii.gz; do
    outdir=$(dirname "$T1_hc")
    txt_out=$outdir/hc_macro_coverage.txt
    [ -s "$txt_out" ] && continue


    aseg=$outdir/$(basename "$T1_hc" |sed 's/T1-.*/aseg_scout.nii.gz/')
    [ ! -r "$aseg" ] && warn "ERROR: cannot find FS aseg atlas '$aseg'" && continue

    incoord=$outdir/../hc_loc_unrotated.1d
    test ! -r "$incoord" && warn "ERROR: cannot find unroatated hc coords '$incoord' (view_placements.jl)" && continue  

    # 9x9x9 cubes. underestimage by 1mm on z. cube for each roi. value is roi number in the file
    # NB. orient RPI to match input from view_placements.jl
    #     and still need to flip first and second column
    #     50 is middle z-slice. NR is "record number" (line num) == roi number
    dryrun 3dUndump -orient RPI -cubes -srad 4.5 -ijk \
      -master "$T1_hc" \
      -prefix "$outdir/hc-coords.nii.gz" -overwrite \
      <(awk  '{print $2,$1,"50",NR}' "$incoord")

    # TODO Add 1mm on bottom of z
    # 3dcalc -m $outdir/hc-coords.nii.bz -expr 'step(k-1)*m' -prefix hc-coords-9x9x10.nii.gz

    # expect volume to be the same for all rois and all visits. but one roi will overlap another if place too close!?
    # see 11769_29291192
    dryrun 3dROIstats -nomeanout -nzvoxels -mask "$outdir/hc-coords.nii.gz" "$outdir/hc-coords.nii.gz" | writedry "$outdir/coord_vol.txt"
    # TODO: nzvol count like 1133 > 10^3. expect 9^3==729

    dryrun 3dROIstats -nomeanout -nzvoxels -mask "$outdir/hc-coords.nii.gz" "$aseg<$hc_rois>" | writedry "$txt_out"

done
