#!/usr/bin/env bash
#
# whole brain analysis
#
# 20230518WF - init
#
# shellcheck disable=SC2046,SC2006 # `: ` inline comments
3dLME \
 -prefix lme_age_only.nii.gz \
 -jobs 60 \
 -qVars 'age' \
 -model  'age+sex'      \
 -SS_type 3   `: default? marginal sum of squares`\
 -ranEff '~1' `: default? random effect f.ea. Subj` \
 -dataTable @datatable.tsv \

# matlab code didn't save header correctly
3drefit -xdel 2 -ydel 2 -zdel 2 -xorigin 96 -yorigin 132 -zorigin 78 lme_age_only.nii.gz

# Default (absence of option -qVarsCenters) means centering on the
# average of the variable across ALL subjects regardless their
# grouping

# The simplest and most common
# one is random intercept, "~1", meaning each subject deviates some
# amount (called random effect)

# -model FORMULA: Specify the terms of fixed effects for all explanatory,
#   including quantitative, variables. The expression FORMULA with more
#   than one variable has to be surrounded within (single or double)
#   quotes. Variable names in the formula should be consistent with
#   the ones used in the header of -dataTable. A+B represents the
#   additive effects of A and B, A:B is the interaction between A
#   and B, and A*B = A+B+A:B. Subject should not occur in the model
#   specification here.

# -SS_type NUMBER: Specify the type for sums of squares in the F-statistics.
#  Two options are currently supported: sequential (1) and marginal (3).

