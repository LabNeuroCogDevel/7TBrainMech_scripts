#!/usr/bin/env bash
set -euo pipefail
env |grep -q ^NOSKIP= || NOSKIP="" # dont skip linking. useful if 2 TIEJUN folders (20200429)
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
scriptdir=$(cd $(dirname $0);pwd)
source $scriptdir/func.bash # getld8: getld8_dcmdir getld8_db
# USAGE: ./000_dcmfolder_201906fmt.bash all

#  20190821WF  init

#
# dicom organization changed after 201904 
# now dicoms are in their own folder, but the folders are named differently
# link new folders to look like older folders
#  this is modeled after 010_gen_raw_links.bash, which is now deprecated
#
# after running this run 020_mkBIDS.R



# create per protcol directories as rawlinks/$lunaid/$seqno_$prtclname_$numberdicom
# depends on file name being like
#   11451_20180216.MR.TIEJUN_JREF-LUNA.0002.0004.2018.02.16.12.10.09.750000.32662664.IMA
#    id           .MR. study          .sqno
#                                          | <-41 chars, 4 fields
link_master_folder() {
   # check input
   [ $# -ne 1 ] && echo "$FUNCNAME: need just the final folder. given '$@'" >&2 && return 1
   dcmroot="$1"
   [ ! -d "$dcmroot" ] && echo "$FUNCNAME: '$dcmroot' must be a directory" >&2 && return 1

   # get id
   id=$(getld8 "$dcmroot" || echo -n "")
   [ -z "$id" ] && echo "no id from $dcmroot, set in func.bash ( $(ls -d $dcmroot/*/ |wc -l) protocol directoires, expect ~ 44)" >&2 && return 1

   linktoroot=/Volumes/Hera/Raw/BIDS/7TBrainMech/rawlinks/$id/
   [ ! -d $linktoroot ] && mkdir $linktoroot

   # check if we need to do anything
   nseq=$(ls -d "$dcmroot"/*/ | grep -vi MLBRAINSTRIP | wc -l)
   nlinked=$( (ls -d "$linktoroot"/*/ || echo -n "") |wc -l)

   # report protocol info. skip if done
   echo -n "# have $nlinked/$nseq linked in $linktoroot"
   [ $nlinked -ge $nseq -a -z "$NOSKIP" ] && echo " skipping" && return 0
   echo ""

   # re-link each folder to match what we've done before
   for d in "$dcmroot"/*/; do
      # find the first dicom in this folder
      exampledcm=$(find -L $d -type f,l -name '*IMA' -print -quit)
      # eg. 20190510LUNA11_1_1990.MR.TIEJUN_JREF-LUNA.0035.0192.2019.07.05.10.16.44.718750.171841323.IMA
      [ -z "$exampledcm" ] && echo "$d: no dicoms in folder!" >&2 && continue

      # extract info from name
      filepart=$(echo $exampledcm | sed 's:^./::' |  cut -f1-4 -d. )
      seqno=${filepart: -4}
      cnt=$(find -L $d -maxdepth 1 -type f,l -iname '*IMA' |wc -l)
      # get protocol name
      prtcl=$(dicom_hinfo -no_name -tag 0008,103e $exampledcm|tr -cs '[\nA-Za-z0-9]' -)
      [ -z "$prtcl" ] && prtcl=$(dicom_hinfo -no_name -tag 0018,1030 $exampledcm|tr -cs '[\nA-Za-z0-9]' -)
      [ -z "$prtcl" ] && echo "no protocol name: dicom_hinfo -tag 0018,1030 -tag 0008,103e '$exampledcm'" >&2 && continue
      # make new name
      dirname=${seqno}_${prtcl}_$cnt
      # 1_1_1990.MR.TIEJUN_JREF-LUNA.0025 becomes
      # 0025_ep3d-bold-1dgrappa-tacq2s-MGS-2_18432

      # link to raw
      linkdir="$linktoroot/$dirname"
      [ -d "$linkdir" -o -L "$linkdir" ] && echo "#   have $linkdir" && continue

      echo "# link $linkdir"
      ln -s "$(readlink -f $d)" "$linkdir"
   done
}

# require some input so we have an idea of whats going on
[ $# -eq 0 ] && echo "
inputs are either
 'all' 
 or any number of Hoby organized TIEJUN_JREF directory, sometimes calld DCM/
   the directory where there are folders for each sequence in a scan session.
   those folders should each be full of *IMA dicom files
USAGE:
 $0 all
 $0 /Volumes/Hera/Raw/MRprojects/7TBrainMech/20190422Luna1/20190422Luna1DCMALL/TIEJUN_JREF-LUNA_20190422_134510_234000
" && exit 1

# 'all' means look for TIEJUN fold220
[ $1 = "all" ] && dirs=(/Volumes/Hera/Raw/MRprojects/7TBrainMech/20{19*/2019*,2*/202*,{19,2}*/DICOM}/TIEJUN_JREF-LUNA*/) || dirs=($@) 

for d in ${dirs[@]}; do
   link_master_folder $d || continue
done
