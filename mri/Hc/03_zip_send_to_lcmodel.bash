#!/usr/bin/env bash

# # use provided list
# # zip position-QC'ed spectrum files for VY to get LCModel output back
# # pev version 20220701
# id_list="qc/good_2022-09-28.txt"
# ! [[ $id_list =~ [0-9]{4}-[0-9]{2}-[0-9]{2} ]] && echo "no date in $id_list" && exit 1
# zipdate=$BASH_REMATCH
# zip send_to_lcmodel/LunaHc_spectrum_$zipdate.zip -@ < <(
#for good_id in $(cat $id_list); do
#   ls spectrum/$good_id/spectrum*[0-9]
#done)

# grab what we haven't already stored
#zipdate=2022-12-02
zipdate=2023-01-30
outfile=send_to_lcmodel/LunaHc_spectrum_$zipdate.zip

# 20230130- confirm we have what we expect
# comm txt/20230130_placed.txt <(unzip -l send_to_lcmodel/LunaHc_spectrum_2023-01-30.zip |grep -Po '\d{8}Luna\d?'|sort -u)


mrid_ex(){ grep -Po '\d{8}L[^/]*'|sort -u; }
id_already_zip() { ls send_to_lcmodel/LunaHc_spectrum_*.zip|xargs -n1 unzip -l|mrid_ex; }
zip_missing(){
 mapfile -t to_send < \
    <(comm -23 <(ls -d spectrum/2*/|mrid_ex) <(id_already_zip) |
      sed s:^:spectrum/:)
 echo "# ${#to_send} not already in a zip file. zipping into $outfile"
 [ -n "${DRYRUN:-}" ] && exit 0
 
 find "${to_send[@]}" -iname 'spectrum.*' | zip -r $outfile -@
}
eval "$(iffmain zip_missing)"
