SHELL=bash
## from BIDS to 1*_2*/mt/
# /Volumes/Hera/Raw/BIDS/7TBrainMech/sub-xxxxx/yyyymmdd/mt/sub-xxxxx_MT_acq-no.nii.gz
# /Volumes/Hera/Projects/7TBrainMech/subjs/xxxxx/yyyymmdd/mt/MTR1.nii.gz
# debug:  make -rdn --warn-undefined-variables
allMTno := $(wildcard /Volumes/Hera/Raw/BIDS/7TBrainMech/sub-1*/2*/mt/sub*acq-no.nii.gz)
MTR := $(shell ./bids_v_mtr $(allMTno))
all: ${MTR}
# could be simplified if only had one of sub-ID/SES or ID_SES 
# but we have both so a wildcard '%' isn't sufficent
# using 'bids_v_mtr' to get input file name from output file name
# and building a rule for each MTR file expected
# help from 
# https://stackoverflow.com/questions/3745177/multi-wildcard-pattern-rules-of-gnu-make
# $$shell and $$< are evaluated on second pass. variable 'mtr' defined/set by foreach loop (?)
# "-" is continue if failed. one missing:
#    /Volumes/Hera/Raw/BIDS/7TBrainMech/sub-11689/20210605/mt/*_MT_acq-yes.nii.gz
# input to mt_warp should be bids session directory
define MT2MTR
$(mtr): $(shell ./bids_v_mtr $(mtr))
	-./mt_warp.bash $$(shell sed s/mt.*// <<< $$<)
endef

$(foreach mtr,$(MTR),$(eval $(call MT2MTR,mtr)))

# SUBJS := $(shell echo $(MTR)|grep -Po '\d{5}_\d{8}' )
