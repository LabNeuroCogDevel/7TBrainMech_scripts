#!/usr/bin/env bash
set -e
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
cd $(dirname $0)
#mni_atlas=$(pwd)/csi_rois_mni.nii.gz
#mni_atlas=$(pwd)/csi_rois_mni_MPRO_20190425.nii.gz
atlas=13MP20200207
mni_atlas="$(pwd)/roi_locations/ROI_mni_$atlas.nii.gz"
statusfile="$(dirname $0)/../txt/status.csv"

# default to show finish. if empty, does not print about completed subjects
env | grep '^SHOWFINISH=' -q || SHOWFINISH="yes"
env | grep '^DRYRUN=' -q && DRYRUN=echo || DRYRUN=""

#
# creates directory with raw files need to run SVR1HFinal
# 1. copy of an mprage in slice space (as mprage_middle.mat and seg.7)
# 2. siarray.1.1
# 3. roi center coordinates in slice space
#

if [ $# -le 0 ]; then
   cat <<-EOF
   USAGE:
    $0 lunaid_date   # specify single subject
    $0 all           # all subjects (print errors for missing)
    $0 have          # only what spreadsheet says we have
    SHOWFINISH="" $0 all # disable some messages, show only missing/failing
    # run the suggestsions 
    ./000_setupdirs.bash all 2>&1 |sed -n 's/.*try: //p'|xargs -I{} -n1 bash -c "{}"
   EXAMPLE:
    $0 11323_20180316
	EOF

   exit 1
fi

if [ $1 == "all" ]; then
   ls /Volumes/Hera/Projects/7TBrainMech/subjs/*/slice_PFC/ |
    perl -lne 'print $& if m/\d{5}_\d{8}/' |
    xargs -n1 $0
    #xargs -n1 echo $0
   exit 0
fi
if [ $1 == "alldb" ]; then
   selld8 l |grep Scan.*Brain |
    perl -lne 'print $& if m/\d{5}_\d{8}/' |
    xargs -n1 $0
    #xargs -n1 echo $0
   exit 0
fi

# only preproc what the sheet says we have
if [ $1 == "have" ]; then
   [ ! -r "$statusfile" ] && echo "missing status files, run ../900_status.R" && exit 1
   Rio -e 'df$ld8[!is.na(df$csipfc_raw)&!is.na(df$ld8)]' < "$statusfile" |
    sed 's/\\n/\n/g' |
    xargs -rn1 $0
    #xargs -rn1 echo $0
   exit 0
fi


## input is subject id
ld8="$1"


## get mrid from id lookup (from id_list.bash)
MRID="$(grep "$ld8" ../MRSI/txt/ids.txt|cut -d' ' -f2)"
[ -z "$MRID" ] && MRID="$(lncddb "
 select m.id from enroll m join enroll e
    on e.etype like 'LunaID' and m.etype like '%MR%' and m.pid=e.pid
    where e.id like '$ld8'")"
[ -z "$MRID" ] && echo "cannot find MRID for '$ld8'; update db or try: ../MRSI/id_list.bash" && exit 1

# need slices
[ ! -d /Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/ ] &&
   echo "cannot find $ld8/slice_PFC dir; run ../MRSI/01_get_slices.bash $ld8" && exit 1

## find mprage (output of 02_label_csivox.bash)
roi_struct=/Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/MRSI/struct_ROI/
[ ! -d $roi_struct ] && echo "cannot find $roi_struct; try: NOCSV=1 ../MRSI/02_label_csivox.bash $ld8" && exit 1

MPRAGE="$(find -L $roi_struct -maxdepth 1 -type f,l -iname '*_7_FlipLR.MPRAGE')"
[ -z "$MPRAGE" ] && echo "cannot find '*_7_FlipLR.MPRAGE'; try: NOCSV=1 ../MRSI/02_label_csivox.bash $ld8" && exit 1
parc_res="/Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/MRSI/parc_group/rorig.nii"
[ ! -r "$parc_res" ] && echo "cannot find '$parc_res'; try: NOCSV=1 ../MRSI/02_label_csivox.bash $ld8" && exit 1

## use mprage to determine slice num (probably 17 or 21)
slice_num=$(basename $MPRAGE | cut -f1 -d_)
# afni needs zero based count
slice_num_0=$((($slice_num - 1)))
[ $slice_num_0 != 16 -a $slice_num_0 != 20 ] &&
   echo "unexpected slice number zero-based slice index '$slice_num' ($slice_num_0 != 16 or 20), from $MPRAGE" && exit 1

## check final output -- no need to run if we already have it
sdir=/Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/MRSI_roi/raw
finalout=$sdir/slice_roi_${atlas}_CM_${ld8}_${slice_num_0}.txt
if [ -r "$finalout" ]; then
   [ -n "$SHOWFINISH" ] && echo "# have $finalout; rm -r '$sdir' # to redo" 
   exit 0
fi

## warp files (from preprocessing and 01_get_slices.bash)
t1_to_pfc="/Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/mprage_to_slice.mat"
pfc_ref="/Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/slice_pfc.nii.gz"
mni_to_t1="/Volumes/Hera/Projects/7TBrainMech/subjs/$ld8/slice_PFC/ppt1/template_to_subject_warpcoef.nii.gz"
for v in t1_to_pfc pfc_ref mni_to_t1; do
   [ -n "${!v}" -a -r "${!v}" ] && continue
   echo "$0: cannot find variable $v: '${!v}'; try: ../MRSI/01_get_slices.bash $ld8" 
   ls -l "${!v}"
   exit 1
done

## raw PFCCSI data
# NB. when we get hipocampus, will cause issues
rawdir="/Volumes/Hera/Raw/MRprojects/7TBrainMech/$MRID"
boxsiarray="/Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/PFC_siarray/$MRID"
# 20211015 - update maxdepth to 2 so we can find '$ID/Recon/
SIARRAY="$(
  find -L $rawdir -maxdepth 2 -type d,l -iname '*CSI*' -not -ipath '*CSIHc*' -print0 |
   xargs -I{} -r0n1 find -L "{}" -maxdepth 1 -type f,l -iname 'siarray.*' -print -quit |
   sed 1q |
   xargs -r dirname
)"
# nothing in raw data, try box
[ -z "$SIARRAY" -a -d "$boxsiarray" ] &&
  SIARRAY="$(
     find -L "$boxsiarray" -maxdepth 1 -type f,l -iname 'siarray.1.1' -print -quit |
     sed 1q |
     xargs -r dirname
  )"

# 20201203 - for 11790_20190916. victors updated dirctory
no_more_mrrc=/Volumes/Hera/Raw/MRprojects/7TBrainMech/Processed_Victor/$MRID/CSIPFC/
[ -z "$SIARRAY" -o ! -d "$SIARRAY" ] &&
   SIARRAY=$(find $no_more_mrrc -iname siarray.1.1|sed 1q|xargs -r dirname)

if [ -z "$SIARRAY" -o ! -d "$SIARRAY" ]; then
   echo "cannot find siarray files in $rawdir or $boxsiarray or $no_more_mrrc; Victor may need to reconstruct (synced from 7tlinux shim [20200304]; prev ../001_rsync_MRSI_from_box.bash)!"
   # if we can use q to query the csv file w/sql, use it
   which q >/dev/null && [ -r "$statusfile" ] &&
      q -d, -H "select csipfc_raw from - where ld8 like '$ld8'" < $statusfile |
      xargs echo "expect NA in $statusfile $ld8 for csipfc_raw file timestamp: "
   exit 1
fi

# put links of files into a directory for easy viewing in matlab gui
echo $ld8 $SIARRAY $MPRAGE
[ ! -d $sdir ] && mkdir -p $sdir
cd $sdir
[ ! -e siarray.1.1 ] && $DRYRUN ln -s $SIARRAY/siarray.1.1 ./
[ ! -e mprage_middle.mat ] && $DRYRUN ln -s $MPRAGE mprage_middle.mat # make mat for easy selection
[ ! -e seg.7 ] && $DRYRUN ln -s $MPRAGE seg.7             # fake seg
[ ! -e rorig.nii ] && $DRYRUN ln -s $parc_res ./          # higher res mprage (from FS) in slice space
[ -n "$DRYRUN" ] && exit 
# warp our mni roi atlas to slice space (mni->t1->slice)
outimg=csi_rois_slice_$ld8.nii.gz
if [ ! -r $outimg ]; then
   cmd="applywarp -o $outimg -i $mni_atlas -r $pfc_ref -w $mni_to_t1 --postmat=$t1_to_pfc --interp=nn"
   eval "$cmd"
   3dNotes -h "$cmd # $0 $@" $outimg
fi


# add a total gm mask (based on victor's parcilation)
# used to give an idea of wm total in matlab roi selection interface (coord_mover.m)
AFNI_COMPRESSOR="" 3dMean -prefix gm_sum.nii -overwrite -sum $(dirname $parc_res)/r*gm*

# 20200305 TODO: do we need this anymore
# rois are handled by coord_builder.bash ??

# later we'll use row/col to find postions in parc_res (216x216)
# but we'll lose what slice we are on so cut that first
# 3dcalc -a "$outimg" -expr "amongst(k,$slice_num_0+1,$slice_num_0, $slice_num_0-1)*a" -prefix csi_rois_slice_${ld8}_middle.nii.gz -overwrite
3dcalc -a "$outimg" -expr "equals(k,$slice_num_0)*a" -prefix csi_rois_slice_${ld8}_middle.nii.gz -overwrite
res_img=csi_rois_slice_${ld8}_middle_216x216.nii.gz
[ ! -r $res_img ] &&
  3dresample -inset csi_rois_slice_${ld8}_middle.nii.gz \
     -master $parc_res \
     -prefix $res_img -rmode NN


# get the center of mass coordinates on the zero-indexed center slice (likely 16)
3dCM -local_ijk -all_rois $res_img |
  egrep '^[0-9]|#ROI'|
  paste - - |
  cut -f2-4 -d" " |
  tee $finalout

exit 0
