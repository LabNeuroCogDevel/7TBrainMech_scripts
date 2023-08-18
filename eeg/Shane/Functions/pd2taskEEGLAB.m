function [ee, varargout] =  pd2taskEEGLAB(ee)
% 20221018 - update EEG.event (input) by moving closest task ttl onto photodiode timing
%            and discarding 
% USAGE
%   EEG.event = pd2taskEEGLAB(EEG.event);
%   EEG.urevent = rmfield(EEG.event, 'urevent'); 
% also see
% [~,ttl_delta] = pd2taskEEGLAB(EEG.event);

tokeep = ones(length(ee),1);
valdelta = nan(length(ee),2);
max_ttl_to_pd_ms = 100;
for i=2:length(ee)
    ttl = ee(i).type;
    prev_ttl = ee(i-1).type;
    ttl_diff = ee(i).latency - ee(i-1).latency;
    if ttl == 1 && prev_ttl >= 10 % is task info (not pd or button push)
        if ttl_diff <= max_ttl_to_pd_ms
           ee(i).type = prev_ttl;
           tokeep(i-1) = 0; % remove prev (too early) task info
           valdelta(i,:) = [prev_ttl ttl_diff];
        else
           fprintf('warning: pd ignoring b/c diff %.0f ms\n', ttl_diff)
        end
    else
       fprintf('warning: pd next to button? %d\n', prev_ttl)
    end
end
ee = ee(find(tokeep));

% urevent now skips numbers. reindex
for i = 1:length(ee)
    ee(i).urevent= i; 
end
% NB. need to reset EEG.ureven too:
% EEG.urevent = rmfield(EEG.event, 'urevent'); 


% if we want more than just the updated EEG struct
% also return the value deltas (but only for when we updated)
if nargout > 1
    varargout{1} = valdelta(tokeep==0,:);
end

end