.PHONY: gmmasks
.PRECIOUS: %/gmmask.nii.gz %/Wbgrndkm_func.nii.gz 

# we start with raw rest files in BIDS standard
RAWREST := $(wildcard /Volumes/Hera/Raw/BIDS/7TBrainMech/sub-*/*/func/*task-rest_*bold.nii.gz)
# as specified in
#   /opt/ni_tools/preproc_pipelines/sources/7TBrainMech_rest

.make/preproc.ls: $(RAWREST) | .make/
	./001_preproc_nosmooth.bash
	mkls $@ "/Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_nowarp_nosmooth/1*_2*/Wbgrndkm_func.nii.gz"

txt/age_sex.tsv: .make/preproc.ls
	ld8 < .make/preproc.ls |xargs ld8info | mlr --tsv cut -f ld8,age,sex then  format-values -f %0.0f > $@

txt/maskave-MPFC_ACC.csv: images/1*_2*/reho-gmmask_epimasked_n27_space-mni.nii.gz
	3dmaskave_grp -csv $@ -m 'acc=/Volumes/Hera/Projects/Maria/7Trest_mrsi/mvm/ACC_p2-16_cl40.nii.gz<1>' -m 'mpfc=/Volumes/Hera/Projects/Maria/7Trest_mrsi/mvm/MPFC_p2-16_cl40.nii.gz<1>' -- $^

txt/overall_mean.csv: images/1*_2*/reho-gmmask_epimasked*.nii.gz
	./030_visit_mean.bash
###
LD8 := $(shell echo "$(RAWREST)" |perl -pe 's:/Volumes/.*?/sub-::g;s:/func/[^ ]*::g;s:/:_:g' )
#APARC := $(patsubst %,/Volumes/Hera/preproc/7TBrainMech_rest/FS7.2/highres/%/mri/aparc+aseg.mgz,$(LD8))
APARC := $(wildcard /Volumes/Hera/preproc/7TBrainMech_rest/FS7.2/*/1*_2*/mri/aseg.mgz)
GMASK := $(subst aseg.mgz,gmmask.nii.gz,$(APARC))
gmmasks: $(GMASK) # gmmasks is target for all of APARC->GMMASK

GMRES := $(patsubst %,/Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_nowarp_nosmooth/%/gmmask_restres.nii.gz,$(LD8))
gmmasks_res: $(GMRES)

%/gmmask.nii.gz: %/aseg.mgz
	niinote $@ mri_binarize --i $(subst gmmask.nii.gz,aseg.mgz,$@) --o $@ --gm 
	3dNotes -h "make -C $(PWD) $@" $@

# NB: wildcard secondary expansion will silently fail when no FS for visit.
#     causes error in 3dresample
.SECONDEXPANSION:
%/gmmask_restres.nii.gz: %/Wbgrndkm_func.nii.gz $$(word 1,$$(wildcard /Volumes/Hera/preproc/7TBrainMech_rest/FS7.2/*/$$(notdir %)/mri/gmmask.nii.gz))
	3dresample -overwrite -prefix $@ -master $(word 1,$^)  -inset $(word 2,$^)
	3dNotes -h "make -C $(PWD) $@" $@

%/Wbgrndkm_func.nii.gz:
	pp 7TBrainMech_rest MHRest_nost_nowarp_nosmooth $(notdir $(@D))

# generic rule to make directories
%/:
	mkdir -p $@
