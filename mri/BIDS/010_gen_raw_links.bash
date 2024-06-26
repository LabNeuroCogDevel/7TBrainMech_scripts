#!/usr/bin/env bash

# create per protcol directories as rawlinks/$lunaid/$seqno_$prtclname_$numberdicom
# if no arguments, read inputdirs.txt
# otherwise tries directoy given as input
# e.g.
# ./00_genraw.bash /Volumes/Hera/Raw/MRprojects/7TR01/20180129DCMALL/

scriptdir=$(cd $(dirname $0);pwd)
bidsroot=$scriptdir

source $scriptdir/func.bash # getld8: getld8_dcmdir getld8_db
cd /Volumes/Hera/Raw/BIDS/7TBrainMech/rawlinks

# look through all dicoms in a directory
# identify different protcols
# depends on file name being like
#   11451_20180216.MR.TIEJUN_JREF-LUNA.0002.0004.2018.02.16.12.10.09.750000.32662664.IMA
#    id           .MR. study          .sqno
#                                          | <-41 chars, 4 fields
# alldcmdir -> 
#   id.mr.study.001* 001.ptrc.ndcm 
#   id.mr.study.003* 003.prtcl.ndcm 
#  ...
in_out() {
  [ -z "$1" -o ! -d "$1" ] && echo "bad args to in_out dcmdir skipcars" >&2 && return
  cd "$1" 
  # only compare e.g. "./11451_20180216.MR.TIEJUN_JREF-LUNA.0002." 
  find -type f | sed 's:^./::' |  cut -f1-4 -d. | sort | uniq -c |
  while read cnt filepart; do 
     [ -z "$filepart" ] && echo "file names did not match expected (cut -d. -f1-4) $cnt" >&2 && continue
     filepart="$(basename $filepart)"
     seqno=${filepart: -4}
     exampledcm=$(find -iname "$filepart*" -type f,l -print -quit )
     [ -z "$exampledcm" ] && echo "found no example dicoms: find $(pwd) -iname '$filepart*' -type f,l -print -quit" >&2 && continue
     prtcl=$(dicom_hinfo -no_name -tag 0008,103e $exampledcm|tr -cs '[\nA-Za-z0-9]' -)
     [ -z "$prtcl" ] && prtcl=$(dicom_hinfo -no_name -tag 0018,1030 $exampledcm|tr -cs '[\nA-Za-z0-9]' -)
     [ -z "$prtcl" ] && echo "no protocol name: dicom_hinfo -tag 0018,1030 -tag 0008,103e '$exampledcm'" >&2 && continue
     dirname=${seqno}_${prtcl}_$cnt
     # sanity check
     npattmatch=$(find $(pwd)/ -iname "$filepart*"|wc -l)
     [ "$npattmatch" -ne "$cnt" ] && echo "glob $(pwd)/$filepart* ($npattmatch) not uniq cnt ($cnt)" >&2
     echo "$(pwd)/$filepart* $dirname";
  done
  cd - >/dev/null
}

# expand glob and link all
link_glob(){
  [ -z "$2" ] && echo "link_glob needs second argument" >&2 && return
  if [ -d "$2" ]; then 
     expectn=$(echo $2|cut -f4 -d_) 
     haven=$(find $2 -maxdepth 1 -type l,f |wc -l)
     echo "already have $2 ($haven/$expectn files)" 
     [ "$expectn" -ne "$haven" ] && echo "[WARNING] rm $2 # to try again" >&2
     return
  fi

  echo "$1 -> $2 ($expectn)"
  [ -n "$DRYRUN" ] && return

  [ ! -d "$2" ] && mkdir "$2"
  indir="$(dirname "$1")"
  patt="$(basename "$1")"
  find "$indir" -iname "$patt" -type f | xargs -I{} ln -s {} $2 || echo "issue with $2"
}
export -f link_glob

link_subjalldcm(){
 # validate input alldcmdir
 d="$1"
 [ -z "$d" -o ! -d "$d" ] && echo "bad alldcm subject directory '$d'" >&2  && return

 # get id
 id=$(getld8 "$d" 2>/tmp/getld8msg ) || : #continue
 [ -z "$id" ] && echo -e "no id for $d ($exampledcm)\n$(sed 's/^/\t/' /tmp/getld8msg)" && return

 echo "$id $d"

 # make subject
 [ -d "$id" -a "$2" == "skip" ] && echo "have $id; $0 $d # for verbose info" && return
 [ ! -d $id ] && mkdir $id
 
 # separate dicoms into their own dirs
 in_out $d | parallel --colsep ' ' link_glob "{1}" $id/{2}
}
if [ $# -eq 0 ]; then
   cat <<HD
USAGE: 
  $0 all
  $0 /Volumes/Hera/Raw/MRprojects/7TBrainMech/20180607Luna1/20180607LUNA1DCMALL/
  $0 /Volumes/Hera/Raw/MRprojects/7TBrainMech/20211*/DICOM
HD
fi
# if no input, look at inputdirs.txt
if [ "$1" == "all" ]; then
  $scriptdir/000_gen_idlist.bash newer
  echo "# no raw dir given, using 000_gen_idlist.bash (alternate usage: $0 /Volumes/Hera/Raw/MRprojects/7TBrainMech/20180607Luna1/20180607LUNA1DCMALL/)"
  cat $scriptdir/inputdirs.txt | while read d ld8 sub_sess; do
    [ -d $bidsroot/$sub_sess ] && echo "# have $bidsroot/$sub_sess for raw $d" && continue
    [ -d $ld8 ] && echo "# have rawlinks $ld8 for raw $d" && continue
    link_subjalldcm $d
  done
# otherwise do all dirs given as arguments
else
  for d in $@; do
    link_subjalldcm $d
  done
fi
