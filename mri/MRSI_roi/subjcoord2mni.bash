#!/usr/bin/env bash
# create mni version of import coordinates
#  20190924WF  init
subjcoord2mni(){
   [ $# -ne 4 ] && echo -e "$FUNCNAME coordfile ppt1dir slice_PFCdir outdir\n\t(have $# inputs '$@')" && return 1
   coord="$1"; shift
   ppt1dir="$1"; shift
   slicedir="$1"; shift
   outdir="$1"; shift

   tmplbrain=$ppt1dir/template_brain.nii
   mpragepp=$ppt1dir/mprage.nii.gz
   warpcoef=$ppt1dir/mprage_warpcoef.nii.gz 
   mp2slice=$slicedir/mprage_to_slice.mat
   rorig=$slicedir/MRSI/parc_group/rorig.nii

   mniout=$outdir/$(basename $coord)_mni.nii.gz
   [ -r $mniout ] && echo "# have $mniout" && return 0

   tmp=$outdir/tmp
   [ ! -r $tmp ] && mkdir -p $tmp

    for v in coord rorig tmplbrain mp2slice mpragepp warpcoef; do
       # set v to full path
       origv=${!v}
       printf -v $v "$(readlink -f ${!v})"
       [ -z "${!v}" -o ! -r "${!v}" ] && echo "no $v ('$origv')!" >&2 &&
          return 1 
    done

    # did we already run?

    echo $coord
    ### DO STUFF
    set -x

    # dump coordinates as cubes in slice space (registared orig)
    awk '{print $2,$3,$4,$1}' $coord  > $tmp/coords_rearranged.txt
    3dUndump \
        -overwrite -prefix $tmp/coords_slicespace.nii.gz  \
        -master $rorig\
        -srad 4.5 \
        -cubes \
        -ijk $tmp/coords_rearranged.txt

    # reverse affine transfor for slice to mprage
    [ ! -r slice_to_mprage.mat ] && convert_xfm -omat slice_to_mprage.mat -inverse $mp2slice
    # apply to get slice coords into mprage (used for gm mask count)
    flirt -interp nearestneighbour -in $tmp/coords_slicespace.nii.gz -ref $mpragepp -applyxfm -init slice_to_mprage.mat -out $tmp/coords_mprage.nii.gz
    # it's orig not TLRC (fsl looses this info)
    3drefit -space ORIG $tmp/coords_mprage.nii.gz
    # send coords from slice to mni (using t1 as intermidate: warpcoef + slice->t1 premat)
    # useful for connectivity
    cmd="
    applywarp -o $mniout \
        -i $tmp/coords_slicespace.nii.gz \
        -r \"$tmplbrain\" \
        -w \"$warpcoef\" \
        --premat=slice_to_mprage.mat \
        --interp=nn "
    eval $cmd
    3dNotes -h "$cmd" $mniout
 }

if [ $(basename $0) == "subjcoord2mni.bash" ]; then
   set -euo pipefail
   trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
   subjcoord2mni $@
else
   :
fi
