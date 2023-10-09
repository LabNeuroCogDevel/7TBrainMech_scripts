#!/usr/bin/env python3
# inspiration from https://github.com/nw-duncan/MRS-voxel-plot/
# 20220324WF - init
#  use nilearn glass brain to visualize slice position
# colors from
# https://matplotlib.org/3.5.1/tutorials/colors/colormaps.html
# glass_brain
# 'ortho', 'x', 'y', 'z', 'xz', 'yx', 'yz', 'l', 'r', 'lr', 'lzr', 'lyr', 'lzry', 'lyrz'.

import sys
import numpy as np
import matplotlib.pyplot as plt
import argparse
import warnings
warnings.simplefilter("ignore")
import pandas as pd
from nilearn import plotting


def read_coords(fname='roi_locations/labels_13MP20200207.txt'):
    labels = pd.read_csv(fname, sep="\t", header=None)
    # convert from LPI to "RAS+"
    centers = [[float(y) for y in x.split(" ")] for x in labels.iloc[:, 1]]
    # LPI to RAS+
    centers_ras = [(c[0], -1*c[1], c[2]) for c in centers]
    return centers_ras


def roi_colors(n_roi=13):
    "here incase we want to change what roi gets what color"
    return plt.cm.get_cmap('tab20').colors[0:n_roi]


def plot_rois(ax_roi, roi_idxs=[1, 2, 7, 8, 9, 10], display_mode='xz'):
    centers_ras = read_coords()
    colors = roi_colors(len(centers_ras))  # same colors despite subselect
    used_rois0 = [i-1 for i in roi_idxs]
    colors_used = [colors[i] for i in used_rois0]
    centers_used = [centers_ras[i] for i in used_rois0]
    # no lines between rois
    n_roi = len(centers_used)
    adjmat0 = np.zeros((n_roi, n_roi))
    plotting.plot_connectome(adjacency_matrix=adjmat0,
                             node_coords=centers_used,
                             annotate=False,
                             node_size=50, node_color=colors_used,
                             display_mode=display_mode, alpha=.5,
                             axes=ax_roi)


def main(args):
    "args display_mode save idx width height"
    # Plot the figure
    fig = plt.figure()
    fig.set_size_inches(args.width, args.height)
    ax_roi = plt.subplot(111)
    plot_rois(ax_roi, args.idx, args.display_mode)
    # display. save if not running interactively
    if hasattr(sys, 'ps1') or not args.save:
        plt.show()
    else:
        plt.savefig(args.save)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='')
    # USED_ROIS = [1, 2, 7, 8, 9, 10]
    parser.add_argument('idx', metavar='index', type=int, nargs='+',
                        help='1-based ROI indexes. probably want 1 2 7 8 9 10')
    parser.add_argument('--save', metavar='save',
                        help='save as', type=str, default=None)
    parser.add_argument('--width', type=float,
                        dest='width',
                        default=4,
                        help="image width")
    parser.add_argument('--height', type=float,
                        dest='height',
                        default=2,
                        help="image height")
    parser.add_argument('--display',  type=str,
                        dest='display_mode',
                        default='xz',
                        help="'ortho', 'x', 'y', 'z', 'xz', 'yx', 'yz', 'l', 'r', 'lr', 'lzr', 'lyr', 'lzry', 'lyrz'.")

    args = parser.parse_args()
    print(args)
    main(args)

# Local Variables:
# python-shell-interpreter: "ipython3"
# python-shell-interpreter-args: "-i --simple-prompt --InteractiveShell.display_page=True"
# End:
