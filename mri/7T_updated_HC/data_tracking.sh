#!/usr/bin/env bash
#
# Session tracking for 7T MRSI HPC project.
# Does NOT modify any files.
#
# Saves named session lists and a summary report to $diag_dir.
#
# 20260402DW

rawdir=/Volumes/Hera/Raw/MRprojects/7TBrainMech
new_spec=/Volumes/Hera/Projects/7TBrainMech/scripts/mri/7T_updated_HC/spectrum
orig_spec=/Volumes/Hera/Projects/7TBrainMech/scripts/mri/Hc/spectrum

# where all output lists and the summary report is written
diag_dir=/Volumes/Hera/Projects/7TBrainMech/scripts/mri/7T_updated_HC/diagnostic_$(date +%Y%m%d)
mkdir -p "$diag_dir"

summary="$diag_dir/summary_report.txt"
> "$summary"   # clear/create on each run

log()  { echo "$*" | tee -a "$summary"; }
warn() { echo "  [!] $*" | tee -a "$summary"; }
hr()   { log "──────────────────────────────────────────────────────────────"; }

log "Pipeline Diagnostic — $(date)"
log "new spectrum dir : $new_spec"
log "orig spectrum dir: $orig_spec"
log "raw data dir     : $rawdir"
hr

# ─── SECTION 1: SPECTRUM DIRECTORY CREATION ───────────────────────────────────
#   How many session directories were created by 01_reorg_mrsi_data_links.sh
#   in the new spectrum directory.
hr
log "SECTION 1: Spectrum directory creation"
log "Counting session directories in new spectrum dir..."

