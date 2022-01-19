[ -n "$DRYRUN" ] && DRYRUN=echo || DRYRUN=""
cd /Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/
[ -n "$DRYRUN" ] && pwd
for z in 2022*processed.zip; do
   [ ! -d $(basename $z .zip) ] && $DRYRUN unzip $z
done
