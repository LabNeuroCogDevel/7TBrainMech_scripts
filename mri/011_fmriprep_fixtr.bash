#!/usr/bin/env bash
#
# fix TR on fmriprep output
#
# 20241118WF - init
#
new_tr(){
   #3dinfo -tr fmriprep/ses-*/sub-10644/func/sub-*_task-rest_run-01_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz
   #  0.048000
   #  0.052000
   #grep '10644'  txt/calc_rest_tr.txt
   #   BIDS/bids_folder/sub-10644/20180216/func/sub-10644_task-rest_run-01_bold.nii.gz 2.182636
   #   BIDS/bids_folder/sub-10644/20191011/func/sub-10644_task-rest_run-01_bold.nii.gz 2.199672
   #
   case $1 in
      0.048*) echo 2.18;;
      0.052*) echo 2.20;;
      *) echo "$1";;
   esac
}

change_json_tr() {
   perl -pie 's{("RepetitionTime": |SeriesStep=")(0.048\d+|0.05[24]\d+)}{$1 . sprintf("%.3f",$2*82/2)}e' "$@"
#grep -Poa 'SeriesStep="[^"]+"' /Volumes/Hera/Projects/7TBrainMech/scripts/mri/fmriprep/ses-1/sub-10173/func/sub-10173_task-rest_run-01_space-fsLR_den-91k_bold.dtseries.nii
#SeriesStep="0.048"
#
#grep Rep /Volumes/Hera/Projects/7TBrainMech/scripts/mri/fmriprep/ses-1/sub-10173/func/sub-10173_task-rest_run-01_space-fsLR_den-91k_bold.json
#  "RepetitionTime": 0.048,

# "TR"*numslice/acceleation => actual TR
#  .048*82/2    => 1.968
#  .054*82/2    => 2.214
#
}
fix_all_nii() {
   files=(/Volumes/Hera/Projects/7TBrainMech/scripts/mri/fmriprep/ses-*/sub-1*/func/sub-1*_task-rest_run-01_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz)
  3dinfo -tr -iname "${files[@]}" | while read -r tr fname; do
    [[ $tr =~ '^2' ]] && continue  # start with 2? already changed (all bad start with 0.0)
    fixtr=$(new_tr "$tr")
    [ "$fixtr" == "$tr" ] && echo "WARN: $fname tr=$tr. not changed" && continue
    dryrun 3drefit -TR "$fixtr" "$fname"
    dryrun 3dNotes -h "# tr from $tr to '$fixtr' via '$0'" "$fname"
done
}
text_tr(){ perl -lne 'print $2 if m/("RepetitionTime": |SeriesStep=")([0-9.]+)/' "$1"; }
fix_one_json(){
 local f="$1"
 tr=$(text_tr "$f")
 [[ $tr =~ '^2' ]] && return  # start with 2? already changed (all bad start with 0.0)
 new_tr=$(new_tr "$tr")
 [ "$new_tr" == "$tr" ] && echo "WARN: $f tr='$tr'. not changed" && return
 # shellcheck disable=SC2016 # $ in single quotes
 dryrun perl -spi -e 's{("RepetitionTime": |SeriesStep=")($tr)}{$1$new_tr}' -- -tr="$tr" -new_tr="$new_tr" "$f"
}
fix_all_json(){
   files=(/Volumes/Hera/Projects/7TBrainMech/scripts/mri/fmriprep/ses-*/sub-*/func/sub-*_task-rest_run-01_space-fsLR_den-91k_bold.dtseries.{nii,json})
   echo "# looking at ${#files[@]} nii/json cifti files"
   # perl -pie 's{("RepetitionTime": |SeriesStep=")(0.048\d+|0.05[24]\d+)}{$1 . sprintf("%.3f",$2*82/2)}e' "${files[@]}"
   cnt=1
   for f in "${files[@]}"; do
      fix_one_json "$f"
   done
}

011_fmriprep_fixtr_main(){
   #fix_allnii
   fix_all_json
}

# if not sourced (testing), run as command
eval "$(iffmain "011_fmriprep_fixtr_main")"

####
# testing with bats. use like
#   bats ./011_fmriprep_fixtr.bash --verbose-run
####
fixtr_test() { #@test
   local output
   run new_tr 0.052000
   [[ $output = "2.20" ]]
   run new_tr 0.048000
   [[ $output = "2.18" ]]
}
gettext_test() { #@test
   local output
   run text_tr /Volumes/Hera/Projects/7TBrainMech/scripts/mri/fmriprep/ses-1/sub-10129/func/sub-10129_task-rest_run-01_space-fsLR_den-91k_bold.dtseries.nii
   [[ $output =~ ^[0-9.]+$ ]]
}
