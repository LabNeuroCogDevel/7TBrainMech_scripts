#!/usr/bin/env bash
#
# run hurst_1d.py on outputs of 01_roi-meants.bash
# 20240324WF - refactor, extracted out of what was 01_roi-meants.bash

usage(){
   cat <<HEREDOC
USAGE:
   $0 [-h] -indir ts/atals-x_prefix-y -atlas altas/x.nii.gz -method [dfa|hurst_rs]

   -indir    folder with 3dROIstats output, likely from 01_roi-meants.bash
   -atlas    ROI atlas
   -method   must be either dfa (likely what you want) or hurst_rs
   -h        this help

SYNOPSIS:
   compute hurst metric on a TS x ROI 1D file.
   wraps around ./hurst_1d.py (itself usng hurst_nolds.py)

   generates roi labels (hardcoded) based on atlas

NOTES:
   see Makefile
   input from ./01_roi-meants.bash
   this is roi mean ts. compare to voxelwise 02_grpmaskave_voxhurst.bash

   script is a lot of boiler plate. 
   large script LOC size is historic, due to refactor
HEREDOC
}

parse_hurst_args(){
   ATLAS=""; INDIR=""; METHOD=""
   [ $# -eq 0 ] && usage && exit 1
   while [ $# -gt 0 ]; do
      case $1 in 
         -h) usage; exit 0;;
         -indir) INDIR="$2"; shift 2;;
         -method) METHOD="$2"; shift 2;;
         -atlas)  ATLAS="$2"; shift 2;;
         -output) OUTPUT="$2"; shift 2;;
         * ) echo "unknown option $1!"; exit 1;;
      esac
   done
   [[ -z "$ATLAS" || -z "$INDIR" || -z "$METHOD" || -z "$OUTPUT" ]] &&
      echo "-atlas, -method, -output and -indir are all required!" && exit 1
   ! [[ $METHOD =~ ^(hurst_rs|dfa)$ ]] && echo "method '$METHOD' must be hurst_rs or dfa" && exit 1
   [ ! -r "$ATLAS" ] && echo "Cannot read atlas file '$ATLAS'" && exit 2
   return 0
}

calc_hurst(){
    local ts_folder="${1:?input folder of 1D files}"
    local saveas="${2:?output name}"
    local method="${3:?dfa or hurst_rs}"
    local atlas="${4:?roi atlas nifti file}"
    case $atlas in
       *mancov*) roi_labels=(4_LPostInsula 5_RCaudate 7_ACC 8_MPFC 9_RDLPFC 10_LDLPFC);;
       *13MP*)   roi_labels=(1_RAntInsula 2_LAntInsula 3_RPostInsula 4_LPostInsula 5_RCaudate 6_LCaudate 7_ACC 8_MPFC 9_RDLPFC 10_LDLPFC 11_RSTS 12_LSTS 13_RThal);;
       *mni_gm50_mask.nii.gz)
                 roi_labels=(all_gm);;
       *) echo "unknown atlas '$atlas', want to match mancov, 13MP or mni_gm"; exit 3;;
    esac
    ./hurst_1d.py  --input "$ts_folder/1*_2*.1D" --output "$saveas" --method "$method" --roilabels "${roi_labels[@]}"
}

main_roimean_hurst(){
   parse_hurst_args "$@"
   #INDIR from 01_roi-meants.bash likey ts/atals-x_prefix-y
   calc_hurst "$INDIR" "$OUTPUT" "$METHOD" "$ATLAS"
}

# if not sourced (testing), run as command
eval "$(iffmain main_roimean_hurst)"
