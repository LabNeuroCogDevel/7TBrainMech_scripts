
[ $# -eq 1 ] && echo "USAGE: $0 coveragethres[0.0-1.0]" && exit 1
thes="$1"
3dMean -prefix all_rois_$thres.nii.gz -sum rois/*/coverage_ratio_gm_$thes.nii.gz
