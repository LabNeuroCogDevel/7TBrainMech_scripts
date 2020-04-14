[ -n "$DRYRUN" ] && DRYRUN=echo || DRYRUN=""
cd /Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/
for z in 2020*processed.zip; do
   [ ! -d $(basename $z .zip) ] && $DRYRUN unzip $z
done
