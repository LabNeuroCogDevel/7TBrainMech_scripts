#!/usr/bin/env bash
#
# 20240324: refactor from 01_maskave_and_pyhurst.bash to 01_roi-meants
#  see use in Makefile 
#   ./01_roi-meants.bash -outdir ts/atlas-cov6GM_prefix-brnasw -atlas atlas/13MP20200207_mancov-centered_GMgt0.5-mask.nii.gz -- /Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_ica/1*_2*/brnaswdkm_func_4.nii.gz
usage(){
   cat <<HEREDOC
USAGE:
   $0 [-h] -outdir ts/atals-x_prefix-y -atlas altas/x.nii.gz -- /path/to/1*_2*/brnasw*func_4.nii.gz

   -outdir    folder without 3dROIstats output
   -atlas     ROI atlas
   -- files   list of files. ld8 extracted to create \$outdir/\$ld8.1D
   -h         this help

SYNOPSIS:
   wraps around
     3dROIstats -quiet -nomeanout -nzmean -1DRformat -mask  "\$mask" "\$tsnii" > "\$outdir/\$ld8.1D"  &

   large LOC size is historic, due to refactor. ./02_roimean_hurst.bash previous was part of this file.
NOTES:
   see Makefile
   output of this is input to ./02_roimean_hurst.bash
   this is roi mean ts. compare to 01_voxelwise.bash
HEREDOC
}

# waitforjobs loop around 3dROIstats
# writes files like $out_folder/12345_20210531.1D (luna_date.1D)
calc_ts(){
   local out_folder="$1"; shift
   local mask="$1"  ; shift
   # shellcheck disable=SC2206 # want to split
   local files=("$@");

   echo "# ${#files[@]} files into $out_folder using $mask"
   mkdir -p "$out_folder"
   for tsnii in "${files[@]}"; do
      out=$out_folder/$(ld8 "$tsnii").1D
      [ -s "$out" ] && continue
      # NB. no censoring. need continious timeseries for hurst/dfa

      # creates nTR (num volumes) rows by nROI columns
      (3dROIstats -quiet -nomeanout -nzmean -1DRformat -mask  "$mask" "$tsnii" > "$out" ) &
      MAXJOBS=${MAXJOBS:-50} waitforjobs
   done
   wait
}
parse_ts_args(){
   ATLAS=""; PREFIX=""; METHOD=""
   [ $# -eq 0 ] && usage && exit 1;
   while [ $# -gt 0 ]; do
      case $1 in 
         -h) usage; exit 0;;
         -outdir) PREFIX="$2"; shift 2;;
         -atlas)  ATLAS="$2"; shift 2;;
         --) shift; break;;
         * ) echo "unknown option $1!"; exit 1;;
      esac
   done
   [[ -z "$ATLAS" || -z "$PREFIX" ]] &&
      echo "-atlas and -outdir are all required!" && exit 1
   [ ! -r "$ATLAS" ] && echo "Cannot read atlas file '$ATLAS'" && exit 2
   FILES=("$@")
   [ ${#FILES[@]} -lt 3 ] && echo "expect more than 3 input files after --" && exit 5
   return 0
}

calc_ts_main(){
   parse_ts_args "$@"
   calc_ts "$PREFIX" "$ATLAS" "${FILES[@]}"
}

eval "$(iffmain calc_ts_main)"
