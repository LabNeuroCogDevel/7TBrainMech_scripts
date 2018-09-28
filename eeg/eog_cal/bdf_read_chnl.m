function [d_struct] = bdf_read_chnl(f, c, varargin)
%bdf_read_chnl -- read specific channels optionally w/preloaded header
%   provide channels as string
%   read in a bdf file. and fix status channel
%   if given 'horiz_eye', figure out the right channels
%
%% read in header if we dont have it
if nargin == 3
    h = varargin{1};
else
    h = ft_read_header(f);
end

%% fix channel names: horizontal eye
% 128 channel: EX3 and 4
% 64 channel:
%  if header has 'eye': FT7 = EX 3, FT8 = EX4 
%  for newer: EXG3 EXG4
horz_eye_idx = contains(c,'horiz_eye');
c_rename = c;
if any(horz_eye_idx)
    horzch = horz_eye_channel_name(h);
    % replace 'horiz_eye' with the actaul channels
    c = [c{~horz_eye_idx} horzch];
    c_rename = [c{~horz_eye_idx} {'eye_l','eye_r'}];
end

%% get the channels we want
try
    chidx = cellfun(@(x) strmatch(x,h.label), c);
catch ME
    disp(h.label)
    disp(cellfun(@(x) strmatch(x,h.label), c,'UniformOutput',0));
    nME = MException('MATLAB:NoChannels', ...
          [f ' does not have all channels: ' strjoin(c)]);
    throw(nME);
    % ME = addCause(ME, nME);
    % rethrow(ME)
    
end
d = ft_read_data(f, 'header', h, 'chanindx', chidx);

%% fix the status channel if included
statusidx = strmatch('Status',h.label);
statidxidx = find(statusidx == chidx);
if ~isempty(statidxidx)
  d(statidxidx,:) = fix_status_channel(d(statidxidx,:));
end

d_struct.file = f;
d_struct.Fs = h.Fs;
for i=1:size(d,1)
    d_struct.(c_rename{i}) = d(i,:);
end

end

