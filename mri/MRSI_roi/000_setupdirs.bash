#!/usr/bin/env bash
set -e
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
cd $(dirname $0)
mni_atlas=$(pwd)/csi_rois_mni.nii.gz

#
# creates directory with raw files need to run SVR1HFinal
# 1. copy of an mprage in slice space (as mprage_middle.mat and seg.7)
# 2. siarray.1.*
# 3. roi center coordinates in slice space
#

if [ $# -le 0 ]; then
   cat <<-EOF
   USAGE: 
    $0 lunaid_date
    $0 all
   EXAMPLE:
    $0 11323_20180316
	EOF

   exit 1
fi

if [ $1 == "all" ]; then
   ls /Volumes/Hera/Projects/7TBrainMech/subjs/*/slice_PFC/ | 
    perl -lne 'print $& if m/\d{5}_\d{8}/' |
    xargs -n1 echo $0 
   exit 0
fi


## input is subject id
ld8="$1"


## get mrid from id lookup (from id_list.bash)
MRID="$(grep "$ld8" ../MRSI/txt/ids.txt|cut -d' ' -f2)"
[ -z "$MRID" ] && echo "cannot find MRID for '$ld8'; try ../MRSI/id_list.bash" && exit 1

## find mprage (output of 02_label_csivox.bash)
MPRAGE="$(find /Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/MRSI/struct_ROI/ -maxdepth 1 -type f,l -iname '*_7_FlipLR.MPRAGE')"
[ -z "$MPRAGE" ] && echo "cannot find '*_7_FlipLR.MPRAGE'; try: ../MRSI/02_label_csivox.bash $ld8" && exit 1
parc_res="/Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/MRSI/parc_group/rorig.nii"
[ ! -r "$parc_res" ] && echo "cannot find '$parc_res'; try: ../MRSI/02_label_csivox.bash $ld8" && exit 1

## use mprage to determine slice num (probably 17 or 21)
slice_num=$(basename $MPRAGE | cut -f1 -d_)
# afni needs zero based count
slice_num_0=$((($slice_num - 1)))
[ $slice_num_0 != 16 -a $slice_num_0 != 21 ] &&
   echo "unexpected slice number zero-based slice index '$slice_num' (16 or 20), from $MPRAGE" && exit 1

## check final output -- no need to run if we already have it
sdir=/Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/MRSI_roi/raw
finalout=$sdir/slice_roi_CM_${ld8}_${slice_num_0}.txt
[ -r "$finalout" ] && echo "# have $finalout; rm -r '$sdir' # to redo" && exit 0

## warp files (from preprocessing and 01_get_slices.bash)
t1_to_pfc="/Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/mprage_to_slice.mat"
pfc_ref="/Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/slice_pfc.nii.gz"
mni_to_t1="/Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/ppt1/template_to_subject_warpcoef.nii.gz"
for v in t1_to_pfc pfc_ref mni_to_t1; do
   [ ! -r "${!v}" ] && echo "cannot find $v: '${!v}'; try: ../MRSI/01_get_slices.bash $ld8" && exit 1
done

## raw PFCCSI data
# NB. when we get hipocampus, will cause issues
rawdir="/Volumes/Hera/Raw/MRprojects/7TBrainMech/$MRID"
SIARRAY="$(
  find $rawdir -maxdepth 1 -type d,l -iname '*CSI*' -print0 |
   xargs -I{} -r0n1 find "{}" -maxdepth 1 -type f,l -iname 'siarray.*' -print -quit |
   sed 1q |
   xargs -r dirname
)"
[ -z "$SIARRAY" -o ! -d "$SIARRAY" ] && echo "cannot find si.array files in $rawdir; get data from Hoby!" && exit 1

# put links of files into a directory for easy viewing in matlab gui
echo $ld8 $SIARRAY $MPRAGE
[ ! -d $sdir ] && mkdir -p $sdir
cd $sdir
[ ! -e siarray.1.1 ] && ln -s $SIARRAY/siarray.* ./
[ ! -e mprage_middle.mat ] && ln -s $MPRAGE mprage_middle.mat # make mat for easy selection
[ ! -e seg.7 ] && ln -s $MPRAGE seg.7             # fake seg
[ ! -e rorig.nii ] && ln -s $parc_res ./          # higher res mprage (from FS) in slice space

# warp our mni roi atlas to slice space (mni->t1->slice)
outimg=csi_rois_slice_$ld8.nii.gz
if [ ! -r $outimg ]; then 
   cmd="applywarp -o $outimg -i $mni_atlas -r $pfc_ref -w $mni_to_t1 --postmat=$t1_to_pfc --interp=nn"
   eval "$cmd"
   3dNotes -h "$cmd # $0 $@" $outimg
fi

# later we'll use row/col to find postions in parc_res (216x216)
# but we'll lose what slice we are on so cut that first
# 3dcalc -a "$outimg" -expr "amongst(k,$slice_num_0+1,$slice_num_0, $slice_num_0-1)*a" -prefix csi_rois_slice_${ld8}_middle.nii.gz -overwrite
3dcalc -a "$outimg" -expr "equals(k,$slice_num_0)*a" -prefix csi_rois_slice_${ld8}_middle.nii.gz -overwrite
res_img=csi_rois_slice_${ld8}_middle_216x216.nii.gz
[ ! -r $res_img ] && 
  3dresample -inset csi_rois_slice_${ld8}_middle.nii.gz \
     -master $parc_res \
     -prefix $res_img -rmode NN

# add a total gm mask (based on victor's parcilation)
# used to give an idea of wm total in matlab roi selection interface (coord_mover.m)
AFNI_COMPRESSOR="" 3dMean -prefix gm_sum.nii -overwrite -sum $(dirname $parc_res)/r*gm*


# get the center of mass coordinates on the zero-indexed center slice (likely 16)
3dCM -local_ijk -all_rois $res_img | 
  egrep '^[0-9]|#ROI'|
  paste - - |
  cut -f2-4 -d" " |
  tee $finalout

exit 0
