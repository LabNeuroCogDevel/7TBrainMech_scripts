import nibabel as nib
import numpy as np

nroi = 13
roits = nib.load('all_13MP20200207.nii.gz')
roits_mat = roits.get_fdata()
dim = roits_mat.shape # == (97, 115, 97, 269)
outmat = np.zeros(list(dim[0:3]) + [nroi])
for roi in range(nroi):
    outmat[:,:,:,roi] = np.sum(roits_mat == roi+1, axis=-1)

roi_sums = nib.Nifti1Image(outmat, roits.affine, roits.header)
nib.save(roi_sums,'13MP20200207_cnt_vol-per-roi.nii.gz')
