#!/usr/bin/env python3

import nolds
import numpy as np
import nibabel as nib
import multiprocessing
from functools import partial
import re
import pandas as pd
import os
from glob import glob

def nii_mask_func(nii_fname, mask, func=nolds.dfa):
    """ calc husrt/dfa on input nifti using mask"""
    ld8 = re.search('\d{5}_\d{8}', nii_fname)[0] 
    outname=f"hurst_nii/{ld8}/py_dencrct_{func.__name__}.nii.gz"
    print(f"# writting {outname}")
    # TODO: read if already exists?
    if os.path.isfile(outname):
        return nib.load(outname).dataobj[:]

    nii = nib.load(nii_fname)
    masked_out4d = np.broadcast_to(mask.dataobj[...,None]<.5,nii.shape)
    ts_masked = np.ma.array(nii.dataobj[:], mask=masked_out4d)
    res = np.apply_along_axis(func, 3, ts_masked)
    mask.data = res
    nib.save(mask, outname)
    return res

def glob_func(ts_filepatt, mask, func=nolds.dfa):
    files=glob(ts_filepatt)
    pool = multiprocessing.Pool(processes=20)
    all_ts = pool.map(partial(nii_mask_func, mask=mask, func=func), files)
    mask.data = np.mean(all_ts)
    return mask
    #outname=f"hurst_nii/py_{func.__name__}.nii.gz"
    #nib.write_nii(mask, outname)
    
    


def run_all():

    subject_glob = '/Volumes/Hera/preproc/7TBrainMechDenCrct_rest/MHRest_nost_ica/1*_2*/'
    gm_mask_fname = '/opt/ni_tools/standard/mni_icbm152_nlin_asym_09c/mni_icbm152_gm_tal_nlin_asym_09c_2mm.nii'
    mask = nib.load(gm_mask_fname)

    for func in [nolds.hurst_rs,nolds.dfa]:
        funcname=re.sub('.*\\.','',func.__name__)
        for prefix in ['brnaswdkm', 'swdkm']:

            outname = f'stats/{prefix}_dencrt_{funcname}.nii.gz'
            in_glob=f'{subject_glob}/{prefix}_func_4.nii.gz'

            print(f"making {outname} with {in_glob}")
            out_data = glob_func(in_glob, mask, func)
            nib.save(out_data, outname)

if __name__ == "__main__":
    run_all()
