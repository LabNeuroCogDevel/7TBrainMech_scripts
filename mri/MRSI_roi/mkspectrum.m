%
% launch SVR1HFinal gui
%
% 20191126 - init
function [f, coords] = mkspectrum(ld8)
  
  if nargin < 1
     [f, pth]= uigetfile({'*'},'any file with lunaid or inside a lunaid directory');
     selected_file = fullfile(f,pth);
     ld8=regexp(selected_file,'\d{5}_\d{8}', 'match');
     ld8=ld8{1},
  end
  %% find raw dir
  % raw dir collects everything we need. depends on ./000_setupdirs.bash
  rdir = sprintf('/Volumes/Hera/Projects/7TBrainMech/subjs/%s/slice_PFC/MRSI_roi/raw/', ld8);
  if ~exist(rdir,'dir')
     error('cannot read subject raw dir "%s"; run: ./000_setupdirs.bash %s', rdir, ld8)
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
end
