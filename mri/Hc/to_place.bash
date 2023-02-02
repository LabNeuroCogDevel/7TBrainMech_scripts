# what's ready to be placed?
for d in spectrum/20*; do [ 0 -ne $(find "$d" -maxdepth 1 -name 'spectrum.*'|wc -l) ] && continue; echo -n $d; [ -r $d/FS_warp ] && echo " ready" || echo " FS/idlook up issue"; done| grep -Pv '20210823Luna1|^$'

