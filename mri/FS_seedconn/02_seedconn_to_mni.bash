#!/usr/bin/env bash
#
# warp seed connectivity REML outs to mni
#
# 20220316WF - init
#
[ -n "${DRYRUN:-}" ] && DRYRUN="echo" || DRYRUN=""
[ ! -v VERBOSE ] && VERBOSE=0
warn(){ echo "$@" >&2; }
verb(){ [ -n "$VERBOSE" ] && warn "$*"; return 0; }

# warp with preproc mat and warpcoef for 7TBrainMech_rest/MHRest_nost_nowarp
# input given as .nii.gz file. will temporary make if have +orig.HEAD version
mni_warp_ld8(){
  in="$1"; shift
  out="$1"; shift
  ld8=$(ld8 "$in")
  [ -r "$out" ] && verb "have '$out'" && return 0
  [ -z "$ld8" ] && warn "no luna_date in '$in'" && return 1
  # make nii.gz version if given afni exixts
  afni_ver=${in/.nii.gz/+orig.HEAD}
  local made_nii=0
  if test ! -r "$in" -a -r "$afni_ver"; then
     verb "making temporary $in"
     $DRYRUN 3dcopy "$afni_ver" "$in"
     made_nii=1
  fi
  # 2 layers of preprocessing. nonlinear (T1<->MNI) in anat. linear (T1<->func) in func
  local preproc_root=/Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_nowarp/
  local template=/opt/ni_tools/standard_templates/mni_icbm152_nlin_asym_09c/mni_icbm152_t1_tal_nlin_asym_09c_brain_2mm.nii
  local func_to_struct=$preproc_root/$ld8/transforms/func_to_struct.mat
  local warp_coef=$preproc_root/../MHT1_2mm/$ld8/mprage_warpcoef.nii.gz
  for f in $template $func_to_struct $warp_coef $in; do
     ! test -r "$f" && warn "cannot warp! missing '$f'" && return 1
  done
  $DRYRUN niinote "$out" applywarp --ref=$template -i "$in" -o "$out" --interp=spline --premat="$func_to_struct" -w "$warp_coef"

  # remove the nifti if it was just created. we dont need to keep two versions of the same file
  [ -r "$afni_ver" -a -r "$in" -a $made_nii -eq 1 ] && $DRYRUN rm "$in"
  return 0
}

list_all_conn(){
   # list all seedconn files but as nii.gz instead of +orig.HEAD. mni_warp_ld8 will make nii.gz out of HEAD if it doesn't exist
   ls /Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_nowarp/1*/seedconn/1*REML_r{nii.gz,+orig.HEAD}| sed 's/+orig.HEAD$/.nii.gz/'
}

_seedconn_to_mni() {
  [[ "$1" == "all" ]] &&
     mapfile -t to_warp < <(list_all_conn) ||
     to_warp=("$@")
  for origspace in "${to_warp[@]}"; do
     mni_warp_ld8 "$origspace" "${origspace/.nii.gz/_mni.nii.gz}"
  done
  return 0
}
usage(){ 
   cat <<-HERE
   $(basename "$0") [all|towarp1.nii.gz towarp2.nii.gz ...]

   warp func files to mni. for seedconnectivty.
   give .nii.gz as input. if DNE but have +orig.HEAD will make temporary nii.gz
   using 7TBrainMech_rest/MHRest_nost_nowarp preprocess mat and warpcoef
   - "all" will find all files
   - otherwise specify file. will make *_mni.nii.gz version in same directory as input file
   - input file must have a lunaid_date somewhere in the path
HERE

}

# if not sourced (testing), run as command
if ! [[ "$(caller)" != "0 "* ]]; then
  set -euo pipefail
  trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error $e"' EXIT
  [ $# -eq 0 ] && usage >&2 && exit 1
  [[ "$1" =~ -h ]] && usage && exit
  _seedconn_to_mni "$@"
  exit $?
fi

####
# testing with bats. use like
#   bats ./02_seedconn_to_mni.bash --verbose-run
####
if  [[ "$(caller)" =~ /bats.*/preprocessing.bash ]]; then
function nold8_warp_test { #@test
   run mni_warp_ld8 x y
   [ "$status" -eq 1 ]
   [[ "$output" =~ no\ luna_date ]]
}
function nofile_warp_test { #@test
   run mni_warp_ld8 12345_20210510.nii.gz y
   [ "$status" -eq 1 ]
   [[ "$output" =~ missing ]]
}
function warp_cmd_test { #@test
   export DRYRUN=echo
   run mni_warp_ld8 /Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_nowarp/10129_20180917/mc_target.nii.gz /tmp/rm_me_test.nii.gz
   [ "$status" -eq 0 ]
   [[ "$output" =~ applywarp ]]
}
function list_test { #@test
   mapfile -t list < <(list_all_conn)
   ! grep HEAD <<< "${list[*]}"
   [ ${#list[@]} -gt 2000 ]
}
fi
