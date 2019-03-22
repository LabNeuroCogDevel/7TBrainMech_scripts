#!/bin/bash

# xxxxxxxxVI: Originally MRSI_CoregSeg_MB4_plusExtras.bash
# 20181213WF: modified for lncd files
#
# wrapper for matlab:
#  Divide ROI & Resize Scout to 1mm 
#  Coregistration (MPRAGE to Scout) & linear regression
#  estimate probability of FS ROI @ each csi voxel

# run for all with SI* sheets from box
#
[ -z "$DRYRUN" ] && DRYRUN=""
export DRYRUN
set -euo pipefail
export AFNI_COMPRESSOR="" AFNI_NIFTI_TYPE_WARN=NO
scriptdir=$(cd $(dirname $0);pwd)

BOXMRSI=/Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/
if [ $# -eq 0 ]; then
   cat <<HEREDOC 
   USAGE:
     $0 subj_date
     $0 all 
     # see /Volumes/Hera/Projects/7TBrainMech/pipelines/MHT1_2mm/ for subj list
HEREDOC
  exit 1
fi

if [ $1 == "all" ]; then
   find $BOXMRSI -iname spreadsheet.csv|
    perl -MFile::Basename -ple '$_=lc(basename(dirname(dirname($_))))'|
    while read mrid; do
       subj_date=$( (grep -i $mrid txt/ids.txt||echo " ") |cut -d' ' -f 1)
       [ -z "$subj_date" ] && echo "cannot find $mrid in txt/ids.txt; rerun ./id_list.bash" && continue
       $0 $subj_date || continue
    done
    
    #sort |
    #join -i -t' ' -1 1 -2 2 - \
    #   <(sort -t' ' -k2,2 txt/ids.txt)|
    #   cut -f 2 -d' '|
    #   xargs -n1 $0
   exit
fi

## read subject input

# user input
subj_date=$1

# check if we've already run
data_dir="/Volumes/Hera/Projects/7TBrainMech/subjs/$subj_date/slice_PFC/MRSI"
final=$data_dir/all_probs.nii.gz
[ -r  "$final" ] && echo "$subj_date: already finished. rm $final # to redo all" && exit 0

# files
subj=${subj_date%%_*}
FSdir=/Volumes/Hera/Projects/7TBrainMech/FS/$subj/ 
scout="/Volumes/Hera/Projects/7TBrainMech/subjs/$subj_date/slice_PFC/slice_pfc.nii.gz"
# no need for mprage -- using freesurfer's orig.nii
# could use link
#filename_MRSI=spreadsheet  # MRSI excel file name after excluding '_SI*'
rawloc=/Volumes/Hera/Raw/BIDS/7TBrainMech/rawlinks/
[ ! -d $rawloc/$subj_date/ ] && echo "$rawloc/$subj_date/ missing!" && exit 1
mrid=$( readlink $(find  $rawloc/$subj_date/ -type l -print -quit) | sed 's:.*Mech/\([^/]*\)/.*:\1:')
[ -z $mrid ] && echo "cannot find $subj_date in $rawloc" >&2 && exit 1

#csi_si1_csv="/Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/$mrid/SI1/spreadsheet.csv"
csi_si1_csv=$(find -L $BOXMRSI -name spreadsheet.csv -ipath "*/$mrid*")

# file indicating what slice was used. eg. 20181217Luna1/PFC_registration_out/17_10_FlipLR.MPRAGE
#reg_out_file=$(find $(dirname $(dirname "$csi_si1_csv"))/*registration_out/ \
#   -maxdepth 1 -type f -iname '[0-9][0-9]*MPRAGE' -print -quit)
reg_out_file=$(find -L $BOXMRSI -ipath "*/$mrid*/*registration_out/*" -iname '[0-9][0-9]*MPRAGE' -print -quit )

check_file(){
    file="$1";shift
    msg="$1";shift
    [ -n "$file" -a -r "$file" ] && return
    echo "$subj_date ($mrid): no file: $file"
    echo "  # fix: $msg" 
    exit 1
}

csi_json="$scriptdir/csi_settings.json"

check_file "$scout"                     "run ./01_get_slices.bash $subj_date"
check_file "$FSdir/mri/aparc+aseg.mgz"  "run ../FS/002_fromPSC.bash"
check_file "$csi_si1_csv"               "run ../001_rsync_MRSI_from_box.bash"
check_file "$csi_json"                  "see https://github.com/LabNeuroCogDevel/7TBrainMech_scripts/blob/master/mri/MRSI/csi_settings.json"
#check_file "$reg_out_file"              "$BOXMRSI/**$mrid/regirstion_out/*MPRAGE is a product of MRSI box, cannot determine slice ($reg_out_file)"

## determine slice
scout_slice_num=""
[  -n "$reg_out_file" ] && [[ "$(basename $reg_out_file)" =~ ^([0-9]+)_ ]] && scout_slice_num=${BASH_REMATCH[1]}
if [ -z "$scout_slice_num" ]; then
   echo "WARNING: DNE $BOXMRSI/**$mrid/regirstion_out/*MPRAGE is a product of MRSI box"
   echo "trying to get slice number from scout"
   slices=$(3dNotes $scout 2>/dev/null |perl -lne 'print $1 if m/Slice_(\d+)$/')
   case $slices in
     66) scout_slice_num=17;;
     82) scout_slice_num=21;;
     *) echo "dont know what to do with $slices slices (not 17 or 21!)";;
   esac 
fi
[ -z "$scout_slice_num" ] && echo "no slice number in $reg_out_file" >&2 && exit 1

