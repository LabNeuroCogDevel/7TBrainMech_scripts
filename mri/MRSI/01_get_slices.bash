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

lsscout(){ ls -d $1/*PFC-gre-field-mapping-MCxx-B0map-33_165 2>/dev/null || ls -d $1/*_66 2>/dev/null || ls -d $1/*_82 2>/dev/null || :; }

# run as lncd
if [ "$(whoami)" != "lncd" -a $(hostname) == "rhea.wpic.upmc.edu" ]; then 
    sudo -E su -l lncd $(readlink -f $0) $@
    exit
fi
! command -v flirt >/dev/null && echo no fsl, export path && exit 1

# setup sane bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
cd $(dirname $(readlink -f $0))



# can take a luna_date or directory. if given nothing find all directories
if [ $# -lt 1 ]; then
  cat <<HEREDOC
USAGE:
  $0 10129_20180917 11299_20180511
  $0 /Volumes/Hera/Raw/BIDS/7TBrainMech/rawlinks/11299_20180511/
  $0 all # look in \$RAW_PATH/[12]*/
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
   "11757_20190322/0025_B0Map33Slice_209"  # no HC, weird scout numbers. visual inspected. angle a bit weird
   "11731_20190201/0023_B0Scout33Slice_66" # early 66 to be ignored
   "11760_20190311/0023_B0Scout33Slice_66" # mixed date data, this is from separate scout dir
   "11799_20190816/0025_B0Scout33Slice_66" # weird 0025_B0Scout33Slice_66  0026_B0Scout33Slice_33  0027_B0Map33Slice_165  0028_B0Map33Slice_33  0029_B0Map33Slice_16
   "11782_20190930/0023_B0Scout33Slice_66" # no HPC? werid 82 dcm scan at 002
   "11770_20190722/0027_B0Scout33Slice_66" # many B0Scouts, 4 possible. this one looks like the right angle
   "11772_20190719/0016_B0Scout33Slice_66" # many B0Scouts, only this one has 66. positioning looks okay
   "11768_20190913/0027_B0Scout33Slice_66" # only option
   "11767_20190729/0024_B0Scout33Slice_66" # looks like right orentation, next is 0036 and is hippo
   "11735_20190719/0023_B0Scout33Slice_66" # both this and 0016 orented for pfc. use later one
   "11737_20190510/0039_B0Scout33Slice_66" # TWO SESSIONS: some linked at dir, others at dcm. first one (dcm links) is oriented 
   "11748_20190401/0023_B0Scout33Slice_66" # other two are hpc
   "11543_20180804/0024_B0Scout33Slice_66" # also have  no protocol name version 0024__66
   "11728_20190114/0025_B0Map33Slice_330" # has way too many dicoms. but 2nd echo will be used. looks okay
   # something weird. picking e2 looks okay (orientation is okay, and is not phase)
   "11759_20190823/0030_B0Map33Slice_495"
   # 20200429 - after using examine_prospect_slice
   "11700_20190406/0028_B0Scout33Slice_66"
   "11816_20200203/0027_B0Map33Slice_165"
   "11791_20191101/0023_B0Scout33Slice_66"
   "11789_20191028/0022_B0Scout33Slice_66"
   # 20200603
   "11675_20200103/0024_B0Scout33Slice_66"
   "11766_20191025/0027_B0Scout33Slice_66"
   "11810_20191212/0025_B0Scout33Slice_66"
   "11811_20200124/0023_B0Scout33Slice_66" # 4 choices. this is only mag img in cor orientation
   # 20200604
   "11668_20180723/0003_B0Scout41Slice_82" # only one. looks like PFC scout 
   "11754_20190304/0019_B0Scout33Slice_66" # 20200713 - this was corectly chosen, but FOV is bad?
                                           # hard code here just for this note
   # 20200715
   "11323_20191101/0038_B0Scout33Slice_66" # have 34 and 38. pick later. 47 is hc. 2 and 8 are 82dcms
   # 11681_20181012 # no csi
   # 11668_20180723 # no csi
   "11793_20210426/0016_B0Scout33Slice_66" # failed scan. comming back later. check PFC

   #"11756_20190325/0025_B0Scout33Slice_66" # have an early 82dcm
   "11756_20190325/0024_B0Scout33Slice_66" # linked from 20190325Luna1/scouts/s024_B0Scout33Slice
   # 20200901 - T1 at end
   "11713_20200821/0017_B0Scout33Slice_66"
   "11681_20200731/0019_B0Scout33Slice_66"
   # 20201105 - 2 Hc scouts. first good 66 is PFC
   "11790_20190916/0024_B0Scout33Slice_66"
   # 20211103
   "11803_20210816/0015_B0Scout33Slice_66"
   "11725_20200724/0017_B0Scout33Slice_66" # log says 15, but 17 is right after
   "11630_20210717/0016_B0Scout33Slice_66" # log says 13, but 16 is only avail
   "11813_20210625/0018_B0Scout33Slice_66" # log says 20, but 18 is only
   "11799_20210621/0017_B0Scout33Slice_66" # reshiming threw off count. scanlog says "13"
   "11732_20210619/0014_B0Scout33Slice_66" # sheet has 17, but dne
   "11689_20210605/0017_B0Scout33Slice_66" # sheet has 14, but only 17 exists
   "11824_20210522/0020_B0Scout33Slice_66" # sheet=17
   "11821_20210521/0024_B0Scout33Slice_66" # sheet=15 only 2, ended early
   "11865_20210517/0019_B0Scout33Slice_66" # sheet=14, only 2
   "11790_20210430/0016_B0Scout33Slice_66" # only 2
   "11864_20210220/0026_B0Scout33Slice-RSI_66" # no notes. lots of extra scans. 27 looks like phase
   "11822_20210218/0027_B0Scout33Slice_66" # sheet=27, also have 37 and 44. go wtih sheet value 
   "11515_20201109/0016_B0Scout33Slice_66" # only 2
   "11751_20201105/0016_B0Scout33Slice_66" # only 2, sheet=23 (but that's BOLD)
   "11734_20201029/0029_B0Scout33Slice_66" # 2 start shims. only pfc/no hc
   "11750_20201023/0023_B0Scout33Slice_66" # 2 shims at start. only pfc/no hco
   "11632_20191017/0030_B0Map33Slice_165"  # scouts dont have 2 echos?
   # 20211123
   11683_20211106/0017_B0Scout33Slice_66   # only 1 exists. incomplete scan maybe okay. would be discared anway

   # 20221004
   11707_20201009/0017_B0Scout33Slice_66

   # 20221012 - early in the sequence? before task. but later look like Hc
   11801_20220602/0015_gre-field-mapping-MCxx-B0map-33_165

   # 20221102 - 0007 is default but looks like Hc. use second scout (AO identified)
   11834_20210524/0016_B0Scout33Slice_66

   # 20221107
   11751_20220618/0018_gre-field-mapping-MCxx-B0map-33_165
   11818_20220609/0019_gre-field-mapping-MCxx-B0map-33_165
   11716_20220616/0017_gre-field-mapping-MCxx-B0map-33_165
   11734_20220610/0018_gre-field-mapping-MCxx-B0map-33_165

   # 20221229. update 20230928
   11823_20221202/0018_PFC-gre-field-mapping-MCxx-B0map-33_330 # repeat b/c motion on first

   # 20230106
   11715_20221118/0018_PFC-gre-field-mapping-MCxx-B0map-33_330 # 330 not 165, seqs 16 and 18

   # 20230928 - picked second. assuming better than first
   11770_20221208/0017_PFC-gre-field-mapping-MCxx-B0map-33_330
   11810_20221117/0017_PFC-gre-field-mapping-MCxx-B0map-33_330

   # FF scans
   "20180824FF2/0023_B0Scout33Slice_66"
   )
   # 11668_20180728 # DNE
   # 11661_20180720 # run twice. only picked up second runn. maybe okay to use only one
   # 11760_20190311/002[468] # whicch?

