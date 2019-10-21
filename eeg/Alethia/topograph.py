#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
plot topographic of eeg data
"""

import numpy as np
import matplotlib.pyplot as plt
import mne

# see homebatchLast.m -- not used
event_id = {
        'ITI':      1,
        'Cue':      2,
        'DotL_n3': -3,
        'DotR_p3':  3,
        'Delay':    4,
        'MVSL_n5': -5,
        'MVSR_p5':  5}

# pull up a participant
setfile = 'Prep/AfterWhole/epochcleanTF/11770_20190806_MGS_Rem_rerefwhole_ICA_icapru_epochs_rj.set'
# in matlab code, cap is:
# /plugins/dipfit2.3/standard_BESA/standard-10-5-cap385.elp
cap = '/opt/ni_tools/matlab_toolboxes/eeglab/plugins/dipfit2.3/standard_BESA/standard-10-5-cap385.elp'
epochs = mne.io.read_epochs_eeglab(setfile, montage=cap)

# set Interactive ON -- plot more than one thing at a time
plt.ion()
# these are the same. doing something wrong?
topo_all = epochs.plot_psd_topomap()
topo_MVSL = epochs['-5'].plot_psd_topomap()
