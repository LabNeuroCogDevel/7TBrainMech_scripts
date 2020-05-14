# MRSIROI R package 
functions used to analyse MRSI ROI 

# Quick install
```R
devtools::install_github('LabNeuroCogDevel/7TBrainMech_scripts/mri/MRSI_roi/mrsi_r')
```

N.B. if you want to edit functions, this is not the best choice. See "Edit and Install"  beloww

# Usage

```R
detach("package:mrsiroi", unload=TRUE) # only if already loaded and need new changes
library(mrsiroi)
d <- read.csv('../../txt/13MP20200207_LCMv2fixidx.csv')
m_glu <- mrsi_bestmodel(d, 1, Glu.Cr, Glu.SD)
fitdf_glu <- mrsi_fitdf(m_glu)

m_gaba <- mrsi_bestmodel(d, 1, GABA.Cr, GABA.SD)
fitdf_gaba <- mrsi_fitdf(m_gaba)

fitdf <- rbind(fitdf_gaba, fitdf_glu)
```

# Edit and install

  1. Fetch the whole repo if it doesn't already exist locally and cd to the package
   ```base
   git clone https://github.com/LabNeuroCogDevel/7TBrainMech_scripts
   cd 7TBrainMech_scripts/mri/MRSI_roi/mrsi_r
   ```

  2.  Then edit and install
   ```R
   devtools::document(); devtools::install('./')
   ```
   or simimply `make` (using [`Makefile`](./Makefile))

# Refs
* https://kbroman.org/pkg_primer/pages/minimal.html
* https://hilaryparker.com/2014/04/29/writing-an-r-package-from-scratch/
* https://cran.r-project.org/web/packages/roxygen2/vignettes/roxygen2.html
