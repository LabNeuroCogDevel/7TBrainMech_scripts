#!/usr/bin/env bash
# create mni version of import coordinates (blob-mni.nii.gz)
#  20190924WF  init
#  20200213WF  rework save paths
# called from coord_mover.m like 
subjcoord2mni(){
   [ $# -ne 4 ] && echo -e "$FUNCNAME coordfile ppt1dir slice_PFCdir outputdir\nmakes blob-mni.nii.gz\n\t(have $# inputs '$@')" && return 1
   coord="$1"; shift    # txtfile=sprintf('%s_%f_%s_%s_for_mni.txt',n,dtime,data.ld8,data.who);
   ppt1dir="$1"; shift  # /Volumes/Hera/Projects/7TBrainMech/subjs/10173_20180802/preproc/t1/
   slicedir="$1"; shift # /Volumes/Hera/Projects/7TBrainMech/subjs/10173_20180802/slice_PFC/
   outdir="$1"; shift   # /Volumes/Hera/Projects/7TBrainMech/subjs/10173_20180802/slice_PFC/roi/$mask/$initials
   # save to folder/roi path
   mniblob=$outdir/blob-mni.nii.gz
   [ -r $mniblob ] && echo "# already finished, to redo:  rm $mniblob">&2 && echo $mniblob && return 0

   tmplbrain=$ppt1dir/template_brain.nii
   mpragepp=$ppt1dir/mprage.nii.gz
   warpcoef=$ppt1dir/mprage_warpcoef.nii.gz 
   mp2slice=$slicedir/mprage_to_slice.mat
   rorig=$slicedir/MRSI/parc_group/rorig.nii



   for v in coord rorig tmplbrain mp2slice mpragepp warpcoef; do
      # set v to full path
      origv=${!v}
      printf -v $v "$(readlink -f ${!v})"
      [ -z "${!v}" -o ! -r "${!v}" ] && echo "no $v ('$origv')!" >&2 &&
         return 1 
   done


   ! test -e $outdir/$(basename $mpragepp)  && ln -s $mpragepp $_
   ! test -e $outdir/$(basename $rorig)  && ln -s $rorig $_
   ! test -e $outdir/$(basename $tmplbrain)  && ln -s $tmplbrain $_

   # did we already run?

   echo $coord >&2
   ### DO STUFF
   set -x

   # dump coordinates as cubes in slice space (registared orig)
   awk '{print $2,$3,$4,$1}' $coord  > $outdir/coords_rearranged.txt
   3dUndump \
       -overwrite -prefix $outdir/coords_slicespace.nii.gz  \
       -master $rorig\
       -srad 4.5 \
       -cubes \
       -ijk $outdir/coords_rearranged.txt

   # reverse affine transfor for slice to mprage
   affine=$outdir/slice_to_mprage.mat
   convert_xfm -omat $affine -inverse $mp2slice
   # apply to get slice coords into mprage (used for gm mask count)
   warped=$outdir/coords_mprage.nii.gz
   niinote $warped flirt -interp nearestneighbour -in $outdir/coords_slicespace.nii.gz -ref $mpragepp -applyxfm -init $affine -out $warped
   # it's orig not TLRC (fsl looses this info)
   3drefit -space ORIG $outdir/coords_mprage.nii.gz
   # send coords from slice to mni (using t1 as intermidate: warpcoef + slice->t1 premat)
   # useful for connectivity
   niinote $mniblob \
      applywarp -o $mniblob \
       -i $outdir/coords_slicespace.nii.gz \
       -r \"$tmplbrain\" \
       -w \"$warpcoef\" \
       --premat=$affine \
       --interp=nn
   set +x
   echo $mniblob
 }

if [ $(basename $0) == "subjcoord2mni.bash" ]; then
   set -euo pipefail
   trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
   subjcoord2mni $@
else
   :
fi
