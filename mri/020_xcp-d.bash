#!/usr/bin/env bash
# follow up 010_fmriprep.bash derivates with xcp-d processing
# initially to get surface based reho (for FC, Dylan)
#
# 20240501WF - init
# 20250221WF - add usebandpass option
# 20250514WF - use host certs to allow hospital man-in-middle. avoid SSL errors
export FSlic=/opt/ni_tools/freesurfer/license.txt
export MAXJOBS=20
export FDTHRES=${FDTHRES:-.5}         # prev was 0 (<=0 disables)
export USEBANDPASS=${USEBANDPASS:-no} # prev was yes (changed 20250221 for hurst)

xcpd(){
   prep_ses_dir="${1:?need ses derivative directory}"
   # NB. ses and sub swapped!
   #   didn't want to run longitudinal pipeline
   #   each session treated as separate dataset
   ! [[ $prep_ses_dir =~ (.*)/ses-([^/]*)/sub-([^/]*) ]] &&
      echo "ERROR: bad preproc deriv ses dir '$prep_ses_dir'. does not match sub-.*/ses.*" &&
      return 1

   prep_dir=$(readlink -f "${BASH_REMATCH[1]}")
   ses="${BASH_REMATCH[2]}"
   sub="${BASH_REMATCH[3]}"
   [[ -z "$prep_dir" || ! -d "$prep_dir" ]] &&
      echo "Bad fmriprep dir from ${BASH_REMATCH[1]} ('$prep_dir' of '$1')" &&
      return 1
   ses_dataset_dir="$prep_dir/ses-$ses"

   ## input version should be tracked too
   # Apr  1 12:10 fmriprep
   # Apr 15 15:59 fmriprep-25.0.0
   # Apr 21 13:52 fmriprep_tests
   # Apr 30 13:46 fmriprep-25.0.0-FST1
   ! [[ $prep_dir =~ fmriprep([^/]*) ]] && echo "input fmrirpep dir is not known to script!" && return 1
   [ -z "${BASH_REMATCH[1]}" ] && prepdesc="23.2.1" || prepdesc="${BASH_REMATCH[1]//[_-]/}"

   FS_dir=$ses_dataset_dir/FS/
   # 20240507 was /Volumes/Hera/Projects/7TBrainMech/scripts/mri/fmriprep/ses-1/xcpd/ses-1/sub-10173/
   # want /Volumes/Hera/Projects/7TBrainMech/scripts/mri/xcpd/ses-1/sub-10173/
   out_dir="$prep_dir/../xcpd/prep-${prepdesc}_fd-${FDTHRES}_bp-$USEBANDPASS/ses-$ses/" 
   #[[ $FDTHRES == 0 && $USEBANDPASS == yes ]] && out_dir="$prep_dir/../xcpd/ses-$ses/"  # 20241118 - preserve old naming for no FD
   dryrun mkdir -p "$out_dir"
   final_out="$out_dir/sub-$sub/func/sub-${sub}_task-rest_run-01_space-fsLR_den-91k_stat-reho_boldmap.dscalar.nii"
   
   test -r "$final_out" && echo "have $final_out" && return 0

   # 20240508:
   #   docker run -it --rm pennlinc/xcp_d:latest  --version
   #   XCP-D v0.7.3
   # 20250221: add option to 
   [[ "${USEBANDPASS:-}" == "no" ]] && bandpass_yesno="--disable-bandpass-filter" || bandpass_yesno=""

   printf "start\t$final_out\t$USER@$HOSTNAME\t%s\t%d\n" "$(date)" "$(date +%s)" | drytee -a "$out_dir/run.log"
   dryrun docker run --rm `#-it` \
      -v /etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro \
      -e REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt \
      -v "$ses_dataset_dir":/fmriprep:ro \
      -v "$FSlic:$FSlic:ro" \
      -v "/Volumes/Hera/tmp/wkdir_fd-${FDTHRES}_bp-${USEBANDPASS}":/work:rw \
      -v "$out_dir":/out:rw \
      -v "${FS_dir}":/freesurfer:ro \
      -v "/opt/ni_tools/templateflow:/opt/ni_tools/templateflow" \
      -v "/opt/ni_tools/templateflow:/root/.cache/templateflow" \
      -e "TEMPLATEFLOW_HOME=/opt/ni_tools/templateflow" \
      pennlinc/xcp_d:latest  \
      /fmriprep /out participant \
      --participant_label "$sub" \
      --fs-license-file "$FSlic" \
      $bandpass_yesno \
      `# --cifti # 20241118 now file-format` \
      --despike \
      --head_radius 40 -w /work \
      --smoothing 4 \
      -p 36P \
      --mode none `# 20241118: many new options needed (below)` \
      --input-type fmriprep \
      --file-format cifti \
      --output-type censored \
      --abcc-qc n \
      --linc-qc n \
      --combine-runs y \
      --warp-surfaces-native2std n \
      --min-coverage 0.5 \
      --min-time 100 `# after FD, min time needed in seconds` \
      --motion-filter-type none `#for physio? option 'lp' needs --band-stop-{min,max}`  \
      --fd-thresh "$FDTHRES"

   printf "end\t$final_out\t$USER@$HOSTNAME\t%s\t%d\n" "$(date)" "$(date +%s)" | drytee -a "$out_dir/run.log"
}

