#!/usr/bin/env bash
#
# 20221019WF - init
#  add bottom and top slice options for espeically bad hc slices
#  will later need to pull %GM/%FS label for coords
#

mprage_neighbors(){
  local in="$1"
  local d="$(dirname "$in")"
  local f="$(basename "$in")"
  # index 0 is bottom; will use as top bottom 
  perl -sE 'say s!^(\d+)_(\d+)!"$d/$1_" . ($2 +3)!er'  -- -d="$d" -_="$f"
  perl -sE 'say s!^(\d+)_(\d+)!"$d/$1_" . ($2 -3)!er'  -- -d="$d" -_="$f"
}

neighborslices_all() {
  for l in spectrum/20*L*/anat.mat; do
     mapfile -t TOPBOT  < <(mprage_neighbors "$(readlink -f "$l")")
     top3="${TOPBOT[0]}"
     bottom3="${TOPBOT[1]}"
     for v in top3 bottom3; do
       test -z "${!v}" -o ! -r "${!v}" && warn "# missing $v: '$_'" && continue
       # link if we dont already have  top.mat or bottom.mat
       ! test -r "$(dirname $l)"/$v.mat &&
           dryrun ln -s "${!v}" "$_"
     done
  done
  return 0
}

# if not sourced (testing), run as command
eval "$(iffmain "neighborslices_all")"

## testing. see:
#   bats ./01.2_add_top_bottom_slice.bash --verbose-run
function neighbor_test { #@test 
   run mprage_neighbors /Volumes/Hera/Raw/MRprojects/7TBrainMech/20201030Luna1/Shim/CoregHC/registration_out/17_7_FlipLR.MPRAGE
   res=($output)
   [ ${#res[@]} -eq 2 ]
   [[ ${res[0]} =~ 17_6_FlipLR.MPRAGE ]]
   [[ ${res[1]} =~ 17_8_FlipLR.MPRAGE ]]
}
