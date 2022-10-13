! test -d stats && mkdir $_
IN=(subjs/1*_2*/conn_mrsi_rest/mxcovsph/07-ACC_corr-r.nii.gz)
3dttest++ -overwrite \
   -prefix stats/ttest-AACC_nvis-${#IN[@]}.nii.gz \
   -resid stats/ttest-AACC_nvis-${#IN[@]}_resid.nii.gz \
   -ACF \
   -setA "${IN[@]}"
