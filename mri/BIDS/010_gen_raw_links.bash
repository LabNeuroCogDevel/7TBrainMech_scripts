#!/usr/bin/env bash

# create per protcol directories as rawlinks/$lunaid/$seqno_$prtclname_$numberdicom
# if no arguments, read inputdirs.txt
# otherwise tries directoy given as input
# e.g.
# ./00_genraw.bash /Volumes/Hera/Raw/MRprojects/7TR01/20180129DCMALL/

scriptdir=$(cd $(dirname $0);pwd)
bidsroot=$scriptdir

source $scriptdir/func.bash # getld8_dcmdir getld8_db
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
     seqno=${filepart: -4}
     exampledcm=$(ls $filepart*|sed 1q)
     prtcl=$(dicom_hinfo -no_name -tag 0008,103e $exampledcm|tr -cs '[\nA-Za-z0-9]' -)
     dirname=${seqno}_${prtcl}_$cnt
     # sanity check
     npattmatch=$(ls $(pwd)/$filepart*|wc -l)
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
     haven=$(ls $2|wc -l)
     echo "already have $2 ($haven/$expectn files)" 
     [ "$expectn" -ne "$haven" ] && echo "[WARNING] rm $2 # to try again"
     return
  fi

  echo "$1 -> $2 ($expectn)"
  [ -n "$DRYRUN" ] && return

  [ ! -d "$2" ] && mkdir "$2"
  find $1 -type f | xargs -I{} ln -s {} $2 || echo "issue with $2"
}
export -f link_glob

link_subjalldcm(){
 # validate input alldcmdir
 d="$1"
 [ -z "$d" -o ! -d "$d" ] && echo "bad alldcm subject directory '$d'" >&2  && return

 # get id
 id=$(getld8_dcmdir $d) || return 
 [ -z "$id" ] && id=$(getld8_db $d)
 [ -z "$id" ] && echo "no id for $d ($exampledcm)" && return

 echo "$id $d"

 # make subject
 [ -d "$id" -a "$2" == "skip" ] && echo "have $id; $0 $d # for verbose info" && return
 [ ! -d $id ] && mkdir $id
 
 # separate dicoms into their own dirs
 in_out $d | parallel --colsep ' ' link_glob {1} $id/{2}
}

# if no input, look at inputdirs.txt
if [ -z "$1" ]; then
  echo "# no raw dir given, using 000_gen_idlist.bash"
  $scriptdir/000_gen_idlist.bash| while read d ld8 sub_sess; do
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