makevirt(){
 # documenting. only needed to run once
 python -m virtualenv /opt/ni_tools/python/virtualenv-xcpd
 source /opt/ni_tools/python/virtualenv-xcpd/bin/activate
 pip install git+https://github.com/pennlinc/xcp_d.git
}

xcpd_py(){
 # documenting. only need to run once to get temlate flows
 # b/c of upmc+python cert issues
 source /opt/ni_tools/python/virtualenv-xcpd/bin/activate
 export TEMPLATEFLOW_HOME=/opt/ni_tools/templateflow
 xcp_d\
      "$ses_dataset_dir"\
      "$out_dir" \
      participant \
      --participant_label "$sub" \
      --fs-license-file "$FSlic" \
      --cifti --despike \
      --head_radius 40 -w /work \
      --smoothing 4
}

# This replaced by 011_fmriprep_fixtr.bash
change_tr() {
   perl -pie 's{("RepetitionTime": |SeriesStep=")(0.048|0.054)}{$1 . sprintf("%.3f",$2*82/2)}e' "$@"
#grep -Poa 'SeriesStep="[^"]+"' /Volumes/Hera/Projects/7TBrainMech/scripts/mri/fmriprep/ses-1/sub-10173/func/sub-10173_task-rest_run-01_space-fsLR_den-91k_bold.dtseries.nii
#SeriesStep="0.048"
#
#grep Rep /Volumes/Hera/Projects/7TBrainMech/scripts/mri/fmriprep/ses-1/sub-10173/func/sub-10173_task-rest_run-01_space-fsLR_den-91k_bold.json
#  "RepetitionTime": 0.048,

# "TR"*numslice/acceleation => actual TR
#  .048*82/2    => 1.968
#  .054*82/2    => 2.214
#
}

xcpd_main() {
   # read args and run on individual
   cd "$(dirname "$0")" || exit 1
   # usage if not all or specific file
   if [[ $# -eq 0 || $* =~ ^-+h ]]; then
      echo "$0 [all | /Volumes/Hera/Projects/7TBrainMech/scripts/mri/fmriprep/ses-1/sub-10129/  ]"
      echo "env: FDTHRES=0 to disable fd; USEBANDPASS=yes to enable bandpass filtering"
      echo "ouput xcpd/fd-0_bp-no/"
      exit 1
   fi

   [[ $1 == "all" ]] &&
      inputs=("$PWD"/fmriprep-25.0.0-FST1/ses-[1-3]/sub-1*/) ||
      inputs=("$@")

   for prepdir in "${inputs[@]}"; do 
      echo "# $prepdir"
      #pgrep -af "xcp.*$prepdir" && echo "# already running" && continue
      xcpd "$prepdir" &
      waitforjobs --config auto
   done

   wait
}

eval "$(iffmain xcpd_main)"
