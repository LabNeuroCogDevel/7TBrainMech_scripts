Authors: Will Foran mostly and a little bit Maria Perica
# MRSIROI R package
functions used to analyse MRSI ROI

# Quick install
```R
devtools::install_github('LabNeuroCogDevel/7TBrainMech_scripts/mri/MRSI_roi/mrsi_r')
```

N.B. if you want to edit functions, this is not the best choice. See "Edit and Install"  below

# Usage

```R
## get newer version
setwd("mri/MRSI_roi/mrsi_r")           # or whereever this folder is
system("git pull")                     # get updates
devtools::install("./")                # install 
# or in bash: git pull && make
detach("package:mrsiroi", unload=TRUE) # remove old package

## using
library(mrsiroi)
d <- read.csv('../../txt/13MP20200207_LCMv2fixidx.csv')

## all in one plot function
p <- mrsi_plot_many(d, 1, list(Glu.Cr='Glu.SD', GABA.Cr="GABA.SD"))
print(p)

## step by step
glu_r1     <- mrsi_clean(d, 1, 'Glu.SD')
glu_r1_m   <- mrsi_bestmodel(glu_r1, 'Glu.Cr')
glu_r1_fit <- mrsi_fitdf(glu_r1_m)

```

# Edit and install

  1. Fetch the whole repo if it doesn't already exist locally and cd to the package
   ```base
   git clone https://github.com/LabNeuroCogDevel/7TBrainMech_scripts
   cd 7TBrainMech_scripts/mri/MRSI_roi/mrsi_r
   ```

  2.  Then edit and (re)install (in `R`)
   ```R
   devtools::document(); devtools::install('./')
   ```
   or simimply `make` from the shell (using [`Makefile`](./Makefile))

  3. Push back changes
   ```bash
    git commit -am '✨ my changes' # consider taging message with an emoji: https://gitmoji.carloscuesta.me/
    git pull # incase any changes were made by anyone else
    git push
   ```

# Testing

  * make a new testfile in R with e.g. `usethis::use_test("mrsi_newthing")`

# Refs

  * https://kbroman.org/pkg\_primer/pages/minimal.html
  * https://hilaryparker.com/2014/04/29/writing-an-r-package-from-scratch/
  * https://cran.r-project.org/web/packages/roxygen2/vignettes/roxygen2.html
  * https://testthat.r-lib.org/
