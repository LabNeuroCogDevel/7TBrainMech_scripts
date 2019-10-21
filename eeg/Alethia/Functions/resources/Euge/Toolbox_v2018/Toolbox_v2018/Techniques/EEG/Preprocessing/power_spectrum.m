function [psd,f,NFFT] = power_spectrum(signal,FS)

T = 1/FS;                 % Sample time
LFFT = length(signal);    % Length of signal
NFFT = 2^nextpow2(LFFT);  % Next power of 2 from length of y
psd = fft(signal-mean(signal),NFFT)/LFFT;
f = FS/2*linspace(0,1,NFFT/2+1);