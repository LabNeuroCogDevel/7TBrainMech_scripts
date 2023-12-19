#!/usr/bin/env python3
"""
read adjusted b1 raw float files from matlab
match the dicom header of it's pair (downsampling affine matrix tofit)
and resample to mp2rage after finding it

20231219WF - rewrite w/more functions
"""
import nibabel as nib
import numpy as np
from glob import glob
import os
import re
from medio import read_img, save_img, MetaData


class ErrorB1(Exception):
    """Our very own error class for unexpect or missing files
    Caught and pass on to 'return (success,message)' pattern"""

    pass


# MRID -> ld8 lookup. global variable populated by DB query
LOOKUP = {}


def clean_mrid(mrid):
    "extract just the date and visit number"
    # return re.sub('(Luna\d).*','\\1', mrid)
    return re.sub(".*(\d{8}Luna\d).*", "\\1", mrid)


querycmd = """PAGER=cat lncddb "select luna.id, mr.id from enroll as luna join enroll as mr on mr.pid=luna.pid and luna.etype like 'LunaID' and mr.etype like '7TMRID'" """
queryres = os.popen(querycmd).read().split("\n")
for l in queryres:
    if not "\t" in l:
        continue
    id, mrid = l.strip().split("\t")
    ld8 = id + "_" + re.sub("L.*", "", mrid)
    LOOKUP[mrid] = ld8


def find_id(path):
    mrid = clean_mrid(path)
    return LOOKUP.get(mrid)


def find_ld8_mp2rage(ld8):
    """
    /Volumes/Hera/Raw/BIDS/7TBrainMech/sub-11651/20190222/anat/sub-11651_T1w.nii.gz
    """
    id, vdate = ld8.split("_")
    bidsroot = "/Volumes/Hera/Raw/BIDS/7TBrainMech/"
    mp2rage = os.path.join(
        bidsroot, "sub-" + id, vdate, "anat", "sub-" + id + "_T1w.nii.gz"
    )
    # useful to have for error message
    # if not os.path.isfile(mp2rage):
    #    mp2rage = None
    return mp2rage


def seq_num_end(fname):
    return int(re.sub(".*\.", "", fname))


def b1_read(base):
    """read raw float output of matlab
    NB. each 2D slice needs to be flipped:
        left right and up down
        and need to make sure we're reading each file (z)
        by seqnum sort, not filename (num 1,2,10 vs word 1,10,2)
    """
    bmap_mats = glob(base + "/B1.1.*")
    # sort by last digit
    bmap_mats = sorted(bmap_mats, key=seq_num_end)
    # example = np.fromfile(bmap_mats[0], "<f")
    # n = int(np.sqrt(example.size))
    n = 64
    x = np.zeros((n, n, len(bmap_mats)))  # (64,64,11)
    for i, bfile in enumerate(bmap_mats):
        x[:, :, i] = np.flipud(np.fliplr(np.fromfile(bfile, "<f").reshape(n, n)))
    return x


def adjust_dcm_header(base, n):
    """
    base - b1maphomog directory
    n - height (== width) of Matlab matrix (n=64)

    we use dicom metadata to match an aligment to mp2rage
    not sure how to do this without the reference dicom image

    dcm_metadata.spacing (calculated from affine) was
    [ 1.6875, 1.6875, 12.], becomes
    [ 3.375,  3.375 , 12.]
    """
    all_dcm = glob(base + "/*IMA")
    if len(all_dcm) != 11:
        raise ErrorB1(f"unepxected number of dcm files ({len(all_dcm)}!=11) in {base}")
    dcm_array, dcm_metadata = read_img(base)
    scale = dcm_array.shape[0] / n  # 2

    dcm_metadata.affine[0, 0] *= scale
    dcm_metadata.affine[1, 1] *= scale
    return dcm_metadata


def mp2rage_with_errors(base, ld8):
    mp2rage = glob(base + "/../registration_out/*MP2R*nii")
    if len(mp2rage) > 0:
        return mp2rage[0]
    if ld8 is None:
        raise ErrorB1(f"no id for {base}")
    mp2rage = find_ld8_mp2rage(ld8)
    if mp2rage is None or not os.path.isfile(mp2rage):
        raise ErrorB1(f"{ld8} has no mp2rage {mp2rage} ({base})")
    return mp2rage


def b1recon(base):
    out_small = base + "/b1-pyrecon.nii.gz"
    out_res = base + "/b1-pyrecon_res-mp2rage.nii.gz"
    if os.path.isfile(out_res):
        return (True, out_res)

    x = b1_read(base)
    n = x.shape[0]
    assert n == x.shape[1]  # square

    if x.shape[2] != 11:
        msg = f"ERROR: unexpected number of mat files ({x.shape[2]}) in {base}"
        return (False, msg)

    ld8 = find_id(base)
    try:
        mp2rage = mp2rage_with_errors(base, ld8)
        dcm_metadata = adjust_dcm_header(base, n)
    except ErrorB1 as e:
        return (False, str(e))

    save_img(out_small, x, dcm_metadata, backend="nib")
    os.system(f'3dNotes -h "{__file__} {base} {mp2rage} {ld8}" "{out_small}"')

    os.system(
        f'3dresample -inset "{out_small}" -master "{mp2rage}" -prefix "{out_res}"'
    )
    return (True, out_res)


if __name__ == "__main__":
    b1 = glob("/Volumes/Hera/Raw/MRprojects/7TBrainMech/*/S*/B1MapHomog/B1.1.0.1.1.1")
    res = [b1recon(os.path.dirname(b)) for b in b1]
    print("\n".join([r[1] for r in res if not r[0]]))
