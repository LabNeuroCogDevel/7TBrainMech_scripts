#!/usr/bin/env bash
#
# initial GM counts are with smaller roi region from placement gui (grid.py)
# But we want to match GM count (and GMratio) used to build GAM model
# (GAM generates nuisance regressed (date adjusted) Cre ration values)
# so inputs of this Thal redo match original Luna inputs
#
# This is script borrows from ../041_GMcount.bash
# which makes roi_percent_cnt_13MP20200207.txt read in by 050_merge.R
#
# If 'coords_rearranged.txt' (lines like x y 50 roival), it will be linked as 'coords_rpi_for_undump.txt'
# otherwise we try to generate the file, but that will only work for the LRThal atlas
#
# 20260625WF - init
# 20260626WF - output files are resampled to LPI. added MNI warp

export NROI=${NROI:-2} \
 ATLAS=${ATLAS:-LRThal} \
 SUBJECT_DIR=${SUBJECT_DIR:-/Volumes/Hera/Projects/7TBrainMech/FS} \
 MNI=${TEMPLATE_FLOW:-$HOME/.cache/templateflow}/tpl-MNI152NLin2009cAsym/tpl-MNI152NLin2009cAsym_res-01_desc-brain_T1w.nii.gz \
 AFNI_NIFTI_TYPE_WARN=NO \
 OUTDIR=gm_redo20260626



# matlab/fortran COL ROW to RPI dicom coordinates for 3dUndump
# "-master" is rorig.nii. 3dinfo -orient says that's RPI. that's what 3dUndump will use
# NOTE: will use last e.g. LThal coordinate as what's reporte
#       LEFT is 1, RIGHT is 2
#  ls -dcr ThalRedo_10195_20180129/*.dir
#   ThalRedo_10195_20180129/LThal_gm-741.136.116.dir 
#   ThalRedo_10195_20180129/RThal_gm-720.136.129.dir
# in coordplacer gui: image top right = 0,0; bottom left = 214,214. antomical is L=R
sid_to_rpi(){
   out=${1:?output file}; shift
   matsize=${1:?max matrix size}; shift
   center_z=${1:?center z}; shift
   printf "%s\n" "$@" |
      perl -slne '$a{$+{roi}} = [ ($matsize-$+{X}+1),
                                 ($matsize-$+{Y}+1)]
                               if m/(?<roi>L|R)Thal.*\.(?<Y>[0-9]+)\.(?<X>[0-9]+).dir/;
                END{print("@{$a{$_}} ",sprintf("%.0f",($center_z+1)/2), " " ,++$i) for qw/L R/}' \
      -- -matsize="$matsize" -center_z="$center_z" \
    > "$out"
}

sid_to_rpi_spectrum_match(){
   out=${1:?output file}; shift
   matsize=${1:?max matrix size}; shift
   test -r roi_pos_new.txt && file=$_
   test -r roi_pos_new.txt && file=$_
   printf "%s\n" "$@" |
      perl -lne '$a{$+{roi}} = [ ($matsize-$+{X}+1),
                                 ($matsize-$+{Y}+1)]
                               if m/(?<roi>L|R)Thal.*\.(?<Y>[0-9]+)\.(?<X>[0-9]+).dir/;
                END{print "@{$a{$_}} 50 ".++$i for qw/L R/}' \
      -- -matsize="$matsize" \
    > "$out"
}

# get gray matter from freesurfer surfer
gm_bin_nii(){
   local fs_mgz=${1:?aparc+aseg.mgz mgz file}
   gmcmd="mri_binarize --i $fs_mgz --gm --o $OUTDIR/gmmask.mgz && mri_convert $OUTDIR/gmmask.mgz $OUTDIR/fs_gmmask.nii.gz && rm $OUTDIR/gmmask.mgz"
   eval "$gmcmd"
   3dNotes -h "$gmcmd" $OUTDIR/fs_gmmask.nii.gz
   3dresample -prefix $OUTDIR/fs_gmmask.nii.gz -inset $OUTDIR/fs_gmmask.nii.gz -orient LPI -overwrite
}

# linear/affine warp from rorig (slice/scout space) to FS (anatomical "mprage")
# create affine matrix later used to move rois from scout to anat
make_mat(){
   niinote $OUTDIR/fs_anat.nii.gz bash -c "mri_convert '${1:?freesurfer input anat mgz}' $OUTDIR/fs_anat.nii.gz"
   3dresample -overwrite -orient LPI -input $OUTDIR/fs_anat.nii.gz -prefix $OUTDIR/fs_anat.nii.gz
   niinote $OUTDIR/rorig_as_fs.nii.gz flirt -in "${2:?rorig.nii.gz}"  -ref $OUTDIR/fs_anat.nii.gz -omat $OUTDIR/slice_to_mprage.mat -o $OUTDIR/rorig_as_fs.nii.gz
}

# output roi stats to file, rows like: sess_id atlas roinum voxels
# where sess and atlas are same (repeated) each line
roistats_long(){
  declare -g NROI ATLAS OUTDIR
  3dROIstats -quiet -nzvoxels -numROI $NROI -mask $OUTDIR/coords_mprage.nii.gz $OUTDIR/fs_gmmask.nii.gz |
   tr $'\t' '\n'|
   sed 1d|
   paste - -|
   cat -n|
   sed "s/^/${1:?session id} $ATLAS /" | tee "${2:?long format roistats output file}"
}

