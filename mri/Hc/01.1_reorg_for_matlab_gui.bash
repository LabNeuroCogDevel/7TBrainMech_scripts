#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
[ -v DRYRUN ] && DRYRUN=echo || DRYRUN=""
find_center(){
 local rdir="$1"; shift
 find -L "$rdir/" "$rdir/../CoregHC/registration_out/" -maxdepth 3 -type f,l  \
    \( -iname '1[56789]_7_FlipLR.MPRAGE' -or \
       -iname '*_7_FlipLR.MPRAGE.*' -or \
       -iname '*_7_FlipLR.MPRAGE' \
    \) \
    \( -ipath '*CoregHC*' -or -ipath '*CSIHC*' \) \
     -print -quit
}
list_all_or_one(){
  [ $# -eq 0 ] && list=(
    /Volumes/Hera/Raw/MRprojects/7TBrainMech/202*/Recon \
   $(ls -d /Volumes/Hera/Raw/MRprojects/7TBrainMech/202*/Shim/CoregH[cC] | xargs dirname) \
   /Volumes/Hera/Raw/MRprojects/7TBrainMech/202*/SHIM/CSIHC/ \
   /Volumes/Hera/Raw/MRprojects/7TBrainMech/20*/Recon_CSI/CSIHC \
   /Volumes/Hera/Raw/MRprojects/7TBrainMech/20230324/20*/Recon_CSI/CoregHC/ \
   /Volumes/Hera/Raw/MRprojects/7TBrainMech/{2023021[34],HCCollection}/2*/Recon_CSI/CoregHC) ||
   list=("$@")

  if [[ $# -eq 1 && $1 =~ 20.*[Aa][0-9]?$ ]]; then
     list=($(find /Volumes/Hera/Raw/MRprojects/7TBrainMech/$1/{Recon,Recon_CSI,S*/CSIHC,CoregHc} -maxdepth 0 -type d || :))

      verb "# $1 ${#list[@]} list: ${list[*]}" >&2
      [ ${#list[@]} -eq 0 ] && warn "# $1: no HC in /Volumes/Hera/Raw/MRprojects/7TBrainMech/$1/{Recon,Recon_CSI,S*/CSIHC,Recon_CSI/CoregHC}" && list=("/Volumes/Hera/Raw/MRprojects/7TBrainMech/$1/Recon*")
  fi
  printf '%s\n' "${list[@]}"
}

#
# reorganize files to for spectrum gui
#  20210825WF  init

# most coreg and siarray are in Recon. but a few are in Shim
# 20220303 201[89] organized differently

# single id

run_all(){ 
   mapfile -t list < <(list_all_or_one "$@")
  for rdir in "${list[@]}"; do
     [ ! -d "$rdir" ] && echo "# no dir like '$rdir' (checking both Recon and S*/CSIHC)" >&2 && continue
     ! [[ $rdir =~ 20[0-9]{6}L[Uu][Nn][Aa][1-9]? ]] && echo "# no MRDate in '$rdir'" >&2 && continue
     id=${BASH_REMATCH}
     siarray=$(find -L $rdir/ -maxdepth 2 -type f,l -iname siarray.1.1 -ipath '*CSIHC*' -print -quit)
     test -z "$siarray" -a -r "$rdir/../CSIHC" &&
        siarray=$(find -L "$_" -maxdepth 1 -type f,l -iname siarray.1.1 -print -quit)
     test -z "$siarray" -a -r "$rdir/../CSIHc" &&
        siarray=$(find -L "$_" -maxdepth 1 -type f,l -iname siarray.1.1 -print -quit)
     # scout might be larger or smaller, but we want middle of 13, so always 7th slice
     # 20221005: add *CSIHC* for
     #    rawdir=/Volumes/Hera/Raw/MRprojects/7TBrainMech/20210719Luna1/Recon
     #    ln -s $rawdir/{CoregHC/registration_out/17_7_FlipLR.MPRAGE,CSIHC}/
     #    ./01.1_reorg_for_matlab_gui.bash $rawdir/CSIHC/
     # 20221130 - added 15_7 for /Volumes/Hera/Raw/MRprojects/7TBrainMech/20210423Luna/Recon but that might be too high
     if [ -z "$siarray" -o ! -s "$siarray" ]; then
        dbhc=$(lncddb "select luna.id || '_'||to_char(vtimestamp,'YYYYmmdd'), measures->'Hc_Spectroscopy' from enroll mr
                join enroll luna on mr.pid=luna.pid and mr.etype like '%MR%' and luna.etype like 'LunaID'
                left join visit on mr.pid = visit.pid 
                   and visit.vtype = 'Scan'
                   and to_char(visit.vtimestamp,'YYYYmmdd') like substr(mr.id,1,8)
                natural left join visit_task
                where
                    visit_task.task = 'ScanLog'
                    and mr.id like '$id'" | uniq)
        warn "$id: missing siarray.1.1 -- probably not a HC visit ($rdir). scanlog db has $dbhc" >&2 
        continue
     fi
     center="$(find_center "$rdir")"
     [ -z "$center" -o ! -s "$center" ] && echo "$id: missing 17_7_FlipLR.MPRAGE -- maybe different res scout (e.g. need 21_10) ($rdir)" >&2 && continue
     outdir=$(pwd)/spectrum/$id 

     verb -level 2 "# outdir=$outdir"
     ! test -e "$outdir/siarray.1.1" && verb "# writting to $outdir"
     test -d $outdir || $DRYRUN mkdir $outdir
     test -e $outdir/siarray.1.1 || $DRYRUN ln -s $siarray $_
     test -e $outdir/recr.1.0.1.1.7 || $DRYRUN ln -s $center $_
     test -e $outdir/seg.7          || $DRYRUN ln -s $center $_
     test -e $outdir/anat.mat       || $DRYRUN ln -s $center $_
  
  done
}

eval "$(iffmain "run_all")"

