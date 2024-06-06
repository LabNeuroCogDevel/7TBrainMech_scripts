#!/usr/bin/env python3
"""
DFA for schaefer atlas based on xcp_d/fmriprep surface (cifti) output
code based on hurst_nolds.py. also see xcpd_surface_hurst.m for maltab hurst 

20240605WF - init
"""
import nolds
import numpy as np
import multiprocessing
from typing import List, Tuple
from functools import partial
import re
import pandas as pd
import itertools
from glob import glob
import nibabel as nib

#from neuromaps.datasets import fetch_atlas
#fslr = fetch_atlas('fsLR', '32k')
#nib.load(fslr['medial'].L).agg_data()

NCORE=50

def match_or_na(instr: str, pat) -> str:
    "Wrap bad match to return NA if None"
    match = re.search(pat, instr)
    if match is None:
        return "NA"
    return match[0]

def show_cifti_lr_info(cifti):
    structs = cifti.header.get_index_map(1).brain_models
    keep_struct = ['CIFTI_STRUCTURE_CORTEX_LEFT', 'CIFTI_STRUCTURE_CORTEX_RIGHT']
    kept_meta =[f for f in structs if f.brain_structure in keep_struct]
    print("; ".join([f"{f.brain_structure}={f.index_offset}:{f.index_offset + f.index_count}/{f.surface_number_of_vertices}"
           for f in kept_meta]))

def load_cortex_only(fname):
    """ subset cifti to just left and right cortex
    fslr32k = 64984  combined left and right
    """
    cifti = nib.load(fname)
    show_cifti_lr_info(cifti)
    cortex_idx = {name: (idx,model)
                  for name,idx, model in cifti.header.get_axis(1).iter_structures()
                  if re.search('CIFTI_STRUCTURE_CORTEX', name)} 
    data = cifti.get_fdata() # ts.shape == (220, 91282)

    # https://neurostars.org/t/separate-cifti-by-structure-in-python/17301/2
    surf_data = {}
    for hemi, (idx, model) in cortex_idx.items():
        hemi_data = data.T[idx] 
        surf_data[hemi] = np.zeros((model.vertex.max() + 1,) + hemi_data.shape[1:], dtype=data.dtype)
        surf_data[hemi][model.vertex] = hemi_data

    # slow. consider np.stack?
    left_right = np.concatenate([surf_data['CIFTI_STRUCTURE_CORTEX_LEFT'],
                                 surf_data['CIFTI_STRUCTURE_CORTEX_RIGHT']])

    assert left_right.shape[0] == 64984
    return left_right



def show_struct_info():
    for fname in ['/opt/ni_tools/atlas/schaefer2018/Schaefer2018_LocalGlobal/Parcellations/HCP/fslr32k/cifti/Schaefer2018_200Parcels_17Networks_order.dlabel.nii',
'/Volumes/Hera/Projects/7TBrainMech/scripts/mri/xcpd/ses-1/sub-10173/func/sub-10173_task-rest_run-01_space-fsLR_den-91k_desc-denoised_bold.dtseries.nii' ]:
        cifti = nib.load(fname)
        # {'CIFTI_STRUCTURE_CORTEX_LEFT': 32492, 'CIFTI_STRUCTURE_CORTEX_RIGHT': 32492}
        structs = cifti.header.get_index_map(1).brain_models

        print(fname, end="\n ");
        print(cifti.header.get_axis(1).nvertices,end="\n\t")
        print("\n\t".join([f"{f.brain_structure}={f.index_offset}:{f.index_offset + f.index_count} ({f.index_count},{f.surface_number_of_vertices})" for f in structs]))
        print("\tsum indexes:",sum([f.index_count for f in structs])) # 91282
        print("\traw data size:", cifti.get_fdata().shape)


def per_vertex(scalar_fname, func):
    """vertex mean time course"""
    raise Exception("unimplemented")

    ts = load_cortex_only(scalar_fname)
    vertex_res = [func(ts[:,i]) for i in range(n_roi)]
    return vertex_res


def per_roi(scalar_fname, roi_indexes, func):
    """hurst of roi mean time course"""
    ts = load_cortex_only(scalar_fname)
    dfa_roits = [func(np.mean(ts[cortex_idx,:],axis=0))
                  for roi_num, cortex_idx in roi_indexes]
    return dfa_roits



def glob_func(ts_filepatt, func=nolds.dfa, idpatt=r'ses-[1-3]/sub-\d{5}'):
    ts1d=glob(ts_filepatt)
    ld8 = [match_or_na(x,idpatt) for x in ts1d]
    print(f"# have {len(ts1d)} files like {ts_filepatt}. running {func.__name__}")
    roi_indexes = read_schaefer()
    pool = multiprocessing.Pool(processes=NCORE)
    #def myfunc(fname):
    #    per_roi(fname, roi_indexes=roi_indexes, func=func)
     
    dfa_roits = pool.map(partial(per_roi, roi_indexes=roi_indexes, func=func), ts1d)
    
    df = pd.DataFrame(dfa_roits)
    print(f"#   dataframe is {df.shape}.")
    # TODO: better schaefer labels
    df.columns = [f"roi_{i}" for i,_ in roi_indexes]
    
    # luna+8digit yyyymmdd visit date/session id
    df.insert(0, 'luna_ses', ld8)
    return df


def read_schaefer() -> List[Tuple[int, List[bool]]]:
    """
    read shaefer mask and return list of tuple (roi, [bool])
    """
    schaefer_atlas_file = '/opt/ni_tools/atlas/schaefer2018/Schaefer2018_LocalGlobal/Parcellations/HCP/fslr32k/cifti/Schaefer2018_200Parcels_17Networks_order.dlabel.nii';
    atlas = load_cortex_only(schaefer_atlas_file) 
    schaefer_rois = np.unique(atlas[atlas !=0]); # 1:200
    assert len(schaefer_rois) == 200

    roi_indexes = [(int(i), np.squeeze(atlas == i)) for i in schaefer_rois]
    assert roi_indexes[0][1].shape[0] == 64984
    assert roi_indexes[1][1].shape[0] == 64984
    
    return roi_indexes

if __name__ == "__main__":
    surf_patt = '/Volumes/Hera/Projects/7TBrainMech/scripts/mri/xcpd/ses-*/sub-1*/func/sub-1*_task-rest_run-01_space-fsLR_den-91k_desc-denoised_bold.dtseries.nii'
    roi_df = glob_func(surf_patt)
    roi_df.to_csv("txt/schaefer200_17N_surface-tsavg-pydfa.csv", quoting=False, index=False)
