function [ times ]= cleaned_times(times)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
p=bwconncomp([diff(times.puntos),1]==1);
for s = 1:size(p.PixelIdxList,2)
sizes(s) = size(p.PixelIdxList{1,s},1);
end

vec = p.PixelIdxList{1,find(sizes == max(sizes))}';
times.puntos = times.puntos(vec);
times.tiempos = times.tiempos(vec);

end

