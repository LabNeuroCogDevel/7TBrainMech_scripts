#!/usr/bin/env python
# inspiration from https://github.com/nw-duncan/MRS-voxel-plot/
# 20220324WF - init
#  use nilearn glass brain to visualize slice position
# colors from
# https://matplotlib.org/3.5.1/tutorials/colors/colormaps.html
# glass_brain
# ‘ortho’, ‘x’, ‘y’, ‘z’, ‘xz’, ‘yx’, ‘yz’, ‘l’, ‘r’, ‘lr’, ‘lzr’, ‘lyr’, ‘lzry’, ‘lyrz’. Default=’ortho’.

import os
import sys
import numpy as np
import pandas as pd
import nibabel as ni
import matplotlib.pyplot as plt
from nilearn import plotting, image

# this is also a script for plotting just the rois
import glassbrain_roi

USED_ROIS = [1, 2, 7, 8, 9, 10]


def back_to_nii(orig, newdata):
    assert orig.shape == newdata.shape
    return ni.Nifti1Image(newdata, orig.affine)


def only_keep_rois(nii_or_fname, keep=USED_ROIS):
    "remove unused rois"
    if type(nii_or_fname) == str:
        nii = ni.load(nii_or_fname)
    else:
        nii = nii_or_fname
    d = nii.get_fdata()
    not_roi = np.invert(np.isin(d, keep))
    d[not_roi] = 0
    return back_to_nii(nii, d)


# image concatenated and summarised with afni tools
atlas_slice = ni.load("/opt/ni_tools/slice_warp_gui/slice_atlas.nii.gz")
roi_map = only_keep_rois("roi_locations/ROI_mni_13MP20200207.nii.gz")
all_roi_density_map = ni.load("./all_13MP20200207_cnt.nii.gz")
x = all_roi_density_map.get_fdata() * (roi_map.get_fdata() > 0)
density_map = back_to_nii(all_roi_density_map, x)

dmdata = density_map.get_data()
mx_cnt = np.max(dmdata)

# Plot the figure
fig = plt.figure()
fig.set_size_inches(4, 6)


# Slice
ax_slice = plt.subplot(311)
plotting.plot_glass_brain(atlas_slice, threshold=0, colorbar=False,
                          annotate=False,
                          axes=ax_slice, cmap='hsv', display_mode='x')
#ax_slice.set_title("Ideal Slice Acquisition", loc="left")

# ROI
ax_roi = plt.subplot(312)
plot_rois_as_nifti = False
if plot_rois_as_nifti:
    plotting.plot_glass_brain(roi_map, threshold=0, colorbar=False,
                            annotate=False, 
                            axes=ax_roi, cmap='tab20', display_mode='xz')
    #ax_roi.set_title("ROIs", loc="left")

else: ## or plot with actual xyz coords
    centers_ras = glassbrain_roi.read_coords()
    glassbrain_roi.plot_rois(ax_roi, roi_idxs=USED_ROIS, display_mode='xz')
    #n_roi = len(centers_ras)
    #adjmat0 = np.zeros((n_roi, n_roi))
    #colors =  plt.cm.get_cmap('tab20').colors[0:n_roi]
    #plotting.plot_connectome(adjacency_matrix=adjmat0, node_coords=centers_ras,
    #                         annotate=False,
    #                         node_size=50, node_color=colors, display_mode='xz',alpha=.5,
    #                         axes=ax_roi)

# coverage
ax_cvg = plt.subplot(313)
plotting.plot_glass_brain(density_map, threshold=0, colorbar=False, annotate=False,
                          axes=ax_cvg, cmap='autumn', display_mode='xz')

#fig.colorbar(dmdata.data, ax=ax_cvg, location='top', orientation='horizontal', ticks=(0, mx_cnt))
# originally set percent to 1
#from matplotlib import ticker
#ax1.yaxis.set_major_formatter(ticker.PercentFormatter(mx_cnt))
#ax_cvg.set_title("MNI ROI within slice coverage", loc="left")

# display. save if not running interactively
if hasattr(sys, 'ps1'):
    plt.show()
else:
    plt.savefig("img/slice_figure_notitle.png")

# Local Variables:
# python-shell-interpreter: "ipython3"
# python-shell-interpreter-args: "-i --simple-prompt --InteractiveShell.display_page=True"
# End:
