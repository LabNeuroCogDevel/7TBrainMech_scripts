# we start with raw rest files in BIDS standard
RAWREST := $(wildcard /Volumes/Hera/Raw/BIDS/7TBrainMech/sub-*/*/func/*task-rest_*bold.nii.gz)
# as specified in
#   /opt/ni_tools/preproc_pipelines/sources/7TBrainMech_rest

.make/preproc.ls: $(RAWREST) | .make/
	./00_preproc_nosmooth.bash
	mkls $@ "/Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_nowarp_nosmooth/1*_2*/Wbgrndkm_func.nii.gz"

# generic rule to make directories
%/:
	mkdir -p $@
