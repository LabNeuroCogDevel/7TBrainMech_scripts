#!/usr/bin/env bash


#
# find slice per subject
#  - no arguments, run for everyone
#  - subject_date as arguments, run for just those
#
# 1. constructs pfc slice (66dicoms, 33 slices)
# 2. get mat for slice <-> mprage  linear warp
# 3. bring slice roi atlas into mprage and slice space (nonlinear)
# depends on preprocessFunctional having been already run

lsscout(){ ls -d $1/*_66 2>/dev/null || ls -d $1/*_82 2>/dev/null ; }

# run as lncd
if [ "$(whoami)" != "lncd" -a $(hostname) == "rhea.wpic.upmc.edu" ]; then 
    sudo -E su -l lncd $(readlink -f $0) $@
    exit
fi
! command -v flirt >/dev/null && echo no fsl, export path && exit 1

# setup sane bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
cd $(dirname $0)



# can take a luna_date or directory. if given nothing find all directories
if [ $# -lt 1 ]; then
  cat <<HEREDOC
USAGE:
  $0 10129_20180917 11299_20180511
  $0 /Volumes/Hera/Raw/BIDS/7TBrainMech/rawlinks/11299_20180511/
  $0 all
  $0 STUDY=FF 20180125FF
HEREDOC
  exit 1
fi

STUDY=7TBrainMech
[[ $1 =~ ^STUDY=(.*)$ ]] && STUDY=${BASH_REMATCH[1]} && shift

case $STUDY in
   FF)
      STUDY_PATH="/Volumes/Hera/Projects/Collab/7TFF/"
      RAW_PATH="/Volumes/Hera/Raw/BIDS/7TFF/rawlinks"
      ;;
   *) 
      STUDY_PATH=/Volumes/Hera/Projects/7TBrainMech
      RAW_PATH=/Volumes/Hera/Raw/BIDS/7TBrainMech/rawlinks
      ;;
esac

# where are things
subjdir="$STUDY_PATH/subjs"
t1root="$STUDY_PATH/pipelines/MHT1_2mm"
mni_atlas="/Volumes/Hera/Projects/7TBrainMech/slice_rois_mni_extent.nii.gz"
#N.B. need to resample atlas w/ 2mm template so extent matched. bad warp otherwise

case $1 in
   all) list=($RAW_PATH/[12]*/);;
   missing) list=( $(for i in $(cat missing_subjects.txt ); do grep $i txt/ids.txt ; done|cut -f 1 -d' '));;
   *) list=($@);;
esac


