#!/usr/bin/env bash
#
# warp freesurfer to native space funcs using preprocessfunctional files
#
# 20220311WF - init
#
[ -v DRYRUN ] && DRYRUN=echo || DRYRUN=
warn(){ echo "$@" >&2; }
export AFNI_NIFTI_TYPE_WARN=NO
# only useful to do for no_warp preproc
func_list(){
   ls -1d /Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_nowarp/1*_2*/
}

# given a nowarp preproc dir, find the related freesurfer mgz file
# first arg should have a subject directory w/luna_date
# second defaults to aparc+aseg.mgz
# could be high or low res. prefer high
funcdir2fsdir(){
   local subject_dir=/Volumes/Hera/preproc/7TBrainMech_rest/FS7.2
   local ld8="$(ld8 "$1")"; shift
   [ -z "$ld8" ] && warn "no ld8 in $1" && return 1
   local name=aparc+aseg.mgz
   [ $# -ne 0 ] && name="$1"
   # have low and highres. sort to get high first if both
   fs_file=$(find $subject_dir/*/$ld8/mri -iname "$name"|sort |head -n1)
   [ -z "$fs_file" ] && warn "no file for $subject_dir/*/$ld8/mri/$name" && return 1
   echo "$fs_file"
}

# stick /nii/ in and change .mgz to .nii.gz
new_fs_name(){
   local fs_file="$1"; shift
   local dname="$(dirname $fs_file)"/nii
   ! test -d $dname && mkdir $_
   local bname=$(basename ${fs_file/.nii.gz} .mgz)
   local nii_file="$dname/$bname.nii.gz"
   echo $nii_file
}
# covert to nii.gz with niinote used to annotate
# stash new files in mri/nii/
mgz2nii(){
   local fs_file="$1"
   nii_file=$(new_fs_name "$fs_file")
   if [ ! -r $nii_file ]; then
      warn "# making $nii_file"
      $DRYRUN niinote $nii_file mri_convert "$fs_file" "$nii_file" >&2
   fi
   echo "$nii_file"
}
# find mprage
find_mprage(){
   local pre_d="$1"
   # just the first match and only the match part. no filenames
   local mprage=$(grep -m1 -hPo '/[^ ]*/mprage_bet.nii.gz' $pre_d/*log* |sed 1q)
   [ -z "$mprage" -o ! -r "$mprage" ] && warn "cannot find mprage '$mprage' from logs of $pre_d" && return 1
   echo $mprage
}

# freesurfer is RPI and 256x256x256. mprage used by preproc is not. dims must match
fs2anat(){
   local fs="$1";shift
   local anat="$1";shift
   local out="$(dirname $fs)/mprage_$(basename ${fs})"
   [ ! -r $out ] && 
     $DRYRUN 3dresample -inset "$fs" -master "$anat" -prefix "$out"  >&2
   echo $out
}

# use preprocessfunctional's transform mat and reference
# to pull likely FS in subjects anat into 
anat2func(){
   local anat_file="$1"; shift
   local preproc_d="$1"; shift
   local bname="$(basename $anat_file)" # probably mprage_.....
   local out="$preproc_d/warps/func_${bname/mprage_/}"
   [ -r $out ] && warn "# have $out" && return 0
   ! test -d "$(dirname $out)" && $DRYRUN mkdir "$_"

   local ref="$preproc_d/mc_target.nii.gz"
   local mat="$preproc_d/transforms/struct_to_func.mat"
   for need in $ref $mat $anat_file; do
     test ! -r "$need" && warn "cannot read $_" && return 1
   done
   $DRYRUN niinote "$out" \
      applywarp --in=$anat_file --out=$out --interp=nn --ref=$ref --premat=$mat
   echo $out
}
fs_func_warp_one(){
   [ $# -ne 2 ] && warn "$FUNCNAME preproc_d fs_file" && return 1
   local preproc_d="$1"; shift
   local fs_file="$1"; shift
   [ ! -d "$preproc_d" ] && warn "'$preproc_d' should be a directory!" && return 1
   [ ! -r "$fs_file" ] && warn "'$fs_file' should be just the filename (not path) of FS atlas" && return 1
   local ld8_fs_file=$(funcdir2fsdir "$preproc_d" $fs_file) || return 1
   # /Volumes/Hera/preproc/7TBrainMech_rest/FS7.2/highres/10129_20180917/mri/aseg.mgz
   local fs_nii="$(mgz2nii "$ld8_fs_file")"
   # /Volumes/Hera/preproc/7TBrainMech_rest/FS7.2/highres/10129_20180917/mri/nii/aparc+aseg.nii.gz 
   echo "# $fs_nii warp to $preproc_d"
   local fs_res=$(fs2anat "$fs_nii" $mprage_bet)
   # local out="$(dirname $fs)/mprage_$(basename ${fs})"
   anat2func "$fs_res" "$preproc_d"
}

_fs_func_warp() {
  mapfile -t FUNCDIRS < <(func_list)
  for d in ${FUNCDIRS[@]}; do
    mprage_bet="$(find_mprage $d)" || continue

    # useful to have what the mprage should be in func
    anat2func ${mprage_bet/_bet/} $d

    for fs_file in aparc+aseg.nii.gz {l,r}h.hippoAmygLabels-T1.v21{.CA,.FS60,.HBT}.mgz; do
       ld8_fs_file=$(funcdir2fsdir "$d" $fs_file) || continue
       # /Volumes/Hera/preproc/7TBrainMech_rest/FS7.2/highres/10129_20180917/mri/aseg.mgz
       fs_nii="$(mgz2nii "$ld8_fs_file")"
       # /Volumes/Hera/preproc/7TBrainMech_rest/FS7.2/highres/10129_20180917/mri/nii/aparc+aseg.nii.gz 
       echo "# $fs_nii warp to $d"
       fs_res=$(fs2anat "$fs_nii" $mprage_bet)
       # local out="$(dirname $fs)/mprage_$(basename ${fs})"
       anat2func "$fs_res" "$d"
    done
  done
  return 0
}

# if not sourced (testing), run as command
if ! [[ "$(caller)" != "0 "* ]]; then
  set -euo pipefail
  trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error $e"' EXIT
  _fs_func_warp "$@"
  exit $?
fi

####
# testing with bats. use like
#   bats ./fs_func_warp.bash --verbose-run
####
if  [[ "$(caller)" =~ /bats.*/preprocessing.bash ]]; then
function find_FS_test { #@test
    run funcdir2fsdir "/Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_nowarp/10129_20180917/" aseg.mgz
    echo $output >&2
    [[ $output == "/Volumes/Hera/preproc/7TBrainMech_rest/FS7.2/highres/10129_20180917/mri/aseg.mgz" ]]
}
function no_FS_test { #@test
    run funcdir2fsdir "/Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_nowarp/10129_20180917/" asegDNE.mgz
    echo "$output" >&2
    [[ $output =~ "no file" ]]
}
function mprage_test { #@test
    run find_mprage "/Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_nowarp/10129_20180917/"
    warn $output
    [[ $output =~ mprage_bet.nii.gz$ ]]
}
function newname_test { #@test 
   run new_fs_name /Volumes/Hera/preproc/7TBrainMech_rest/FS7.2/highres/10129_20180917/mri/aparc+aseg.mgz
   warn $output
   [[ $output == /Volumes/Hera/preproc/7TBrainMech_rest/FS7.2/highres/10129_20180917/mri/nii/aparc+aseg.nii.gz ]]
}
fi
