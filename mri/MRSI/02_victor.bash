#!/bin/bash

set -euo pipefail

################################## USER INPUT ##################################
# directory where all the MATLAB codes for this script are located in
matlabcode_dir=$(cd $(dirname $0);pwd)/Codes_yj/
spm_dir=/opt/ni_tools/matlab_toolboxes/spm12/

flair_flag=0 # 1 if FLAIR exists, 0 if not
#filename_flair=20141028_154029AXIALFLAIRs007a1001.nii # comment out this line if FLAIR doesn't exist

scout_slice_num=[13.7,17,20.3,23.7]  # slice numbers of SCOUT corresponding to the center positions of CSI acquisition (add 1 to Siemens Slice number in header)
#csi_slice_num=[2,4,1,3]  # slice numbers of CSI corresponding to scout_slice_num (it should be appeared in the filename of MRSI excel file in format '_SI*')
csi_size=[24,24]  # matrix size of CSI [anterior-posterior direction, left-right direction]
csi_FOV=[240,240]  # FOV of CSI in [mm] [anterior-posterior direction, left-right direction]
csi_thk=8  # slice thickness of CSI in [mm]
scout_FOV=[240,240]  # FOV of B0 scout in [mm] [anterior-posterior direction, left-right direction]
scout_thk=3  # distance between two consecutive slices of B0 scout in [mm] (slice thickness + gap between two slices)

thresh_total=0.75  # GM + WM > thresh_total (should be between 0 and 1)
thresh_maxtissue=0.5  # Fraction of Max Region > thresh_maxtissue (should be between 0 and 1)

#filename_MRSI=spreadsheet  # MRSI excel file name after excluding '_SI*'

################################################################################


########################### script input #######################################
[ $# -eq 0 ] && echo "USAGE: $0 subj_date scout_slice_num" && exit 1

subj_date=$1
subj=${s##_*}
FSdir=/Volumes/Hera/Projects/7TBrainMech/FS/$subj/ 
filename_scout="/Volumes/Hera/Projects/7TBrainMech/subjs/$subj_date/slice_PFC/slice_pfc.nii.gz"
filename_mprage="/Volumes/Hera/Projects/7TBrainMech/pipelines/MHT1_2mm/$subj_date/mprage.nii.gz"
#filename_mprage="/Volumes/Hera/Projects/7TBrainMech/subjs/10129_20180917/slice_PFC/ppt1/mprage.nii.gz"

# TODO: do these have to be .nii instead of .nii.gz ?

[ ! -r $FSdir ] && echo "$subj_date: no FS. run ../FS/002_fromPSC.bash" && exit 1
[ ! -r $filename_scount ] && echo "$subj_date: no scount. run ../MRSI/01_get_slices.bash" && exit 1
[ ! -r $filename_mprage ] && echo "$subj_date: no mprage. run ../010_preproc.bash" && exit 1

data_dir="/Volumes/Hera/Projects/7TBrainMech/subjs/$subj_date/slice_PFC/MRSI"

################################################################################

cd $data_dir
log_file1=$data_dir/Log_Freesurfer.out
log_file2=$data_dir/Log_Regression.out
SUBJECTS_DIR=$data_dir
nifti_dir=$matlabcode_dir/NIfTI
FSout_dir=$data_dir/FS/mri
# ROI_dir=$data_dir/parc_group
ROI_dir=$data_dir/Processed/parc_group

if [ "$flair_flag" -eq "0" ];then
    echo "No FLAIR"
    filename_flair=0
fi

### Delete existing files
#if [ -e $log_file1 ];then
#    echo "Deleting log file for Freesurfer"
#    rm $log_file1
#fi

#if [ -d $SUBJECTS_DIR/FS ];then
#echo "Deleting freesurfer directory"
#rm -r $SUBJECTS_DIR/FS
#fi

if [ -e $log_file2 ];then
echo "Deleting log file for linear regression"
rm $log_file2
fi


### Divide ROI & Resize Scout to 1mm & Coregistration (MPRAGE to Scout) & linear regression
[ ! -d $FSout_dir ] && mkdir -p $FSout_dir
cd $FSout_dir
mri_convert --in_type mgz --out_type nii --out_orientation RAS $FSdir/orig.mgz orig.nii
mri_convert --in_type mgz --out_type nii --out_orientation RAS $FSdir/aparc+aseg.mgz aparc+aseg.nii
mri_convert --in_type mgz --out_type nii --out_orientation RAS $FSdir/wmparc.mgz wmparc.nii

if [ -d $ROI_dir ];then
    echo "Deleting parc_group directory"
    rm -r $ROI_dir
fi

# mkdir $ROI_dir
if [ ! -d $ROI_dir ];then
    mkdir -p $ROI_dir
fi
3dcopy $FSout_dir/orig.nii $ROI_dir/orig.nii
3dcopy $FSout_dir/aparc+aseg.nii $ROI_dir/aparc+aseg.nii
3dcopy $FSout_dir/wmparc.nii $ROI_dir/wmparc.nii

matlab -nodesktop -nosplash -r "nifti_dir=char(strcat('$nifti_dir')); addpath('$nifti_dir'); cd $matlabcode_dir; ROI_dir=char(strcat('$ROI_dir')); parc_grouping_ft_plusExtras('$(eval echo $ROI_dir)'); data_dir=char(strcat('$data_dir')); filename_scout=char(strcat('$filename_scout')); img_resize_ft('$(eval echo $data_dir)','$(eval echo $filename_scout)'); spm_dir=char(strcat('$spm_dir')); addpath('$spm_dir'); matlabcode_dir=char(strcat('$matlabcode_dir')); filename_flair=char(strcat('$filename_flair')); spm_registration_ROI_ft_plusExtras('$(eval echo $matlabcode_dir)','$(eval echo $ROI_dir)','$(eval echo $data_dir)','$(eval echo $filename_scout)',$flair_flag,'$(eval echo $filename_flair)'); parc_at_csi_multi_ft_plusExtras('$(eval echo $data_dir)',$flair_flag,'$(eval echo $filename_flair)',$scout_slice_num,$csi_size,$csi_FOV,$csi_thk,$scout_FOV,$scout_thk);" >$log_file2

