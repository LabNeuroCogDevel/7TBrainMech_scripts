function plot_power_spectrum(signal,FS,titleName)

[psd,f,NFFT] = power_spectrum(signal,FS);

figure
plot(f(1:length(psd(1:NFFT/10))),2*abs(psd(1:NFFT/10)));
title(titleName)