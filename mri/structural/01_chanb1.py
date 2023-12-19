#!/usr/bin/env python3
import nibabel as nib
import numpy as np
from glob import glob
import os
import re
from medio import read_img, save_img, MetaData

LOOKUP = {}


def clean_mrid(mrid):
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


def find_mp2rage(ld8):
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


def b1recon(base):
    bmap_mats = glob(base + "/B1.1.*")

    out_small = base + "/b1-pyrecon.nii.gz"
    out_res = base + "/b1-pyrecon_res-mp2rage.nii.gz"
    if os.path.isfile(out_res):
        return (True, out_res)

    if len(bmap_mats) != 11:
        msg = f"ERROR: unexpected number of mat files ({len(bmap_mats)}) in {base}"
        return (False, msg)

    ld8 = find_id(base)
    mp2rage = glob(base + "/../registration_out/*MP2R*nii")
    if len(mp2rage) > 0:
        mp2rage = mp2rage[0]
    else:
        if ld8 is None:
            msg = f"ERROR: no id for {base}"
            return (False, msg)
        mp2rage = find_mp2rage(ld8)
        if mp2rage is None or not os.path.isfile(mp2rage):
            msg = f"ERROR: {ld8} has no mp2rage {mp2rage} ({base})"
            return (False, msg)

    # sort by last digit
    bmap_mats = sorted(bmap_mats, key=lambda key: int(re.sub(".*\.", "", key)))
    # example = np.fromfile(bmap_mats[0], "<f")
    # n = int(np.sqrt(example.size))
    n = 64

    # we use dicom metadata to match an aligment to mp2rage
    # not sure how to do this without the reference dicom image
    all_dcm = glob(base + "/*IMA")
    if len(all_dcm) != 11:
        msg = f"ERROR: unepxected number of dcm files ({len(all_dcm)}!=11) in {base}"
        return (False, msg)
    dcm_array, dcm_metadata = read_img(base)
    scale = dcm_array.shape[0] / n  # 2

    x = np.zeros((n, n, len(bmap_mats)))  # (64,64,11)
    for i, bfile in enumerate(bmap_mats):
        x[:, :, i] = np.flipud(np.fliplr(np.fromfile(bfile, "<f").reshape(n, n)))

    dcm_metadata.affine[0, 0] *= scale
    dcm_metadata.affine[1, 1] *= scale
    # dcm_metadata.spacing (calculated from affine) was
    # [ 1.6875, 1.6875, 12.], becomes
    # [ 3.375,  3.375 , 12.]
    save_img(out_small, x, dcm_metadata, backend="nib")
    os.system(f'3dNotes -h "{__file__} {base} {mp2rage} {ld8}" "{out_small}"')

    os.system(
        f'3dresample -inset "{out_small}" -master "{mp2rage}" -prefix "{out_res}"'
    )
    return (True, out_res)


b1 = glob("/Volumes/Hera/Raw/MRprojects/7TBrainMech/*/S*/B1MapHomog/B1.1.0.1.1.1")

res = [b1recon(os.path.dirname(b)) for b in b1]
print("\n".join([r[1] for r in res if not r[0]]))
