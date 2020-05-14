# MRSIROI R package 
functions used to analyse MRSI ROI 

# Usage

```R
d <- read.csv('../../txt/13MP20200207_LCMv2fixidx.csv')
m_glu <- mrsi_bestmodel(d, 1, Glu.Cr, Glu.SD)
fitdf_glu <- mrsi_fitdf(m_glu)

m_gaba <- mrsi_bestmodel(d, 1, GABA.Cr, GABA.SD)
fitdf_gaba <- mrsi_fitdf(m_gaba)

fitdf <- rbind(fitdf_gaba, fitdf_glu)
```

# Build and install

```R
devtools::document(); devtools::install('./')
```

or simimply `make` (using [`Makefile`](./Makefile))

# Refs
* https://kbroman.org/pkg_primer/pages/minimal.html
* https://hilaryparker.com/2014/04/29/writing-an-r-package-from-scratch/
* https://cran.r-project.org/web/packages/roxygen2/vignettes/roxygen2.html
