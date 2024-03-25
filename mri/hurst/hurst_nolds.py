#!/usr/bin/env python3
# nolds dfa into  'txt/nolds_dfa.csv'
# 20230926WF - init (MP<-JH<-DL)
# 20240324WF - use 02_roimean_hurst.bash via Makfile instead! 
#              this file imported by hurst_1d.py and used by 02_roimean_hurst.bash
#              but files saved by run_all() are obsolute

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


# NB 20231002FC - variable TR could be a problem. dfa: make this seconds instead of nTRs
# /home/ni_tools/python/userbase/lib/python3.11/site-packages/nolds/measures.py
# poly = poly_fit(np.log(nvals), np.log(fluctuations), 1, fit=fit_exp)

import nolds
import numpy as np
import multiprocessing
from functools import partial
import re
import pandas as pd
from glob import glob

def roits_perroi_measure(roi_fname, func):
    """roi mean time course (averaging/smoothing within roi may change high freq props) """
    ts = np.loadtxt(roi_fname)

    # single column input needs to be forced to matrix
    if len(ts.shape)==1:
        ts = np.reshape(ts,(ts.shape[0],1))

    n_roi = ts.shape[1]
    x = [func(ts[:,i]) for i in range(n_roi)]
    return x

def match_or_na(instr: str, pat):
    "Wrap bad match to return NA if None"
    match = re.search(pat, instr)
    if match is None:
        return "NA"
    return match[0]

def glob_func(ts_filepatt, roi_labels, func, idpatt=r'\d{5}_\d{8}'):
    ts1d=glob(ts_filepatt)
    print(f"# have {len(ts1d)} files like {ts_filepatt}. running {func.__name__}")
    pool = multiprocessing.Pool(processes=72)
    all_ts = pool.map(partial(roits_perroi_measure, func=func), ts1d)
    
    df = pd.DataFrame(all_ts)
    print(f"#   dataframe is {df.shape}.")
    
    # more useful roi names are in the original label file
    # use those to avoid losing track of indexes
    if roi_labels is not None:
        print(f"#   setting {len(roi_labels)} labels to columnnames: {', '.join(roi_labels)}")
        df.columns = roi_labels
    
    # luna+8digit yyyymmdd visit date/session id
    ld8 = [match_or_na(x,idpatt) for x in ts1d]
    df.insert(0, 'ld8', ld8)
    return df


def run_all():
    label_file = '../MRSI_roi/roi_locations/labels_13MP20200207.txt'
    roi_labels_df =pd.read_table(label_file, sep=':', names=['roi','cord'])
    roi_labels = [re.sub(' ','',roi) for roi in roi_labels_df.roi]

    print(f"# running hurst and dfa for rois {label_file}")
    for func in [nolds.hurst_rs,nolds.dfa]:
        funcname=re.sub('.*\\.','',func.__name__)
        for prefix in ['nsdkm','brnsdkm', 'nswdkm']:
            if prefix=='brnsdkm':
                in_prefix=''
            else:
                in_prefix=f'_{prefix}'

            # warp files are in different preproc directory
            # /Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost/11868_20211025/mrsipfc13_nzmean_nswdkm_ts.1D
            if prefix=='nswdkm':
                subject_glob = '/Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost/1*_2*/'
            else:
                subject_glob='/Volumes/Hera/preproc/7TBrainMech_rest/MHRest_nost_nowarp/*/'

            # eg.
            # stats/MRSI_pfc13_brnsdkm_hurst_rs.csv
            # stats/MRSI_pfc13_brnsdkm_dfa.csv
            outname = f'stats/MRSI_pfc13_{prefix}_{funcname}.csv'
            in_glob=f'{subject_glob}/mrsipfc13_nzmean{in_prefix}_ts.1D'

            print(f"making {outname}")
            glob_func(in_glob, roi_labels, func).\
              to_csv(outname, quoting=False, index=False)

if __name__ == "__main__":
    run_all()
