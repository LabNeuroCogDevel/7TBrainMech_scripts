function x = fix_status_channel(x)
%FIX_STATUS_CHANNEL make status channel report values we expect
%   readjust by min of timseries, replace extrm vals w/0
 x = x - min(x);
 x(x>65000) = 0;
end

% 20241105: min doesn't work for some. experimenting with bitmask
% from https://mne.tools/dev/generated/mne.io.read_raw_bdf.html
% no luck
function x = fix_status_channel_weird(x)
   % f = '/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Shane/preprocessed_data/MGS/AfterWhole/ICAwholeClean_homogenize/11626_20180404_MGS_Rem_rerefwhole_ICA_icapru.set';
   % f = '/Volumes/Hera/Raw/EEG/7TBrainMech/11629_20191016/11629_20191016_mgs.bdf';
   f = '/Volumes/Hera/Raw/EEG/7TBrainMech/11626_20180404/11626_20180404_MGS.bdf';
   h = ft_read_header(f);
   statusidx = strmatch('Status',h.label);
   d = ft_read_data(f, 'header', h, 'chanindx', statusidx);
   mask = (2^16) - 1;
   x = bitand(-1*d(1,:),mask);
end