echo "$subj_date $mrid: using slice $scout_slice_num"

[ -n "$DRYRUN" ] && exit

[ ! -d $data_dir ] && mkdir $data_dir

# recorde slice number
[ ! -r $data_dir/scout_slice_num.txt ] && echo $scout_slice_num > $data_dir/scout_slice_num.txt


mscript=$data_dir/fs_csi_${subj_date}.m  
[ -r $mscript ] && echo "rm $mscript; # have but didnt finish. rm mscrip to rerun" && exit 
############################ depends #############################################

# where are the matlab toolboxes and code
matlabcode_dir=$scriptdir/Codes_yj/
spm_dir=/opt/ni_tools/matlab_toolboxes/spm12/
nifti_dir=$matlabcode_dir/NIfTI

# where to save everything
# where to save the grouped FS parcelations rois
ROI_dir=$data_dir/parc_group
# where to save matlab log
log_reg=$data_dir/Log_Regression.out
# No FLAIR, so empty filename
filename_flair=""; 


## UNUSED, prob thres (should be between 0 and 1)
thresh_total=0.75     # GM + WM > thresh_total 
thresh_maxtissue=0.5  # Fraction of Max Region > thresh_maxtissue

###################### make files   ############################################

[ -e $log_reg ] && echo "Deleting log file for linear regression"   && rm $log_reg
# is this a good idea?
[ -d $ROI_dir ] && echo "Deleting parc grouping directory $ROI_dir" && rm -r $ROI_dir
[ ! -d $ROI_dir ] && mkdir -p $ROI_dir


cd $data_dir
mgz2nii_RAS() { 
   # freesurfer mgz into nii (w/ RAS matrix orientation)
   mri_convert --in_type mgz --out_type nii --out_orientation RAS \
      $FSdir/mri/$1.mgz $1.nii
   # AFNI converts NIFTI_datatype=8 (INT32) to FLOAT32
   3dcopy $1.nii  $ROI_dir/$1.nii
   # remove mri_convert (INT32) version
   rm $1.nii
}

mgz2nii_RAS orig
mgz2nii_RAS aparc+aseg
mgz2nii_RAS wmparc

# scout in data dir for matlab resize
3dcopy -overwrite $scout scout.nii
3dresample -overwrite -dxyz 1 1 1 -inset scout.nii -prefix scout_resize.nii -rmode Cu

## csi_template used to make nifti from 2d mat csi outputs
# 3dcopy -overwrite $(dirname $scout)/s17/9x9mm.nii.gz csi_template.nii
# get slice number as it were 0 index. prob 17 is now 16
slice_num_0=$scout_slice_num
let slice_num_0-=1
# get voxel size from json config file. likely: 9 9
voxsize=($(jq '.csi_vox|map(tostring)|join(" ")' -r "$csi_json"))

3dZcutup -keep $slice_num_0 $slice_num_0 $scout
3dresample -dxyz ${voxsize[@]} 3 -input zcutup+orig.HEAD  -prefix csi_template.nii -overwrite
rm zcutup+orig*

## do the meat of it in matlab

cat > $mscript <<EOF
% generated by $0 ($(pwd)) on $(date)
addpath('$nifti_dir');
addpath('$spm_dir');

matlabcode_dir='$matlabcode_dir';
ROI_dir='$ROI_dir';
data_dir='$data_dir';
roi_file='$scriptdir/roi.txt';
csi_json='$csi_json';
filename_scout='scout.nii';
filename_flair='$filename_flair';

csi_csv = '$csi_si1_csv';
csi_nii_out = fullfile(data_dir,'csi_val');
csi_template = fullfile(data_dir,'csi_template.nii');

cd(matlabcode_dir);
grouping_masks(roi_file, ROI_dir) 
% img_resize_ft(data_dir,filename_scout); done with 3dresample instead
spm_reg_ROIs(ROI_dir, roi_file, fullfile(data_dir,filename_scout), filename_flair) 

fprintf('labeling FS rois in csi space (2d_csi_ROI and struct_ROI)\\n')
csi_roi_label(ROI_dir, roi_file, csi_json, filename_flair,$scout_slice_num)
% makes 2d_csi_ROI and struct_ROI directories

% make niftis
fprintf('making nii from %s\\n',data_dir)
csi_2d_dir = fullfile(data_dir,'2d_csi_ROI');
dir2d_to_niis(csi_2d_dir,csi_2d_dir, csi_template);

% for csi data too
fprintf('converting spreadsheet to nii (%s -> %s)\\n',csi_csv, csi_nii_out)
SI1_to_nii(csi_csv, csi_template, csi_nii_out);
EOF

echo "# running $(pwd)/$mscript"

### actually run!
# -nodesktop -nosplash 
matlab -nodisplay -r "try, ${mscript%.m},catch e, disp(e); end; quit" |tee $log_reg

# put niftis together for easy viewing
3dbucket -overwrite -prefix all_csi.nii.gz csi_val/*nii
3dbucket -overwrite -prefix all_probs.nii.gz 2d_csi_ROI/*nii
3drefit -relabel_all_str \
  "$(ls 2d_csi_ROI/*nii |
     perl -MFile::Basename -pe '
       $_=basename($_,".nii");
       s/^\d+_(.*)_FlipLR/\1/;
       s/csivoxel.// ')" \
   all_probs.nii.gz
[ ! -r ../mprage_in_slice.nii.gz ] && ln -s ../mprage_in_slice.nii.gz ./
