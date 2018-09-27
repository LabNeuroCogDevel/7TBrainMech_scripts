function d = bdf_read_chnl(f, c, varargin)
%bdf_read_chnl -- read specific channels optionally w/preloaded header
%   provide channels as string
%   read in a bdf file. and fix status channel
%
%% read in header if we dont have it
if nargin == 3
    h = varargin{1};
else
    h = ft_read_header(f);
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

end

