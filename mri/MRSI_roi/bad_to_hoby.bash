#!/usr/bin/env bash
#
# copy lcmodel outputs to better names for sending quality issues for debuging
#
# 20220315WF - init
#
[ -v DRYRUN ] && DRYRUN=echo || DRYRUN=
warn(){ echo "$@" >&2; }

file_list(){
for sdir in ../../../subjs/{11798,11732,11675,10195,11715,11561,11724,11683,11770,11757,11765,10997,11734,11781,11756,11769,11658,11674,10173,11688}_*/slice_PFC/MRSI_roi/13MP20200207/*/; do 
   sid3=$sdir/sid3_picked_coords.txt
   if [ ! -r $sid3 ]; then
      warn "# missing '$sid3'! maybe too old"
      $DRYRUN mk_sid3 $sdir/picked_coords.txt
      # echos new made file
   else
      echo $sid3
   fi
done
}
sid3(){ awk '{print 216-$3+1 "\t" 216-$2+1}' "$@"; }
mk_sid3(){
   # ../../../subjs/11732_20190204/slice_PFC/MRSI_roi/13MP20200207/MP/picked_coords.txt|sort
   picked_cord="$1"; shift
   [ ! -r $picked_cord ] && warn "no file like $picked_cord" && return 1
   output=$(dirname $picked_cord)/sid3_picked_coords.txt
   [ ! -r $output ] &&
     sid3 $picked_cord > $output
   # from matlab:
   #  sid3coords(:,1) = res(2) - coords(:,3) + 1;
   #  sid3coords(:,2) = res(1) - coords(:,2) + 1;
   echo $output
}

link_from_sid3(){
   local f="$1"; shift
   local ld8=$(ld8 $f)
   local outdir=txt/to_hoby_20220315/$ld8/ 
   test -d $outdir || $DRYRUN mkdir $outdir

   sed 's/:.*//;s/ /_/g' roi_locations/labels_13MP20200207.txt |
   paste - $f| grep ACC |
   while read label x y; do
         d=/Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/*/$ld8*/spectrum.$x.$y.dir
         [ ! -e $d ] && echo "# no match for '$d'" >&2 && continue
         link_as=$outdir/${label}.$(basename ${d/spectrum.} .dir)
         [ -e "$link_as" ] && continue
         echo "# $ld8 $label $d"
         $DRYRUN ln -s $d $link_as
   done
}


_bad_to_hoby() {
   mapfile -t bad_file_list < <(file_list)
  for f in "${bad_file_list[@]}"; do
     link_from_sid3 $f
  done
  return 0
}

# if not sourced (testing), run as command
if ! [[ "$(caller)" != "0 "* ]]; then
  set -euo pipefail
  trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error $e"' EXIT
  _bad_to_hoby "$@"
  exit $?
fi

####
# testing with bats. use like
#   bats ./bad_to_hoby.bash --verbose-run
####
if  [[ "$(caller)" =~ /bats.*/preprocessing.bash ]]; then
@test "sid3" {
   d=../../../subjs/11715_20210213/slice_PFC/MRSI_roi/13MP20200207/AG
   # exit 0 if inputs are the same
   diff -q $d/sid3_picked_coords.txt <(sid3 $d/picked_coords.txt)
}
fi
