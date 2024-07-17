#!/usr/bin/env python3
# from
from glob import glob
import mne
import re
import numpy as np
import matplotlib.pyplot as plt

def avg_psd(bdf_fname):
    print(bdf_fname)
    raw = mne.io.read_raw_bdf(bdf_fname)
    psd = raw.compute_psd()
    # subset of channels (starting iwth C or F)
    # used to reduce count for demonstration. not pricipled
    demo_ch = [x for x in psd.ch_names if re.search('^[CF]',x)]
    x = psd.pick(demo_ch).get_data()
    # uV^2/Hz (dB): 12+ instead of np.log10(x*10**12). save a few thousand calculations
    avg_psd = 10*(12+np.log10(np.mean(x,axis=0)))
    return avg_psd

all_files = glob('/Volumes/Hera/Raw/EEG/7TBrainMech/1*_2*/*_mgs.bdf')
ld8=[re.search("\d{5}_\d{8}",x).group() for x in all_files]
# running for all. but only use 2018+2023
all_avg_psd = [avg_psd(fname) for fname in all_files]


# switched Mar-May 2022.
# Look random 12 (sorted by lunaid) from 2018 vs 2023
a = np.stack(all_avg_psd)
def year_mean(year):
    #globals: 'ld8', 'a'
    # find ld8s that have this year
    idx = np.where([x[6:10] == year for x in ld8])[0].tolist()
    # truncate so same number of visits in each year
    idx_12 = idx[0:12]
    return np.mean(a[idx_12,:], axis=0)

# hacky way to get freqs for plot
psd_ex = mne.io.read_raw_bdf(all_files[0]).compute_psd()

plt.plot(psd_ex.freqs, year_mean("2023"),label='loef no sheild (2023)')
plt.plot(psd_ex.freqs, year_mean("2018"),label='WPH faraday cage (2018)')
plt.legend()
plt.title("PSD before and after EEG move")
plt.xlabel("freq")
plt.ylabel("dB (uV^2/Hz)")
plt.savefig("images/psd_before_after.png")



#### confirm we're plotting uV/Hz correctly
#psd.pick('C6').plot()
#C6 = psd.pick('C6').get_data()[0,0:]
#plt.plot(psd.freqs, C6, label="C6 psd get_data")
#plt.plot(psd.freqs, 10*np.log10(C6*10**12), label="C6 10*log(psd*10**12)")
#plt.legend()
