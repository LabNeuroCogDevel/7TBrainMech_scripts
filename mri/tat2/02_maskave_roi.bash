#!/usr/bin/env bash

# 20220301 - copy from  /Volumes/Phillips/mMR_PETDA/scripts/tat2/07_extractTAT2_09c.bash 
forceWrite=0
maskavedir="$(dirname "$0")/out/maskave"
test ! -r "$maskavedir" && mkdir "$_"

# collect here so we dont have to do the glob for every mask
# also lets us print how many files we're running for
TAT2_FILES=(out/1*_2*_tat2.nii.gz)
echo "# running for ${#TAT2_FILES[@]} tat2 files";

echo "
# name         mask                                              rois
# harox_striatum_upsample atlas/HarvardOxford-striatum-2mm.masknums.18_09c.nii.gz 1..21
harox_striatum            atlas/HarOx_2mm.nii.gz                                  5,16,6,17,11,21,7,18
harox_nacc                atlas/HarOx_2mm.nii.gz                                  11,21
harox_caudate             atlas/HarOx_2mm.nii.gz                                  5,16
harox_putamen             atlas/HarOx_2mm.nii.gz                                  6,17
harox_pallidum            atlas/HarOx_2mm.nii.gz                                  7,18

"| sed 's/#.*//' |grep -v '^$'|
while read -r maskname maskfile valuerange; do
  [ -z "$maskname" ] && continue
  [ ! -r "$maskfile" ] && echo "ERROR: cannot read mask file $maskfile" >&2 && continue
  for cfile in "${TAT2_FILES[@]}"; do
     # extract id from filename (luna_vdate)
     [ ! -r "$cfile" ] && echo "ERROR: No such file '$cfile'" >&2 && continue
     subj="$(grep -Po '\d{5}_\d{8}' <<< "$cfile")"
     [ -z "$subj" ] && echo "ERROR: bad id in '$cfile'" >&2 && continue
  
     # dont redo unless forced
     outfile="$maskavedir/$subj-$maskname.csv"
     [ -r "$outfile" -a $forceWrite -eq 0 ] && echo "# Have output file $outfile, SKIPPING" && continue
  
     
     cmd="3dmaskave -quiet -mask ${maskfile}'<$valuerange>' $cfile"
     echo "$outfile: $cmd"
     val=$(eval "$cmd")
     echo "${maskname},${subj},rest,${val}" > "$outfile"
  done
done

echo "# concatting all maskave csv files: maskave.csv"
echo "roi,subj,event,beta" > maskave.csv
find "$maskavedir" -name "*csv" -type f -exec cat {} + >> maskave.csv 


####  ROI values
# http://neuro.imm.dtu.dk/wiki/Harvard-Oxford_Atlas
# 0	Left Cerebral White Matter
# 1	Left Cerebral Cortex
# 2	Left Lateral Ventrical
# 3	Left Thalamus
# 4	Left Caudate
# 5	Left Putamen
# 6	Left Pallidum
# 7	Brain-Stem
# 8	Left Hippocampus
# 9	Left Amygdala
# 10	Left Accumbens
# 11	Right Cerebral White Matter
# 12	Right Cerebral Cortex
# 13	Right Lateral Ventricle
# 14	Right Thalamus
# 15	Right Caudate
# 16	Right Putamen
# 17	Right Pallidum
# 18	Right Hippocampus
# 19	Right Amygdala
# 20	Right Accumbens