skiplist=( "11793_20210726 2ndsession no PFC"
"11695_20200904 cancelled"
"11722_20200713 cancelled"
"11716_20200904 cancelled"
"11681_20181012 hc makeup but could not run hc"
"11748_20201109 same subject as 11515_20201109 -- double lunaid")

for sraw in "${list[@]}"; do

   # is this a luna_date
   if [[ $STUDY_PATH =~ 7TBrainMech ]]; then
      ! [[ $(basename "$sraw") =~ [0-9]{5}_[0-9]{8} ]] && echo "# no lunadate in '$sraw'" >&2 && continue
      ld8=$BASH_REMATCH
   else
      # Fabio subject
      ld8=$(basename "$sraw")
   fi

   # skip known bad/missing
   for skip in "${skiplist[@]}"; do
      [[  "$skip" =~ ^$ld8 ]] || continue
      echo "# $skip"
      continue 2
   done

   # maybe we gave a lunaid_date instead of a directoyr?
   [ ! -d $sraw ] && sraw=$RAW_PATH/$sraw
   [ ! -d $sraw ] && echo "# bad input: no directory like $sraw" >&2 && continue


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
   slicedirs=($(lsscout "$sraw"))
   n=${#slicedirs[@]}
   if [ -n "$slice_dcm_dir" ]; then 
      echo "# manually setting $ld8 $slice_dcm_dir" >&2
   elif [ $n -eq 2 ]; then
      slice_dcm_dir=${slicedirs[0]}
   elif [[ $n -eq 1 && ${slicedirs[*]} =~ PFC ]]; then
      slice_dcm_dir=${slicedirs[0]}
   else
      echo "# $ld8: bad slice raw dir num ($n of expect 2, '${slicedirs[*]}' not like PFC-)" >&2
      # if no matches. point to raw directory
      [ $n -eq 0 ] && echo "search for missing link in '$(dirname $(readlink -f $(ls -d $sraw/*|sed 1q)))';
        also ../BIDS/000_dcmfolder_201906fmt.bash" && continue
      echo "# 1. pick best using " >&2
      echo "  ../MRSI_roi/examine_prospect_slices $sraw/*{82,66}*" >&2
      echo " " >&2
      (ls -d ${sraw}/*{82,66,PFC-*165}*||:) |sed 's/^/\t/' >&2
      echo "# 2. hardcode best protocol directory within 'force_dir' in $0" >&2
      echo "### for what it's worth" >&2
      echo "    from /Volumes/L/bea_res/7T/fMRI/7T_fMRI_Scan_Log.xlsx has this seq number+note:" >&2
      lncddb "select id, vtimestamp, measures->'PFC_Spectroscopy', measures->'Notes'
              from visit_task
              natural join visit
              join enroll on visit.pid = enroll.pid and etype like 'LunaID'
              where task like 'ScanLog' and
              id like '${ld8%_*}' and
              to_char(vtimestamp,'YYYYMMDD') like '${ld8#*_}' and
              vtype like '%Scan%';" >&2


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
      [ -r slice_pfc_e2_ph.nii.gz ] && echo "# $ld8 $slice_dcm_dir scout is phase instead of mag?! (b/c $this_dir/slice_pfc_e2_ph.nii.gz)  consider hardcoding a different scout image in $0:force_dir?!" && continue
      eval $cmd
      if [ -r slice_pfc_e2.nii.gz -a ! -r slice_pfc.nii.gz ]; then
          mvcmd="cp slice_pfc_e1.nii.gz slice_pfc.nii.gz" 
          eval $mvcmd
          cmd="$cmd; $mvcmd" 
          # 20221012 changing from e2 to e1.
          echo "WARNING: $ld8 has at least two different echos in scout. picked e1 on CM's suggestion. prev used e2"
          echo -e "$ld8\t$(date +%F)\tscout dcm2niix has 2 echos, picked _e1!" >> warning_note.txt
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
     niinote mprage_in_slice.nii.gz flirt -ref slice_pfc.nii.gz -in ppt1/mprage.nii.gz -o mprage_in_slice.nii.gz -omat mprage_to_slice.mat ||
        echo "# $ld8: have $(pwd)/slice_pfc_native.nii.gz" >&2

   # 3dcalc -a slice_pfc.nii.gz -expr 'equals(k,17) * a' -prefix spfc_17.nii.gz -overwrite
   # provide roi in mprage and slice space. former to check if latter is bad
   if [ ! -r roi_slice.nii.gz ]; then
      niinote roi_mprage.nii.gz \
         applywarp -i $mni_atlas -o roi_mprage.nii.gz -r ppt1/mprage.nii.gz     -w ppt1/template_to_subject_warpcoef.nii.gz --interp=nn
      niinote roi_slice.nii.gz \
         applywarp -i $mni_atlas -o roi_slice.nii.gz  -r slice_pfc.nii.gz  -w ppt1/template_to_subject_warpcoef.nii.gz --postmat=mprage_to_slice.mat --interp=nn
      echo "# made $(pwd)/roi_slice.nii.gz"
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

