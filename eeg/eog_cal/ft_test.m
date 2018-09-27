function ft_test()
%test_fieldtrip -- opinionated toolbox checker for fieldtrip

ftloc='/opt/ni_tools/matlab_toolboxes/fieldtrip/';
if isempty(which('ft_read_header'))
    if ~ exists(ftloc,'dir')
        error(['Fieldtrip is not loaded and its not where I looked.\n'...
            'I recommend installing to ' ftloc ': \n' ...
            '\twget "ftp://ftp.fieldtriptoolbox.org/pub/fieldtrip/fieldtrip-lite-20180926.zip"' ...
            '\n\tunzip fieldtrip-lite*\n'...
            '\tmv fieldtrip*/ ' ftloc ...
            ])
    end
    
    addpath(ftloc)
end

end

