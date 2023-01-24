#!/usr/bin/env bash
source "$(dirname "$0" 2>/dev/null || echo ".")"/func.bash # getld8_dcmdir getld8_db

lsn() {
  local d="$1"
  n=$(find "$d" -maxdepth 1 -type f -iname '*IMA'|wc -l);
  add_nd="$n $d"
  grep "$add_nd" raw_dirs.txt && return 0
  [ "$n" -gt 10000 ] && echo "$add_nd"
}

lsn_append(){ lsn "$1" | tee -a raw_dirs.txt; }

fmt_rawdir(){
   local rawdir="$1";
   read -r n d <<< $(sort -nr raw_dirs.txt | grep "$rawdir"  |sed 1q)
   [ -z "$d" -o ! -r "$d" ] && echo "WARNING: no dcm dir for $rawdir" >&2 && return 1
   #dicom_hinfo -no_name -tag 0010,0010 $(find $d -maxdepth 1 -mindepth 1 -iname '*IMA' -print -quit) | 
   #perl -slne 'print "$SDir\t${1}_${2}\tsub-$1/$2" if m/(\d{5})_(\d{8})/' -- -SDir=$d;
   ld8=$(getld8 "$d" 2>/tmp/getld8msg) || : #continue
   [ -z "$ld8" ] && cat /tmp/getld8msg >&2 && return 1
   echo -e "$d\t$ld8\tsub-${ld8/_/\/}"
}

# find raw dicom list dirs
#   like '*DCM*' (usually ALLDCM) 
#   should have more than 300 files (slow to determine!)
# save to inputdirs.txt:
#  $DCMALL/	$ld8	sub-$l/$d8
# also makes raw_dirs.txt:
#  $ndcm $DCMALL/

main(){ 
  [ $# -lt 1 ] && cat >&2 <<HERE && exit 1
USAGE:
  $0 [all|newer]
   all     => count *IMA files in all Raw/MRprojects/7TBrainMech/*/*/ directories
   newer   => count only directories newer than raw_dirs.txt
   day     => anything in the last day
   idv /Volumes/Hera/Raw/MRprojects/7TBrainMech/201908*/
           => just these directories
OUTPUT:
  inputdirs.txt
HERE

  # create raw dirs if it's been a day
  [ ! -s raw_dirs.txt ] && rm raw_dirs.txt # if is an empyt file, remove
  
  
  search_dirs=()
  append=""
  case "$1" in
     all)
        # do everything
        search_dirs=(/Volumes/Hera/Raw/MRprojects/7TBrainMech/2*/)
        ;;
  
     newer)
        # compaire the newest directory we have with the newest in raw_dirs.txt
        newest=$(stat -c%Z  /Volumes/Hera/Raw/MRprojects/7TBrainMech/2*/|sort -nr |sed 1q)
        #lastrun=$( (cut -f2 -d' ' raw_dirs.txt||echo 0) |xargs stat -c%Z |sort -nr |sed 1q)
        lastrun=$(stat -c%Z raw_dirs.txt)
  
        search_dirs=($(stat -c"%Z %n"  /Volumes/Hera/Raw/MRprojects/7TBrainMech/2*/|
           sort -nr |
           awk "(\$1>$lastrun){print \$2}"))
        append="-a"
        echo "newest is $newest, last counted is $lastrun, searching for ${#search_dirs}: ${search_dirs[@]}"
        ;;
  
     day)
        let tdiff=$(date +%s)-$(stat -c%Z raw_dirs.txt||echo 0) 
        let aday=60*60*24
        [  $tdiff -gt $aday ] && search_dirs=(/Volumes/Hera/Raw/MRprojects/7TBrainMech/2*/)
        ;;
     idv)
        shift;
        append="-a"
        search_dirs=("$@");;
     *)
        echo "bad input '$1': want all, newer, day, or idv";;
  esac
  
  [ ${#search_dirs} -eq 0 ] && echo "nothing to do" && exit 0
  
  for d in $(find "${search_dirs[@]}" -maxdepth 1 -type d); do 
     lsn "$d"
  done |tee $append raw_dirs.txt
  
  echo "making directory,id,bids-id tsv"
  
  for rawdir in /Volumes/Hera/Raw/MRprojects/7TBrainMech/2*/; do
     # find dir with most dicoms
     fmt_rawdir "$rawdir" || :
  done > inputdirs.txt
}


#set -e
#trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
eval "$(iffmain main)"
