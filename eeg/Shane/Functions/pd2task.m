function [ee] =  pd2task(ee)
tokeep = ones(length(ee),1);
for i=2:length(ee)
    ttl = ee(i).value;
    prev = ee(i-1).value;
    ttl_diff = ee(i).sample - ee(i-1).sample;
    if ttl == 1 && prev >= 10 % is task info (not pd or button push)
        if ttl_diff < 150   % 11 samples ~ 20ms
           ee(i).value = prev;
           tokeep(i) = 0;
        else
           fprintf('warning: pd ignoring b/c diff %.3f\n', ttl_diff/512)
        end
    else
       fprintf('warning: pd next to button? %d\n', prev)
    end
end
ee = ee(find(tokeep));
end