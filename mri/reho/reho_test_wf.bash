#!/usr/bin/env bash
 
# read from nowarp preproc dir
PREPROCDIR=/Volumes/Zeus/preproc/7TBrainMech_rest/MHRest_nost_nowarp_nosmooth/
# write to local images dir
OUTDIR="/Volumes/Hera/Projects/7TBrainMech/scripts/mri/reho/images/"

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
inputfile="$PREPROCDIR/$subject/Wbgrndkm_func.nii.gz"
if [ ! -r "$inputfile" ]; then
   echo "ERROR: cannot read '$inputfile'"
   exit 1
fi

# get gm mask
## need to find gm mask
gmmask="$(dirname "$inputfile")/gmmask_restres.nii.gz"
[ ! -r "$gmmask" ] && warn "ERROR: $subject has no gmmask.nii.gz ($gmmask)!?" && exit 3

# -p doesn't error if already exists and creats all parents when needed
mkdir -p "$OUTDIR/${subject}"

# run for each neighborhood size
for neighbor in 7 19 27; do
  echo -e "\n\ncalculating ReHo with $neighbor-voxel neighborhood\n"

  # don't redo files we've already done
  outfile=$OUTDIR/${subject}/reho_n$neighbor.nii.gz
  if [ -r "$outfile" ]; then
     echo "# already have $outfile"
     continue
  fi

  # run ReHo with $neighbor-voxel neighborhood
  3dReHo -prefix "$outfile" \
     -inset "$inputfile" \
     -nneigh $neighbor
  echo "# wrote $OUTDIR/${subject}_reho_n$neighbor.nii.gz"

  # masked
  3dReHo -prefix "$outfile" \
     -make "$gmmask" \
     -inset "$inputfile" \
     -nneigh $neighbor
done
