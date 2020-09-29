function savedir = hera(varargin)
   % HERA - find data root direcotry (probably /Volumes/Hera)
   % Hera on lab servers is in /Volumes (also see  'sshfs r:/Volumes /Volumes')
   % but on macOS mounting all /Volumes isn't a good idea
   % so will have variable Hera locations. enumerated in 'places'

   if ispc
       savedir = fullfile('H:/',varargin{:});
       return
   end

   % EDIT ME: add paths (vertically!) as they are needed
   % vertical for formating. but also see transpose in for loop def
   places = {
      '/Volumes/Hera'
      '/Users/fcalabro/mnt/rhea/Volumes/Hera'};
   rootdir = '';
   for p=places'
      if exist(p{1}, 'dir')
         rootdir=p{1};
         break
      end
   end

   if isempty(rootdir), error('cannot find hera route'), end
   savedir = fullfile(rootdir,varargin{:});
   
   % for host specfic could try
   % [err, host] = system('hostname');
   % strncmp(host, 'rhea.wpic.upmc.edu', length(host))
end