for sraw in ${list[@]}; do
   # maybe we gave a lunaid_date instead of a directoyr?
   [ ! -d $sraw ] && sraw=$RAW_PATH/$sraw
   [ ! -d $sraw ] && echo "# bad input: no directory like $sraw" >&2 && continue

   # is this a luna_date
   if [[ $STUDY_PATH =~ 7TBrainMech ]]; then
      ! [[ $(basename $sraw) =~ [0-9]{5}_[0-9]{8} ]] && echo "# no lunadate in '$sraw'" >&2 && continue
      ld8=$BASH_REMATCH
   else
      # Fabio subject
      ld8=$(basename $sraw)
   fi



   force_dir=( \
   "10195_20180129/0023_B0Scout33Slice_66"
   "11451_20180216/0024_B0Scout41Slice_82"
   "11685_20180907/0031_B0Scout33Slice_66"
   "11682_20180907/0027_B0Scout33Slice_66"
   "11633_20180426/0023_B0Scout33Slice_66" # no HC
   "11668_20180702/0023_B0Scout33Slice_66" # no HC
   "11634_20180409/0021_B0Scout41Slice_82" # run after mprage,r2' - no 66 there
   "11626_20180312/0024_B0Scout41Slice_82"
   "10644_20180216/0022_B0Scout41Slice_82" 
   "11627_20180323/0023_B0Scout33Slice_66" 
   "11681_20180921/0023_B0Scout33Slice_66" 
   "11688_20181215/0023_B0Scout33Slice_66" # have 002_82, 0023_66 -- weird
   "11724_20190104/0023_B0Scout33Slice_66" # no HC
   "11752_20190315/0025_B0Scout33Slice_66" # no HC
   "11634_20180409/0021_B0Scout41Slice_82" # 3, 82 at 002
   "11757_20190322/0028_B0Map33Slice_66"   # no HC
   "11731_20190201/0023_B0Scout33Slice_66" # early 66 to be ignored
   "11760_20190311/0023_B0Scout33Slice_66" # mixed date data, this is from separate scout dir
   "11728_20190114/0028_B0Map33Slice_66"   # 3 in a row, use the last before rest
   # FF scans
   "20180824FF2/0023_B0Scout33Slice_66"
   )
   # 11668_20180728 # DNE
   # 11661_20180720 # run twice. only picked up second runn. maybe okay to use only one
   # 11760_20190311/002[468] # whicch?
   # missing dicoms!
   #elif [ $ld8 == "11543_20180804" ]; then
   #   slice_dcm_dir="$sraw/"


   slice_dcm_dir=""
   for fd in ${force_dir[@]}; do
      # TODO if ld8 is FF -- will need to fix
      [ $ld8 == $(dirname $fd) ] || continue
      slice_dcm_dir=$sraw/$(basename $fd)
      break
   done

   # do we have a single scout to work with
   n=$( (lsscout "$sraw" || echo -n) |wc -l ) 
   if [ -n "$slice_dcm_dir" ]; then 
      echo "# manually setting $ld8 $slice_dcm_dir" >&2
   elif [ $n -eq 2 ]; then
      slice_dcm_dir=$(lsscout "$sraw" |sed 1q)
   else
      echo "# $ld8: bad slice raw dir num ($n $sraw/*{82,66}*, expect 2). hardcode fix 'force_dir' in $0" >&2
      continue
   fi


   # is preprocess mprage done?
   mprage=$t1root/$ld8/mprage.nii.gz
   [ ! -r $mprage ] && echo "# $ld8: no t1. run: 'pp 7TBrainMech_mgsencmem MHT1_2mm $ld8' (missing $mprage)" >&2 && continue
   wcoef=$t1root/$ld8/template_to_subject_warpcoef.nii.gz 
   [ ! -r $wcoef ] && echo "# $ld8: no warp coef. rerun 'pp 7TBrainMech MHT1_2mm $ld8' (missing $wcoef)" >&2 && continue

   ## reconstruct slice dicom
   this_dir="$subjdir/$ld8/slice_PFC"
   echo "# $ld8 $slice_dcm_dir to $this_dir"

   # make slice directory if we need to
   [ ! -d $this_dir ] && mkdir -p $this_dir
   cd $this_dir

   # create nifti if we need to
   #[ $(find . -maxdepth 1 -type f  -iname '*.nii.gz' |wc -l ) -gt 0 ] || dcm2niix_afni -o ./ -f slice_pfc $slice_dcm_dir
   cmd="dcm2niix_afni -o ./ -f slice_pfc $slice_dcm_dir"
   if [ ! -r slice_pfc.nii.gz ]; then 
      [ -r slice_pfc_e2_ph.nii.gz ] && echo "# $ld8 $slice_dcm_dir scout is phase instead of mag?! consider hardcoding a different scout image in $0:force_dir?!" && continue
      eval $cmd
      if [ -r slice_pfc_e2.nii.gz -a ! -r slice_pfc.nii.gz ]; then
          mvcmd="mv slice_pfc_e2.nii.gz slice_pfc.nii.gz" 
          eval $mvcmd
          cmd="$cmd; $mvcmd" 
          echo "WARNING: $ld8 has at least two different echos in scout. picked e2 because it had more contrast one time"
          echo -e "$ld8\t$(date +%F)\tscout dcm2niix has 2 echos, picked _e2!" >> warning_note.txt
      elif find -maxdepth 1 -iname 'slice_pfc_*.nii.gz' -type f; then
         echo "# $ld8 BAD DCM2NII: $slice_dcm_dir has unexpected nii convertion: $(find -maxdepth 1 -iname 'slice_pfc_*.nii.gz' -type f)"
         continue
      fi
      AFNI_NO_OBLIQUE_WARNING="YES" 3dNotes -h "$cmd" slice_pfc.nii.gz 
   fi
   # 20190822 have e1 and e2 for 11575_20190708
   [ ! -r slice_pfc.nii.gz ] && echo "$ld8: 'dcm2niix $slice_dcm_dir' failed!" >&2 && continue

   ## flirt
   # get preproces mprage easily accesible (mprage and warpcoef)
   [ ! -d ppt1 ] && ln -s $t1root/$ld8/ ppt1
   # todo: consider
   #[ ! -r slice_pfc_native.nii.gz -o ! -r slice_pfc_to_native.mat ] && 

   [ ! -r mprage_in_slice.nii.gz -o ! -r mprage_to_slice.mat ] && 
     flirt -ref slice_pfc.nii.gz -in ppt1/mprage.nii.gz -o mprage_in_slice.nii.gz -omat mprage_to_slice.mat ||
        echo "# $ld8: have $(pwd)/slice_pfc_native.nii.gz" >&2

   # 3dcalc -a slice_pfc.nii.gz -expr 'equals(k,17) * a' -prefix spfc_17.nii.gz -overwrite
   # provide roi in mprage and slice space. former to check if latter is bad
   if [ ! -r roi_slice.nii.gz ]; then
      applywarp -i $mni_atlas -o roi_mprage.nii.gz -r ppt1/mprage.nii.gz     -w ppt1/template_to_subject_warpcoef.nii.gz --interp=nn
      applywarp -i $mni_atlas -o roi_slice.nii.gz  -r slice_pfc.nii.gz  -w ppt1/template_to_subject_warpcoef.nii.gz --postmat=mprage_to_slice.mat --interp=nn
   fi

   # make a nifti that is just slice 17 at 24x24 voxels (9x9mm)
   # to be used with matlab later
   if [ ! -r s17/9x9mm.nii.gz ]; then
      [ ! -d s17 ] && mkdir s17
      cd s17
      3dZcutup -keep 16 16 ../slice_pfc.nii.gz
      #3dcopy zcutup+orig.HEAD s17.nii.gz -overwrite
      3dresample -dxyz 9 9 3 -input zcutup+orig.HEAD  -prefix 9x9mm.nii.gz -overwrite
      rm zcutup+orig*
   fi

done

