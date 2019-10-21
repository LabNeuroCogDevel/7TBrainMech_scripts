function [EEG] = discard_channels(channels_to_discard, EEG)
    EEG.data(channels_to_discard,:) = [];
    EEG.chanlocs(channels_to_discard,:) = [];
    EEG.nbchan = size(EEG.data, 1);
