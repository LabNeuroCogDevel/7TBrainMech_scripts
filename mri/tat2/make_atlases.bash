
# 20220301 - 7T is 2mm. PET is 2.3mm.
# want to use orig lower res masks on high res data.
# upsample previously used on PET
# but boundaries will be messy/inaccurate
[ ! -d atlas ] && mkdir atlas

[ ! -r atlas/HarvardOxford-striatum-2mm.masknums.18_09c.nii.gz ] && 
  3dresample -master out/10129_20180917_tat2.nii.gz -inset /Volumes/Phillips/mMR_PETDA/atlas/HarvardOxford-striatum-2.3mm.masknums.18_09c.nii.gz -prefix atlas/HarvardOxford-striatum-2mm.masknums.18_09c.nii.gz

exit 0
