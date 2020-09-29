function savedir = hera(varargin)
   if ispc
       savedir = fullfile('H:/',varargin{:});
       return
   end

   % Hera on rhea is in volumes (also see e.g. 'sshfs r:/Volumes /Volulmes')
   % but on macOS mounting all /Volumes isn't possible
   % so will have variable Hera locations. enumerated here
   places = {
      '/Volumes/Hera'
      '/Users/fcalabro/mnt/rhea/Volumes/Hera'};
   rootdir = '';
   for p=places
      if exist(p{1}, 'dir')
         rootdir=p{1};
         break
      end
   end
   if isempty(rootdir), error('cannot find hera route'), end
   savedir = fullfile('/Volumes/Hera/',varargin{:});
   
   % for host specfic could try
   % [err, host] = system('hostname');
   % strncmp(host, 'rhea.wpic.upmc.edu', length(host))
end
