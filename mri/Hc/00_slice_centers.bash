#!/usr/bin/env bash
#
# show hc slice center b/c positioning is worse than expected
#
# 20221017WF - init
#
verb() { [ -n "${VERBOSE:-}" ] && echo -e "$@"; return 0; }
_slice_centers() {
  local nii id out
  nii="$1"
  #ld8=$(ld8 "$nii")
  #[ -z "$ld8" ] && warn "no id in '$nii'" && return 1
  id=$(grep -Po '20\d{6}L[A-Za-z]+[12]?' <<< "$nii")
  [ -z "$id" ] && warn "no id in '$nii'" && return 1
  out=slices/$id.png
  #verb "$id: $nii -> $out"
  test -d slices/ax || dryrun mkdir -p "$_"
  test -r "$out" ||
     dryrun slicer "$nii" -L -a "$out"

  test -r "slices/ax/${id}.png" ||
     dryrun slicer "$nii" -L -z 0.5 "$_"
  return 0
}

_slicemain(){
   [ $# -eq 0 ] &&
     files=(/Volumes/Hera/Raw/MRprojects/7TBrainMech/2*/Recon_CSI/CoregHC/rmprage.nii \
            /Volumes/Hera/Raw/MRprojects/7TBrainMech/2*/Recon/CoregHC/r*.nii\
            /Volumes/Hera/Raw/MRprojects/7TBrainMech/HCCollection/2*/Recon_CSI/CoregHC/r*.nii) ||
     files=("$@")
        verb "have ${#files[@]} total r*.ni.gz files from MRRC. $(ls -d spectrum/2*/|wc -l) w/ preproc folders already. $(ls slices/ax/*.png|wc -l) slice images"
   for nii in "${files[@]}"; do
      _slice_centers "$nii" || continue
   done
}
eval "$(iffmain _slicemain)"

####
# testing with bats. use like
#   bats ./00_slice_centers.bash --verbose-run
####
function init_test { #@test 
  :
}
# 20210809Luna1
