function [ PSD ] = PSD( s_erps,timebins,freqbins,channel )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
allvals = squeeze(s_erps(channel,freqbins,timebins));
PSD = mean(allvals(:));

end

