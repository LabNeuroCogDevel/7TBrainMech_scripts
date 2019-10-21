function [ PSDdb,PSD ] = calcPSD( s_erps,timebins,freqbins,channel,s_mbases )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
allvals = squeeze(s_erps(channel,freqbins,timebins));
allBL = squeeze(s_mbases(channel,freqbins));
PSDdb = squeeze(allBL' * mean(allvals));


allvals = 10.^(squeeze(s_erps(channel,freqbins,timebins))./10);
allBL = 10.^(squeeze(s_mbases(channel,freqbins))./10);
PSD =squeeze(allBL' * mean(allvals));
end

