function verboseprintf(verbose, varargin)
%EEGLAB 14.1.1b embedded function in newtimef.m
if strcmpi(verbose, 'on')
    fprintf(varargin{:});
end;