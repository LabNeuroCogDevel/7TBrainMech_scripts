echo "NOT RUNNING. Here for documentation only"
exit 1
# this is just here for documentation. should never need to be rerun

cd raw_zipdir/ # /Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01

# 20200519 - 
[ ! -d HPC/ProcessedHc_20200520_2019-Mar2020 ] &&
   echo unzip -d HPC/ ProcessedHc_20200520_2019-Mar2020.zip

# 20200520 - fetch old data kindly re-upload to shimlinux by victor!
[ ! -d HPC/Processed103019/ ] &&
   echo unzip -d HPC/ ProcessedHc_20190722-20190913.zip

outdir=$(pwd)/HPC/ProcessedHc103019_fixed_ln
test ! -d $outdir && mkdir $_
# standardize naming: HPC/Processed103019/ 
# May 20  2020 -- run
# 20220630     -- lots of renaming to fix issues.
#   $'\r' included in filename!
#   side should be R/L not Right/Left
#   untouched: count is backwards? goes 6-1 instead of 1-6
# TODO: fix these!! not neded for b/c ProcessedHc103019_fixed_ln replicated elsewhere correctly
for f in $(pwd)/HPC/Processed103019/*/locations.txt; do
   ! [[ $f =~ Luna([0-9]{4})([0-9]) ]] && echo "bad name $f" && continue
   newid=2019${BASH_REMATCH[1]}Luna${BASH_REMATCH[2]}
   echo $newid
   cat $f | while read side roi r c; do
      d=$(dirname $f)/spectrum.$r.$c.dir
      [ ! -d $d ] && echo "no $d!" && continue
      # new dir like
      # spectrum.71.111.R.2.dir
      new_d=$outdir/$newid/spectrum.$r.$c.$side.$roi.dir
      test -d $(dirname $new_d) || mkdir $_
      [ ! -e $new_d ] && ln -s $d $new_d
   done
done
