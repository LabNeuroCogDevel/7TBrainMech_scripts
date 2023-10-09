# what's ready to be placed?
for d in spectrum/20*; do
   [ 0 -ne $(find "$d" -maxdepth 1 -name 'spectrum.*'|wc -l) ] && continue
   echo -n $d
   [ -r $d/FS_warp ] && echo " ready" || echo " FS/idlook up issue"
done|
 grep -Pv '20210823Luna1|20220701Luna1|^$'| # excluding empty lines and bad files
 grep -Pv '20190406Luna1'| # hpc cyst
 grep -Pv '20210823Luna1|20220701Luna1|20220825Luna1|20221021Luna1|20221028Luna1' # 20230317 OR "placement issues" 
