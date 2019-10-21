function custom_verboseprintf(verbose, varargin)
if strcmpi(verbose, 'on')
    fprintf(varargin{:});
end;