mapfile -t all_new_dirs < <(find "$new_spec" -maxdepth 1 -type d -name '20*Luna*' | sort)
n_dirs=${#all_new_dirs[@]}
log "  Session directories found : $n_dirs"

printf '%s\n' "${all_new_dirs[@]}" | xargs -I{} basename {} > "$diag_dir/all_new_dirs.txt"
log "  Saved to: all_new_dirs.txt"


# ─── SECTION 2: SIARRAY LINKING ───────────────────────────────────────────────
#   Of the directories created, how many actually have the raw MRSI data
#   (siarray.1.1) linked in.
#
#   For sessions missing siarray.1.1, check whether the raw file
#   actually EXISTS under rawdir. This separates two failure modes:
#     - EXISTS_ON_DISK   → raw data is there but the symlink was never made;
#                          recoverable by re-running or fixing rescue script
#     - TRULY_MISSING    → raw data was never collected or is on a different
#                          volume; these sessions likely can't be recovered
hr
log "SECTION 2: siarray.1.1 linking"

missing_siarray=()
has_siarray=()
for d in "${all_new_dirs[@]}"; do
    if [ -e "$d/siarray.1.1" ]; then
        has_siarray+=("$(basename "$d")")
    else
        missing_siarray+=("$(basename "$d")")
    fi
done

log "  Has siarray.1.1    : ${#has_siarray[@]}"
log "  Missing siarray.1.1: ${#missing_siarray[@]}"

printf '%s\n' "${has_siarray[@]}"    > "$diag_dir/has_siarray.txt"
printf '%s\n' "${missing_siarray[@]}" > "$diag_dir/missing_siarray.txt"
log "  Saved to: has_siarray.txt, missing_siarray.txt"

# For missing ones, check if the raw file exists
exists_on_disk=()
truly_missing=()
log "  Checking rawdir for missing siarray sessions (may take a moment)..."
for id in "${missing_siarray[@]}"; do
    found=$(find -L "$rawdir" -path "*$id*" -iname 'siarray.1.1' 2>/dev/null | head -n1)
    if [ -n "$found" ]; then
        exists_on_disk+=("$id|$found")
    else
        truly_missing+=("$id")
    fi
done

log "  Missing siarray — EXISTS on rawdir (linkable) : ${#exists_on_disk[@]}"
log "  Missing siarray — TRULY missing from rawdir   : ${#truly_missing[@]}"

printf '%s\n' "${exists_on_disk[@]}" > "$diag_dir/siarray_exists_on_disk.txt"
printf '%s\n' "${truly_missing[@]}"  > "$diag_dir/siarray_truly_missing.txt"
log "  Saved to: siarray_exists_on_disk.txt, siarray_truly_missing.txt"

if [ ${#truly_missing[@]} -gt 0 ]; then
    warn "Truly missing sessions had no HC spectroscopy collected OR data is on"
    warn "an unmounted volume. Cross-check against your prelim both_subjects.txt."
fi


# ─── SECTION 3: ANAT/SEG/RECR LINKING ────────────────────────────────────────
#   All three of anat.mat, seg.7, recr.1.0.1.1.7 should be present for each
#   session (they're symlinks to the same *_7_FlipLR.MPRAGE file).
#   If any are missing, that session will fail downstream in the MATLAB GUI
#   and FS alignment steps. We track which specific file(s) are absent so
#   you can tell whether it's a partial vs. complete linking failure.
hr
log "SECTION 3: anat.mat / seg.7 / recr.1.0.1.1.7 linking"

missing_anat=(); missing_seg=(); missing_recr=()
for d in "${all_new_dirs[@]}"; do
    id=$(basename "$d")
    [ ! -e "$d/anat.mat" ]         && missing_anat+=("$id")
    [ ! -e "$d/seg.7" ]            && missing_seg+=("$id")
    [ ! -e "$d/recr.1.0.1.1.7" ]  && missing_recr+=("$id")
done

log "  Missing anat.mat        : ${#missing_anat[@]}"
log "  Missing seg.7           : ${#missing_seg[@]}"
log "  Missing recr.1.0.1.1.7  : ${#missing_recr[@]}"

printf '%s\n' "${missing_anat[@]}"  > "$diag_dir/missing_anat.txt"
printf '%s\n' "${missing_seg[@]}"   > "$diag_dir/missing_seg.txt"
printf '%s\n' "${missing_recr[@]}"  > "$diag_dir/missing_recr.txt"
log "  Saved to: missing_anat.txt, missing_seg.txt, missing_recr.txt"

# Flag sessions missing all three — these are total linking failures
missing_all_three=()
for d in "${all_new_dirs[@]}"; do
    id=$(basename "$d")
    if [ ! -e "$d/anat.mat" ] && [ ! -e "$d/seg.7" ] && [ ! -e "$d/recr.1.0.1.1.7" ]; then
        missing_all_three+=("$id")
    fi
done
log "  Missing ALL THREE (complete link failure): ${#missing_all_three[@]}"
printf '%s\n' "${missing_all_three[@]}" > "$diag_dir/missing_all_three_links.txt"
log "  Saved to: missing_all_three_links.txt"


# ─── SECTION 4: MATLAB GUI PLACEMENTS ────────────────────────────────────────
# What we're looking for:
#   Two output files are generated by the GUI + downstream steps:
#     - coordinates.txt         (ROI placement coordinates)
#     - hc_loc_ijk_afni_ml.1d   (rotated/transformed 1D coordinate file)
#
#   For sessions missing coordinates.txt, we check the ORIGINAL spectrum
#   directory (orig_spec). This separates:
#     - IN_ORIG_NOT_COPIED  → placement was made in the old project but
#                             matlab_coord_files.sh failed to copy it over;
#                             directly recoverable
#     - NEVER_PLACED        → no placement exists anywhere; subject needs
#                             to be manually placed in the GUI before
#                             proceeding, or may be excluded
#
#   Flag sessions that have coordinates.txt but are missing the
#   1d file, which suggests 06_FS74_labels.sh ran but the awk/3dUndump
#   step failed mid-run.
hr
log "SECTION 4: MATLAB GUI placement files"

has_coords=(); missing_coords=()
has_1d=(); missing_1d=()
for d in "${all_new_dirs[@]}"; do
    id=$(basename "$d")
    if [ -e "$d/coordinates.txt" ]; then
        has_coords+=("$id")
    else
        missing_coords+=("$id")
    fi
    if [ -e "$d/hc_loc_ijk_afni_ml.1d" ]; then
        has_1d+=("$id")
    else
        missing_1d+=("$id")
    fi
done

log "  Has coordinates.txt         : ${#has_coords[@]}"
log "  Missing coordinates.txt     : ${#missing_coords[@]}"
log "  Has hc_loc_ijk_afni_ml.1d   : ${#has_1d[@]}"
log "  Missing hc_loc_ijk_afni_ml.1d: ${#missing_1d[@]}"

printf '%s\n' "${has_coords[@]}"    > "$diag_dir/has_coords.txt"
printf '%s\n' "${missing_coords[@]}" > "$diag_dir/missing_coords.txt"
printf '%s\n' "${has_1d[@]}"        > "$diag_dir/has_1d.txt"
printf '%s\n' "${missing_1d[@]}"    > "$diag_dir/missing_1d.txt"
log "  Saved to: has_coords.txt, missing_coords.txt, has_1d.txt, missing_1d.txt"

# Check for sessions missing coords.txt but has siarray
# These are sessions where raw data exists but placement was never done
coords_missing_but_has_siarray=()
for id in "${missing_coords[@]}"; do
    if [ -e "$new_spec/$id/siarray.1.1" ]; then
        coords_missing_but_has_siarray+=("$id")
    fi
done
log "  Missing coords but HAS siarray (unplaced sessions): ${#coords_missing_but_has_siarray[@]}"
printf '%s\n' "${coords_missing_but_has_siarray[@]}" > "$diag_dir/unplaced_sessions.txt"
log "  Saved to: unplaced_sessions.txt"

# Check orig dir for missing coords
in_orig_not_copied=(); never_placed=()
for id in "${missing_coords[@]}"; do
    if [ -e "$orig_spec/$id/coordinates.txt" ]; then
        in_orig_not_copied+=("$id")
    else
        never_placed+=("$id")
    fi
done
log "  Missing coords — IN ORIG (copy failure): ${#in_orig_not_copied[@]}"
log "  Missing coords — NEVER PLACED anywhere  : ${#never_placed[@]}"

printf '%s\n' "${in_orig_not_copied[@]}" > "$diag_dir/coords_in_orig_not_copied.txt"
printf '%s\n' "${never_placed[@]}"       > "$diag_dir/coords_never_placed.txt"
log "  Saved to: coords_in_orig_not_copied.txt, coords_never_placed.txt"

# Sessions with coords but missing 1d file — partial run failure
coords_but_no_1d=()
for id in "${has_coords[@]}"; do
    [ ! -e "$new_spec/$id/hc_loc_ijk_afni_ml.1d" ] && coords_but_no_1d+=("$id")
done
log "  Has coords but missing 1d file (partial run failure): ${#coords_but_no_1d[@]}"
printf '%s\n' "${coords_but_no_1d[@]}" > "$diag_dir/coords_but_no_1d.txt"
log "  Saved to: coords_but_no_1d.txt"


# ─── SECTION 5: FS74 SCOUT ALIGNMENT (04_FS74_to_HcScout.sh) ─────────────────
# What we're looking for:
#   The final output of 04_FS74_to_HcScout.sh for each session is:
#     FS_warp/${ld8}_aseg74-HcScout_HcOnly.nii.gz
#   and the affine used downstream by 05 and 06 is:
#     FS_warp/${ld8}_T1-HcScout_0GenericAffine.mat
#
#   Missing HcOnly file = FS alignment never completed for this session.
#   Missing affine = ANTs registration step failed or was never run.
#   Both missing = 04 was never run or exited early for this session.
hr
log "SECTION 5: FS74 scout alignment outputs (04_FS74_to_HcScout.sh)"

has_hconly=(); missing_hconly=()
missing_affine=()
for d in "${all_new_dirs[@]}"; do
    id=$(basename "$d")
    hconly=$(ls "$d"/FS_warp/*_aseg74-HcScout_HcOnly.nii.gz 2>/dev/null | head -n1)
    affine=$(ls "$d"/FS_warp/*_T1-HcScout_0GenericAffine.mat 2>/dev/null | head -n1)

    if [ -n "$hconly" ]; then
        has_hconly+=("$id")
    else
        missing_hconly+=("$id")
    fi
    [ -z "$affine" ] && missing_affine+=("$id")
done

log "  Has HcOnly nii.gz   : ${#has_hconly[@]}"
log "  Missing HcOnly      : ${#missing_hconly[@]}"
log "  Missing affine .mat : ${#missing_affine[@]}"

printf '%s\n' "${has_hconly[@]}"    > "$diag_dir/has_hconly.txt"
printf '%s\n' "${missing_hconly[@]}" > "$diag_dir/missing_hconly.txt"
printf '%s\n' "${missing_affine[@]}" > "$diag_dir/missing_affine.txt"
log "  Saved to: has_hconly.txt, missing_hconly.txt, missing_affine.txt"


# ─── SECTION 6: FS74 ROI MASKS (05_FS74_roimasks.sh) ─────────────────────────
# What we're looking for:
#   Two output files per session from 05_FS74_roimasks.sh:
#     FS_warp/${ld8}_HBTlr500_FS74_scout.nii.gz  (HBT mask, ~177 expected)
#     FS_warp/${ld8}_gm_FS74.scout.nii.gz         (GM mask, ~178 expected)
#
#   If HBT is missing but gm is present (or vice versa), that suggests a
#   partial run where one branch failed. HBT failures are more common
#   because they depend on both hemispheres of the longitudinal FS output
#   existing, whereas GM only needs aseg.mgz.
hr
log "SECTION 6: FS74 ROI masks (05_FS74_roimasks.sh)"

has_hbt=(); missing_hbt=()
has_gm=(); missing_gm=()
hbt_not_gm=(); gm_not_hbt=()

for d in "${all_new_dirs[@]}"; do
    id=$(basename "$d")
    hbt=$(ls "$d"/FS_warp/*_HBTlr500_FS74_scout.nii.gz 2>/dev/null | head -n1)
    gm=$(ls  "$d"/FS_warp/*_gm_FS74.scout.nii.gz       2>/dev/null | head -n1)

    if [ -n "$hbt" ]; then has_hbt+=("$id"); else missing_hbt+=("$id"); fi
    if [ -n "$gm"  ]; then has_gm+=("$id");  else missing_gm+=("$id");  fi

    [ -n "$hbt" ] && [ -z "$gm"  ] && hbt_not_gm+=("$id")
    [ -n "$gm"  ] && [ -z "$hbt" ] && gm_not_hbt+=("$id")
done

log "  Has HBT scout   : ${#has_hbt[@]}"
log "  Missing HBT     : ${#missing_hbt[@]}"
log "  Has GM scout    : ${#has_gm[@]}"
log "  Missing GM      : ${#missing_gm[@]}"
log "  HBT present, GM missing (partial run): ${#hbt_not_gm[@]}"
log "  GM present, HBT missing (partial run): ${#gm_not_hbt[@]}"

printf '%s\n' "${has_hbt[@]}"     > "$diag_dir/has_hbt.txt"
printf '%s\n' "${missing_hbt[@]}" > "$diag_dir/missing_hbt.txt"
printf '%s\n' "${has_gm[@]}"      > "$diag_dir/has_gm.txt"
printf '%s\n' "${missing_gm[@]}"  > "$diag_dir/missing_gm.txt"
printf '%s\n' "${hbt_not_gm[@]}"  > "$diag_dir/hbt_not_gm.txt"
printf '%s\n' "${gm_not_hbt[@]}"  > "$diag_dir/gm_not_hbt.txt"
log "  Saved to: has_hbt.txt, missing_hbt.txt, has_gm.txt, missing_gm.txt"
log "            hbt_not_gm.txt, gm_not_hbt.txt"


# ─── SECTION 7: LABEL CSV OUTPUTS (06_FS74_labels.sh + fs_label_idv.R) ────────
# What we're looking for:
#   The final output CSVs from fs_label_idv.R when run in matlab mode are
#   suffixed with _ml (see outputname() in fs_label_idv.R). The bash script
#   06_FS74_labels.sh checks for the NON-suffixed versions, so the skip
#   logic never fires — but for counting completions we must check for
#   the correct _ml versions. Expected ~159 per your notes.
#
#   For sessions missing any CSV, we check which upstream prerequisite is
#   absent to categorize the failure reason:
#     NO_COORDS       → coordinates.txt never made it to this directory
#     NO_ASEG_SCOUT   → 04_FS74_to_HcScout.sh did not complete
#     NO_HBT_SCOUT    → 05_FS74_roimasks.sh HBT step did not complete
#     NO_GM_SCOUT     → 05_FS74_roimasks.sh GM step did not complete
#     UNKNOWN_FAILURE → all prereqs present but CSV still missing;
#                       likely an R runtime error — check R logs
hr
log "SECTION 7: Label CSV outputs (06_FS74_labels.sh + fs_label_idv.R)"

has_all_csvs=()
missing_csvs_no_coords=()
missing_csvs_no_aseg=()
missing_csvs_no_hbt=()
missing_csvs_no_gm=()
missing_csvs_unknown=()

for d in "${all_new_dirs[@]}"; do
    id=$(basename "$d")

    aseg_csv="$d/hc_aseg74_roirat_ml.csv"
    hbt_csv="$d/hc_HBT74_roirat_ml.csv"
    gm_csv="$d/hc_gm74_rat_ml.csv"

    if [ -e "$aseg_csv" ] && [ -e "$hbt_csv" ] && [ -e "$gm_csv" ]; then
        has_all_csvs+=("$id")
        continue
    fi

    # categorize the failure by which upstream file is missing
    if [ ! -e "$d/coordinates.txt" ]; then
        missing_csvs_no_coords+=("$id")
    elif [ -z "$(ls "$d"/FS_warp/*_aseg74_scout.nii.gz 2>/dev/null)" ]; then
        missing_csvs_no_aseg+=("$id")
    elif [ -z "$(ls "$d"/FS_warp/*_HBTlr500_FS74_scout.nii.gz 2>/dev/null)" ]; then
        missing_csvs_no_hbt+=("$id")
    elif [ -z "$(ls "$d"/FS_warp/*_gm_FS74.scout.nii.gz 2>/dev/null)" ]; then
        missing_csvs_no_gm+=("$id")
    else
        missing_csvs_unknown+=("$id")
    fi
done

total_missing_csvs=$(( ${#missing_csvs_no_coords[@]} + ${#missing_csvs_no_aseg[@]} + \
                       ${#missing_csvs_no_hbt[@]}    + ${#missing_csvs_no_gm[@]}   + \
                       ${#missing_csvs_unknown[@]} ))

log "  Has ALL label CSVs (_ml)     : ${#has_all_csvs[@]}"
log "  Missing CSVs total           : $total_missing_csvs"
log "    → reason: NO_COORDS        : ${#missing_csvs_no_coords[@]}"
log "    → reason: NO_ASEG_SCOUT    : ${#missing_csvs_no_aseg[@]}"
log "    → reason: NO_HBT_SCOUT     : ${#missing_csvs_no_hbt[@]}"
log "    → reason: NO_GM_SCOUT      : ${#missing_csvs_no_gm[@]}"
log "    → reason: UNKNOWN (R fail?) : ${#missing_csvs_unknown[@]}"

printf '%s\n' "${has_all_csvs[@]}"            > "$diag_dir/has_all_csvs.txt"
printf '%s\n' "${missing_csvs_no_coords[@]}"  > "$diag_dir/fail_no_coords.txt"
printf '%s\n' "${missing_csvs_no_aseg[@]}"    > "$diag_dir/fail_no_aseg_scout.txt"
printf '%s\n' "${missing_csvs_no_hbt[@]}"     > "$diag_dir/fail_no_hbt_scout.txt"
printf '%s\n' "${missing_csvs_no_gm[@]}"      > "$diag_dir/fail_no_gm_scout.txt"
printf '%s\n' "${missing_csvs_unknown[@]}"    > "$diag_dir/fail_unknown.txt"
log "  Saved to: has_all_csvs.txt, fail_no_coords.txt, fail_no_aseg_scout.txt"
log "            fail_no_hbt_scout.txt, fail_no_gm_scout.txt, fail_unknown.txt"


# ─── SECTION 8: END-TO-END COMPLETE SESSIONS ──────────────────────────────────
# What we're looking for:
#   Sessions that have made it through every stage of the pipeline with all
#   required files present. These are your analysis-ready sessions.
#   Any session NOT in this list but in your prelim both_subjects.txt is a
#   recoverable or irrecoverable loss that needs to be accounted for.
hr
log "SECTION 8: End-to-end complete sessions"

complete_sessions=()
for d in "${all_new_dirs[@]}"; do
    id=$(basename "$d")
    has_si=$(  [ -e "$d/siarray.1.1" ]                                       && echo 1 || echo 0)
    has_an=$(  [ -e "$d/anat.mat" ]                                           && echo 1 || echo 0)
    has_co=$(  [ -e "$d/coordinates.txt" ]                                    && echo 1 || echo 0)
    has_1d=$(  [ -e "$d/hc_loc_ijk_afni_ml.1d" ]                             && echo 1 || echo 0)
    has_hc=$(  ls "$d"/FS_warp/*_aseg74-HcScout_HcOnly.nii.gz &>/dev/null    && echo 1 || echo 0)
    has_hb=$(  ls "$d"/FS_warp/*_HBTlr500_FS74_scout.nii.gz   &>/dev/null    && echo 1 || echo 0)
    has_gm=$(  ls "$d"/FS_warp/*_gm_FS74.scout.nii.gz          &>/dev/null    && echo 1 || echo 0)
    has_csv=$( [ -e "$d/hc_aseg74_roirat_ml.csv" ] && \
               [ -e "$d/hc_HBT74_roirat_ml.csv"  ] && \
               [ -e "$d/hc_gm74_rat_ml.csv"       ]                          && echo 1 || echo 0)

    if [[ "$has_si$has_an$has_co$has_1d$has_hc$has_hb$has_gm$has_csv" == "11111111" ]]; then
        complete_sessions+=("$id")
    fi
done

log "  Fully complete sessions: ${#complete_sessions[@]}"
printf '%s\n' "${complete_sessions[@]}" > "$diag_dir/complete_sessions.txt"
log "  Saved to: complete_sessions.txt"


# ─── FINAL SUMMARY ────────────────────────────────────────────────────────────
hr
log "FINAL SUMMARY"
log "  Stage                          | N"
log "  -------------------------------|-----"
log "  Spectrum dirs created          | $n_dirs"
log "  Has siarray.1.1               | ${#has_siarray[@]}"
log "  Has anat.mat                   | $(( n_dirs - ${#missing_anat[@]} ))"
log "  Has coordinates.txt            | ${#has_coords[@]}"
log "  Has hc_loc_ijk_afni_ml.1d     | ${#has_1d[@]}"
log "  Has FS74 HcOnly nii.gz         | ${#has_hconly[@]}"
log "  Has HBT scout                  | ${#has_hbt[@]}"
log "  Has GM scout                   | ${#has_gm[@]}"
log "  Has all label CSVs (_ml)       | ${#has_all_csvs[@]}"
log "  FULLY COMPLETE                 | ${#complete_sessions[@]}"
hr
log "All diagnostic files written to: $diag_dir"
log "Done — $(date)"