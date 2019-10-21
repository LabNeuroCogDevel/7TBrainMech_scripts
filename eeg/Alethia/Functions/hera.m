function savedir = hera(varargin)
   if ispc
       savedir = fullfile('H:/',varargin{:});
   else % isunix ismac
       savedir = fullfile('/Volumes/Hera/',varargin{:});
   end
   
   % for host specfic could try
   % [err, host] = system('hostname');
   % strncmp(host, 'rhea.wpic.upmc.edu', length(host))
end
