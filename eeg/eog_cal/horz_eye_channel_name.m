function horzch = horz_eye_channel_name(h)
% horz_eye_channel_name - given header, what are the horz channel names
   if length(h.label) == 144
        horzch = {'EXG3','EXG4'};
   % for the 4 with init 64 calibration
   elseif any(contains(h.label,'eye'))
        horzch = {'FT7','FT8'};
   else % 73 channels (64 head), no 'eye'
       horzch = {'EX3','EX4'};
   end
   if ~ all(cellfun(@(x) any(contains(h.label,x)), horzch))
       error('though should have horz eye channels %s in header, but do not',...
           strjoin(horzch))
   end
end