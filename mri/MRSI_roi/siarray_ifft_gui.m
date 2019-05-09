%
% launch SVR1HFinal gui
%
% 20190412 - init
function [f, coords] = siarray_ifft_gui(ld8)
  % example subj:
  % ld8 = '11323_20180316';
  
  n_rois = 12;
  
  %% find raw dir
  % raw dir collects everything we need. depends on ./000_setupdirs.bash
  rdir = sprintf('/Volumes/Hera/Projects/7TBrainMech/subjs/%s/slice_PFC/MRSI_roi/raw/', ld8);
  if ~exist(rdir,'dir')
     error('cannot read subject raw dir "%s"; run: ./000_setupdirs.bash %s', rdir, ld8)
  end

  %% read in coordinates
  % like /Volumes/Hera/Projects/7TBrainMech/subjs/11323_20180316/slice_PFC/MRSI_roi/raw/slice_roi_CM_11323_20180316_16.txt
  %  0	63  63
  %  1	68  92
  %  2	60  90
  % there can be many cord files, we want to pick the most recenet
  % from e.g.
  %  slice_roi_MPOR20190425_CM_11323_20180316_16.txt
  %  slice_roi_MPOR20190425_CM_11323_20180316_16_737541.477512_OR.txt
  %  slice_roi_MPOR20190425_CM_11323_20180316_16_737541.477513_WF.txt
  coords_file_patt=sprintf('%s/slice_roi_%s_CM_%s_*.txt',rdir,'MPOR20190425',ld8);
  cf_list=dir(coords_file_patt);
  if isempty(cf_list)
     error('cannot find coord file like "%s"; run: ./000_setupdirs.bash %s', coords_file_patt, ld8)
  end
  coords_file=fullfile(cf_list(end).folder,cf_list(end).name);
  fprintf('using cordinate file: %s\n', coords_file)

  coords = load(coords_file);
  coords = coords(coords(:,1)~=0,:); % remove roi 0
  if length(coords) ~= n_rois
     warning('expected %d rois, have %d in %s', n_rois, length(coords), coords_file)
     % replace missing rois with 0s
     coords_new = zeros(n_rois,3); 
     coords_new(:,1) = 1:n_rois;
     coords_new(coords(:,1),:) = coords;
     coords = coords_new;
  end




  %% launch figure
  addpath('SVR1HFinal');
  f=hgload('SVR1HFinal/SVR1H2015.fig');

  %% set all values
  % registration.out 7th mp2rage middle slice
  % fake segementation by picking phony `seg.7` (copy of from mprage slice 7)
  % reset angles

  % function to set string of tag
  setobj = @(x,y) set(findobj(f,'Tag',x),'String',y);

  % set scout
  setobj('DIRscout',rdir);
  setobj('FOVscout','216');
  setobj('RESscout','216');
  % load, select mprage_middle.mat

  % set seg, not used by probaly has to exist
  setobj('DIRsegment',rdir);
  setobj('FOVsegment','216');
  setobj('RESsegment','216');
  % load, select seg.7

  % si
  setobj('SIFileName',rdir)

  % reset angles to empty
  setobj('VOffset',0);
  setobj('HOffset',0);
  setobj('Angle',0);

  
  %% set coords
  % read in left and right
  fid=fopen('./mni_coords_MPOR_20190425_labeled.txt','r'); 
  side = textscan(fid, '%s %*[^\n]'); 
  fclose(fid);
  side=side{1}; % want first (and only) column

  % make MPFC left and ACC right to even out which roi goes where
  side{strncmp('ACC:', side,4)} = 'Left';
  side{strncmp('MPFC:', side,4)} = 'Right';

  if length(side) ~= length(coords)
      error('wrong number of rois in %s vs mni_coords.txt', coords_file)
  end
  % old roi example
  %  Left ACC: -8, 32, 23                           0 63 63                 
  %  Right ACC: 8, 32, 23                           1 68 92 
  %  ...    
  %  Right Middle Occipital Gyrus: 38, -71, -13    11 42 33
  %  Left Middle Occipital Gyrus: -42, -66, -10    12 86 26

  d.L = 1;  d.R = 1; % intialize left and right count
  for i = 1:length(coords)
      lr=side{i}(1); % L or R
      % TODO: confirm value is 'L' or 'R'
      
      % TODO: confirm row and col 20190430 -- flip col is left/right
      % TODO: confirm orientation RAI vs LPI?
      % set row
      lbl = sprintf('%s%d%s', lr, d.(lr),'Col');
      setobj(lbl, coords(i,2));
      % and col      
      lbl = sprintf('%s%d%s', lr, d.(lr),'Row');
      setobj(lbl, coords(i,3));
      % z is always 50 hopefully
      
      % enable radio
      rdo = sprintf('%s%dOn', lr, d.(lr));
      if coords(i,2) == 0 && coords(i,3) == 0
          radval=0;
      else
          radval=1;
      end
      set(findobj(f,'Tag',rdo), 'Value',radval)
      
      d.(lr) = d.(lr) +1;
  end
  
  if d.L ~= d.R
      error('uneven number of left (%d) and right (%d) rois', d.L, d.R)
  end
  
  %%
  % 1. selection: write (puts .loc in siarray folder)
  % 2. ifft (kspace transfrom)
  % 3. recon coord

  % WritePositions
  % Reorient slice
  % IFFT
  % Recon Coords
  % [enter] [enter]gg

end
  % see:  arrayfun(@(x) x.Tag,f.Children, 'Un', 0)
  %       findobj(f,'-regexp', 'Tag', 'scout.*')
  %       for c=f.Children', try, if strmatch('Reorient',c.String), c, end , end, end


  %  h = guihandles(f);
  % for hh=fieldnames(h)'; guidata(h.(hh{1})), end

  % hgload ProcessVarian7TData1k/recent7TaSiemens.fig
