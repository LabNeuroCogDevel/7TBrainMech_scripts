20220221 - Makefile runs `mt_warp.bash` for all mt in BIDS (non-standard)

from `/Volumes/Hera/Raw/BIDS/7TBrainMech/sub-xxxxx/yyyymmdd/mt/sub-xxxxx_MT_acq-no.nii.gz`
makes `/Volumes/Hera/Projects/7TBrainMech/subjs/xxxxx/yyyymmdd/mt/MTR1.nii.gz`

Uses a macro (complicated by `sub-ID/SES` vs `ID_SES`) in Make to take the place of a wrapper script.
has the benifit of built in parallel and update checking.
but we lose dynamic job count (like in waitforjobs) and have more code complexity. `make` is more nitch than bash and requires some meta programming/eval. And tab complete on make is very slow -- targets are dynamically generated and per file. (The alternative single-file-per-step sentinal files would tab-complete much faster.)
