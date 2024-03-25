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

REDO = False # if not redo, will read from hurst output nifitis when they exist
MAXJOBS = 50 # how many visits to run at a time

def hurst_on_mask_func(nii_fname, mask: nib.nifti1.Nifti1Image, func):
    """ calc husrt/dfa on input nifti using mask
    SIDEEFFECT: saves nifti output"""
    ld8matches = re.search('\d{5}_\d{8}', nii_fname)
    prefix     = re.search('[brna]*swdkm', nii_fname)
    if not ld8matches:
        raise Exception(f"no ld8 in nifti filenae '{nii_fname}'")
    if not prefix:
        raise Exception(f"unknown prefix in '{nii_fname}'")

    ld8 = ld8matches[0] 
    prefix = prefix[0] 
    outname=f"hurst_nii/{ld8}/py_dencrct_{prefix}_{func.__name__}.nii.gz"
    # TODO: read if already exists?
    if os.path.isfile(outname) and not REDO:
        print(f"# reading {outname}")
        return nib.load(outname).dataobj[:]

    print(f"# writting {outname}")
    nii = nib.load(nii_fname)
    masked_out4d = np.broadcast_to(mask.dataobj[...,None]<.5,nii.shape)
    ts_masked = np.ma.array(nii.dataobj[:], mask=masked_out4d)
    res = np.apply_along_axis(func, 3, ts_masked)
    #mask.data = res
    res = nib.Nifti1Image(res, mask.affine, mask.header)
    nib.save(res, outname)
    return res

def glob_func(ts_filepatt: str, mask: nib.nifti1.Nifti1Image, func=nolds.dfa):
    """
    open a parallel pool to use for each timeseries
    wraps hurst_on_mask_func (which saves out individual files)
    also writes out the mean of all hurst outputs
    """
    files=glob(ts_filepatt)
    pool = multiprocessing.Pool(processes=MAXJOBS)
    # partial function with which hurst func and gm mask setup
    hurst_func = partial(hurst_on_mask_func, mask=mask, func=func)
    all_ts = pool.map(hurst_func, files)
    print(f"all_ts len: {len(all_ts)} (type {type(all_ts)}")
    try:
        all_ts = np.mean(np.concatenate(all_ts))
        res = nib.Nifti1Image(all_ts, mask.affine, mask.header)
        return res
    except Exception as e:
        print(e)
        return None
    #outname=f"hurst_nii/py_{func.__name__}.nii.gz"
    #nib.write_nii(res, outname)
    
    


def run_all():

    subject_glob = '/Volumes/Hera/preproc/7TBrainMechDenCrct_rest/MHRest_nost_ica/1*_2*/'
    gm_mask_fname = '/opt/ni_tools/standard/mni_icbm152_nlin_asym_09c/mni_icbm152_gm_tal_nlin_asym_09c_2mm.nii'
    mask = nib.load(gm_mask_fname)

    for func in [nolds.dfa]: # nolds.hurst_rs,
        funcname=re.sub('.*\\.','',func.__name__)
        for prefix in ['brnaswdkm']: #, 'swdkm']:

            outname = f'stats/{prefix}_dencrt_{funcname}.nii.gz'
            in_glob=f'{subject_glob}/{prefix}_func_4.nii.gz'

            print(f"making {outname} with {in_glob}")
            out_data = glob_func(in_glob, mask, func)
            nib.save(out_data, outname)

if __name__ == "__main__":
    run_all()
