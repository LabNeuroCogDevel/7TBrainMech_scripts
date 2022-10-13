#!/usr/bin/env bash
#
# use coverage map to make seeds for connectivity
#
# 20221011WF - init
#
source mkcorr.bash # get_blob
mapfile -t LABELS < <(sed 's/ //g;s/:.*//' ../MRSI_roi/roi_locations/labels_13MP20200207.txt)
TP1FILE=/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI_roi/gaba_glu_r/out/gaba_glu.csv
tp1subjs-spheres(){
  local roinum="$1"; shift
  mlr --csv  filter "\$roi==$roinum" "then" \
             uniq -g id  $TP1FILE |
  while read lunaid; do
    get_blob ${lunaid}_* cmsphere-mni | sed 1q;
  done
}

#mapfile -t ALL_SPHERES < <(ls $(get_blob 1*_2* cmsphere-mni) 2>/dev/null)



addroinum() {
   local roi="$1"; shift
   while [ $# -gt 0 ]; do echo "$1<$roi>"; shift; done
}

mkroi-centergm() {
  local size=9
  local gm=/opt/ni_tools/standard/mni_icbm152_nlin_asym_09c/mni_icbm152_gm_tal_nlin_asym_09c_2mm.nii 
  local gmthres=0.5

  local in="$1"
  local out=${in/.nii.gz/_gm-${gmthres}_mxsph-$size.nii.gz}
  test -r "$out" && warn "# have $_" && return 0

  local mx="$(3dBrickStat -max "$in"|sed 's/ //g')"
  [[ -z "$mx" || $mx =~ \[ ]] && warn "bad max '$mx' for '$in'" && return 1
  warn "# mx $mx for '$in'"

  3dCM -local_ijk "$in<$mx>"|
      3dUndump -prefix "$out" -mask "3dcalc(-expr step(a-$gmthres) -a $gm )" \
               -overwrite \
               -srad $size -master "$in" -ijk -
   echo "$out"
}

mkseed-roi() {
 local roi="$1";shift 
 local label=${LABELS[$((roi - 1))]}
 mapfile -t tp1_in < <(tp1subjs-spheres "$roi")
 nvisit=${#tp1_in[@]}
 [ $nvisit -eq 0 ] && warn "# skipping roi $roi (assume not in $TP1FILE)" && return 1
 # prev tp1_in=("${ALL_SPHERES[@]}")
 mapfile -t inputrois < <(addroinum "$roi" "${tp1_in[@]}")
 test -d roi-cnt || dryrun mkdir "$_"
 prefix=roi-cnt/$(printf "%02d" "$roi")-${label}_nvisit-$nvisit
 out="${prefix}_rat.nii.gz"
 test -r "$out" && warn "# already have $_" && echo "$out" && return 0
 dryrun 3dMean -count -prefix "${prefix}_cnt.nii.gz" "${inputrois[@]}" >/dev/null
 # % of visits not of max. if no roi for a visit, rat cannot be 100
 dryrun 3dcalc -prefix "${prefix}_rat.nii.gz" -a "${prefix}_cnt.nii.gz" -expr a/$nvisit >/dev/null
 echo "$out"
 return 0
}
mask_seed(){
   local thres=0.5 # 80% coverage
   local gmmask="/opt/ni_tools/standard/mni_icbm152_nlin_asym_09c/mni_icbm152_gm_tal_nlin_asym_09c_2mm.nii"
   local gmthres=0.5
   local in="$1"
   ! [[ $in =~ _rat.nii.gz ]] && warn "bad input: $in should be _rat.nii.gz" && return 1
   out=${in/_rat.nii.gz/_ratths-${thres}_gm.nii.gz}
   test -r "$out"  && echo "# have $_" && return 0
   dryrun 3dcalc -a "$in" -g $gmmask -expr "step(a-$thres)*step(g-$gmthres)" -prefix "$out"
}

mkseeds-f() {
 for roi in {1..13}; do
    seed=$(mkseed-roi $roi||:)
    test -z "$seed" && continue
    mkroi-centergm "${seed/_rat.*/_cnt.nii.gz}"
    mask_seed "$seed"
 done
}

# if not sourced (testing), run as command
eval "$(iffmain mkseeds-f)"

####
# testing with bats. use like
#   bats ./mkseeds.bash --verbose-run
####
function roinum_test { #@test 
   run addroinum 1 a b
   [[ $output =~ "a<1>"."b<1>" ]]
}

function sphers_test { #@test
   [ -r "${ALL_SPHERES[1]}" ]
   [ ${#ALL_SPHERES[@]} -gt 230 ]
}

function labels_test { #@test
   [ ${#LABELS[@]} -eq 13 ]
}
function tp1subjs-spheres-test { #@test
  mapfile -t tp1files < <(tp1subjs-spheres 10)
  [ -r "${tp1files[1]}" ]
  [ ${#tp1files[@]} -gt 80 ]
}
