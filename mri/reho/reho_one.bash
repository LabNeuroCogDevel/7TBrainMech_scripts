#!/usr/bin/env bash
 
# read from nowarp preproc dir
PREPROCDIR=/Volumes/Zeus/preproc/7TBrainMech_rest/MHRest_nost_nowarp_nosmooth
# write to local images dir
OUTDIR="/Volumes/Hera/Projects/7TBrainMech/scripts/mri/reho/images"

#ask for file name
 
# use what's given on the commandline ("$1") or ask for input if not given
if [ -n "$1" ]; then
   subject="$1"
else
   echo -e "\nEnter file name from directory:"
   echo -e "/Volumes/Zeus/preproc/7TBrainMech_rest/MHRest_nost_nowarp_nosmooth\n"
   read -r subject
fi

# make sure we were given a good subject
# if given a full file and not a subject, use that as input instead
inputfile="$PREPROCDIR/$subject/Wbgrndkm_func.nii.gz"
[ ! -r  "$inputfile" ] && inputfile="$subject"
if [ ! -r "$inputfile" ]; then
   echo "ERROR: cannot read '$inputfile'"
   exit 1
fi
# make (or ensure) subject is the luna_date8 from inputfile
subject="$(ld8 "$inputfile")"

#echo "input_arg=$1;subject: $subject;inputfile=$inputfile"
#exit 1


# get gm mask
gmmask="$(dirname "$inputfile")/gmmask_restres.nii.gz"
[ ! -r "$gmmask" ] && warn "ERROR: $subject has no gmmask.nii.gz ($gmmask)!?" && exit 3

# -p doesn't error if already exists and creats all parents when needed
mkdir -p "$OUTDIR/${subject}"

# get gm epi mask
# don't redo files we've already done
gmepimask=$OUTDIR/${subject}/gmmask_epimasked.nii.gz
if [ ! -r "$gmepimask" ]; then
# calculate gm epi mask
   3dcalc -m "$gmmask" -a "${inputfile[0]}" \
      -expr 'm*step(abs(a))' \
      -prefix "$gmepimask"
   echo "# wrote $gmepimask"
 else
   echo "# already have $gmepimask"
 fi



# run ReHo for each neighborhood size
for neighbor in 7 19 27; do
  echo -e "\n\ncalculating ReHo with $neighbor-voxel neighborhood\n"


  # no mask version
  # don't redo files we've already done
  outfile=$OUTDIR/${subject}/reho_n$neighbor.nii.gz
  if [ ! -r "$outfile" ]; then
  # run unmasked ReHo with $neighbor-voxel neighborhood
     3dReHo -prefix "$outfile" \
        -inset "$inputfile" \
        -nneigh $neighbor
     echo "# wrote $outfile"
   else
     echo "# already have $outfile"
  fi


  # gm masked version
  outfile=$OUTDIR/${subject}/reho-gmmask_n$neighbor.nii.gz
  if [ ! -r "$outfile" ]; then
     # run gm masked ReHo with $neighbor-voxel neighborhood
     3dReHo -prefix "$outfile" \
        -mask "$gmmask" \
        -inset "$inputfile" \
        -nneigh $neighbor
     echo "# wrote $outfile"
   else
     echo "# already have $outfile"
  fi


  # gm epi masked version
  outfile=$OUTDIR/${subject}/reho-gmmask_epimasked_n$neighbor.nii.gz
  if [ -r "$outfile" ]; then
     echo "# already have $outfile"
     continue
  fi
  # run gm epi masked ReHo with $neighbor-voxel neighborhood
  3dReHo -prefix "$outfile" \
     -mask "$gmepimask" \
     -inset "$inputfile" \
     -nneigh $neighbor
  echo "# wrote $outfile"


done