to_mni(){
  local ses_id=${1:?session id in freesurfer}
  declare -g SUBJECT_DIR TEMPLATE_FLOW OUTDIR
  fs_brain="$SUBJECT_DIR/$ses_id/mri/brain.mgz"
  ! test -s "$MNI" &&
     python -c "import templateflow; templateflow.api.get('MNI152NLin2009cAsym', suffix=['T1w'])"
     # uv tool run templateflow get MNI152NLin2009cAsym --res 01 --suffix T1w
  niinote $OUTDIR/brain_space-anat.nii.gz mri_convert "$fs_brain" $OUTDIR/brain_space-anat.nii.gz
  3dresample -overwrite -orient LPI \
     -input $OUTDIR/brain_space-anat.nii.gz -prefix $OUTDIR/brain_space-anat.nii.gz
  niinote $OUTDIR/brain2mni_1Warp.nii.gz antsRegistrationSyNQuick.sh \
     -d 3 -f "$MNI" -m "$fs_brain" -o $OUTDIR/brain2mni_
  ln -s "$MNI" $OUTDIR/
}

gm_session(){ 
  export -f gm_bin_nii sid_to_rpi make_mat roistats_long to_mni
  cd "${1:?slice directory with rorig}" || return 1

  ! [[ $PWD =~ [0-9]{5}_[0-9]{8} ]] && echo "ERROR: no id in $PWD" && return 2
  ses_id=${BASH_REMATCH[0]}  #like 11945_20230721

  fs_mgz="$SUBJECT_DIR/$ses_id/mri/aparc+aseg.mgz"
  rorig_all=(rorig.nii*); rorig=$(readlink -f "${rorig_all[0]}")
  ! test -r "$fs_mgz" && echo "ERROR: missing $fs_mgz" && return 3
  ! test -r "$rorig" && rorig=$rorig.gz # ugly linking. if missing try gz version
  ! test -s "$rorig" && echo "ERROR: missing rorig.nii* '$rorig' in $PWD" && return 3

  size_orient=($(3dinfo -ni -nj -nk -orient "$rorig"))
  ! [[ ${size_orient[*]} =~ 216.216.99.RPI ]] && echo "ERROR! $rorig not expected orientation (have: '${size_orient[*]}')" && return 4

  dryrun mkdir -p $OUTDIR
  
  skip-exist $OUTDIR/"$(basename "$rorig")" \
     ln -s "$rorig" __SKIPFILE

  # resuse existing coords file
  [  -s coords_rearranged.txt -a \
   ! -r $OUTDIR/coords_rpi_for_undump.txt ] &&
     dryrun ln -s "$PWD/coords_rearranged.txt" "$OUTDIR/coords_rpi_for_undump.txt" 
  
  # currently only works for LRThal redo. need above file otherwise
  skip-exist $OUTDIR/coords_rpi_for_undump.txt \
    sid_to_rpi __SKIPFILE "${size_orient[0]}" "${size_orient[2]}" ./*.dir

  skip-exist $OUTDIR/slice_to_mprage.mat \
     make_mat "$SUBJECT_DIR/$ses_id"/mri/T1.mgz "$rorig"
  
  skip-exist $OUTDIR/coords_slicespace.nii.gz\
   bash -c "3dUndump -prefix __SKIPFILE \
     -master '$rorig' \
     -srad 4.5 -cubes \
     -ijk $OUTDIR/coords_rpi_for_undump.txt && 
   3dresample -overwrite -orient LPI \
     -input __SKIPFILE -prefix __SKIPFILE"
  
  skip-exist $OUTDIR/coords_mprage.nii.gz \
   niinote __SKIPFILE \
    flirt -interp nearestneighbour \
     -in $OUTDIR/coords_slicespace.nii.gz \
     -ref $OUTDIR/fs_anat.nii.gz \
     -applyxfm -init $OUTDIR/slice_to_mprage.mat \
     -out __SKIPFILE
  
  skip-exist $OUTDIR/fs_gmmask.nii.gz \
     gm_bin_nii "$fs_mgz"
  
  skip-exist $OUTDIR/gm_count.txt \
   roistats_long "$ses_id" __SKIPFILE 

  # MNI for coverage comparison. !SLOW!
  skip-exist $OUTDIR/brain2mni_1Warp.nii.gz \
     to_mni "$ses_id"

  skip-exist $OUTDIR/coords_mni.nii.gz \
   niinote __SKIPFILE\
     antsApplyTransforms -v -d 3 \
     -i $OUTDIR/coords_mprage.nii.gz \
     -n NearestNeighbor \
     -o __SKIPFILE \
     -r "$MNI" \
     -t $OUTDIR/brain2mni_1Warp.nii.gz \
     -t $OUTDIR/brain2mni_0GenericAffine.mat
}

eval "$(iffmain gm_session)"

test_rpi() { #@test
 #LThal_gm-741.136.116.dir -> 116 81
 #RThal_gm-720.136.129.dir -> 129 81

 output=$(sid_to_rpi >(cat) 216 99 ThalRedo_10195_20180129/*.dir)
 echo "$output"
 [[ "$output" =~ 101.81.50.1.*88.81.50.2 ]]
}
