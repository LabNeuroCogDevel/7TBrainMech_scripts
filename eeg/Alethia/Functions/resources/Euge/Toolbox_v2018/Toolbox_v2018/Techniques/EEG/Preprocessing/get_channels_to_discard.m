function [channels_to_discard, median_variance, jumps, nr_jumps] = get_channels_to_discard(signal, threshold)

signal = signal'; %¿Por qué? [comentario 22/3/18]

signalvariance=var(signal);
aboveSV=find(signalvariance>(5*median(signalvariance)));
belowSV=find(signalvariance<(median(signalvariance)/5));

median_variance = union(aboveSV,belowSV); %concatenación de los elementos sin repetición en ambas matrices

nr_jumps=zeros(1,size(signal,2));
for k=1:size(signal,2);
    nr_jumps(k)=length(find(diff(signal(:,k))>threshold)); % find jumps>80uV
end

figure,plot(nr_jumps);
title('Jumps')
jumps = find(nr_jumps>0);

channels_to_discard = sort(union(median_variance,jumps));