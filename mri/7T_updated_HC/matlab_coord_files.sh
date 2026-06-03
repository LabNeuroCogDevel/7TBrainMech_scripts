#!/usr/bin/env bash
#
# copy over files needed to extract FS7.4 tissue composition
# in new project directory from original (mri/Hc)
#
# 20260331DW

set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
[ -v DRYRUN ] && DRYRUN=echo || DRYRUN=""

orig_dir=/Volumes/Hera/Projects/7TBrainMech/scripts/mri/Hc/spectrum
new_dir=/Volumes/Hera/Projects/7TBrainMech/scripts/mri/7T_updated_HC/spectrum

for subj_dir in "$orig_dir"/20*; do
	subj=$(basename "$subj_dir")

	# files needed
	coords=${subj_dir}/coordinates.txt
	hc_loc=${subj_dir}/hc_loc_ijk_afni_ml.1d

	# define final destination for files
	output_dir=${new_dir}/${subj}

	[[ -r "${coords}" ]] && dryrun cp "${coords}" "${output_dir}"
	[[ -r "${hc_loc}" ]] && dryrun cp "${hc_loc}" "${output_dir}"
done