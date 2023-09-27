#!/usr/bin/env python3
# nolds dfa into  'txt/nolds_dfa.csv'
# 20230926WF - init (MP<-JH<-DL)

# nolds suggested from MP via JH via Dan Luri
# >  two methods for calculating the Hurst *things*:
# >    rescaled range (nolds.hurst_rs) and DFA (nolds.dfa).
# > I have not used this package myself, but it seems to have excellent documentation,
# > which is always a good sign.
# >
# > ·  Technically speaking, only R/S produces the Hurst *exponent*. DFA produces a Hurst *parameter*. The nolds documentation has a good explanation of the differences in how each is calculated, if you’re interested.
# > ·  The important difference in practice is that DFA is robust to nonstationary data, but R/S is not.
# >
# > In my experience, R/S and DFA seem to behave at least somewhat differently for resting BOLD data,
# > but I haven’t done a formal comparison.
# > It might be worth including both in our analyses just to see if anything interesting shows up,
# > even if we only include DFA in the paper. 
# > To dig into more about that, he also said:
# >     I would recommend to use detrended fluctuation analysis (DFA) to estimate the Hurst exponent,
# >      as it is robust to non-stationarities which may be present in BOLD data.
# >      There is some evidence that DFA may also be more robust in the presence of multi-fractal scaling
# >      (i.e. the presence of more than one scaling law across timescales),
# >      which has previously been found in fMRI data (and which I see in my own work).
# >      See this paper for an example of how Hurst exponent is calculated using DFA,
# >      as well as a brief discussion of
# >       'Core and matrix thalamic sub-populations relate to spatio-temporal cortical connectivity gradients'
# >       https://www.sciencedirect.com/science/article/pii/S1053811920307102?via%3Dihub
# also "Sex classification using long-range temporal dependence of resting-state functional MRI time series"
#  https://onlinelibrary.wiley.com/doi/full/10.1002/hbm.25030


import nolds
import numpy as np
import multiprocessing
import re
import pandas as pd
from glob import glob

def dfa_roits(roi_fname):
    ts = np.loadtxt(roi_fname)
    n_roi = ts.shape[1]
    x = [nolds.dfa(ts[:,i]) for i in range(n_roi)]
    return x

ts1d = glob('/Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_nowarp/*/mrsipfc13_nzmean_ts.1D');

# run all all cores of rhea
# this is relatively fast and there are only ~220 files
pool = multiprocessing.Pool(processes=72)
dfa_all_ts = pool.map(dfa_roits, ts1d)

dfa_df = pd.DataFrame(dfa_all_ts)

# more useful roi names are in the original label file
# use those to avoid losing track of indexes
roi_labels =pd.read_table('../MRSI_roi/roi_locations/labels_13MP20200207.txt', sep=':', names=['roi','cord'])
dfa_df.columns = [re.sub(' ','_',roi) for roi in roi_labels.roi]

# luna+8digit yyyymmdd visit date/session id
ld8 = [re.search('\d{5}_\d{8}',x)[0] for x in ts1d]
dfa_df.insert(0, 'ld8', ld8)

dfa_df.to_csv('txt/nolds_dfa.csv', quoting=False, index=False)
