function [notch_filtered_signal] = notch_filter(EEG,hz2Eliminate,hzWidth)

%Notch
% wo=hz2Eliminate/(FS/2);
% bw=wo/10;
% [b,a]=iirnotch(wo,bw);
% canal_notch=filter(b,a,canal_notch_0);

%ALTERNATIVE
% EEG = pop_iirfilt( EEG, hz2Eliminate - hzWidth, hz2Eliminate + hzWidth, [], [1]);
figure
EEG = pop_eegfiltnew(EEG, hz2Eliminate - hzWidth, hz2Eliminate + hzWidth, 3380, 1, [], 1);
notch_filtered_signal = EEG.data;

plot_power_spectrum(notch_filtered_signal(1,:),EEG.srate,'Power Spectrum of Notch Filtered Signal')
