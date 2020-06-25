function [bettaFull,BettaUp,BettaLow] = extractBettas(singchanPSD,Bfullrange,Buprange,Blowrange,freqs)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
%     singchanPSD = PSD(:,c)
mdFULL = fitlm(freqs(Bfullrange),singchanPSD(Bfullrange));
bettaFull = mdFULL.Coefficients.Estimate(2);

mdUP = fitlm(freqs(Buprange),singchanPSD(Buprange));
BettaUp = mdUP.Coefficients.Estimate(2);

mdLOW = fitlm(freqs(Blowrange),singchanPSD(Blowrange));
BettaLow = mdLOW.Coefficients.Estimate(2);
end

