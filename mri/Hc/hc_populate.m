function f = hc_populate(subj, f)
  % need subject is
  % and optionally a figure handle. will hgload if not provided
  % largely copied from "../../mri/MRSI_roi/siarray_ifft_gui.m"

  hc_rawdir=['/Volumes/Hera/Projects/7TBrainMech/scripts/mri/Hc/spectrum/' subj '/' ];
  if ~exist(hc_rawdir,'dir')
     error('cannot read subject raw dir "%s"! Do we have files from victor?', rdir)
  end

  figdir='/home/ni_tools/matlab_toolboxes/MRRC/SVR1HFinal';
  if ~exist(figdir, 'dir')
     error('cannot find hippocampus fig dur "%s"', figdir)
  end

  addpath(figdir);
  %olddir=pwd;
  %cd(figdir);
  %pwd


  %% 3 ways to get the figure: passed in, its open, or we need to load it
  if nargin < 2 
    % maybe we already have it open?
    % TODO: search through all open figures if more than one is open?
    all_figs = findall(groot,'Type','figure');
    if numel(all_figs) == 1 && strmatch(all_figs.Name,'Hippocampus') 
       disp('reusing only "Hippocampus" figure')
       f = all_figs;
    else
       disp('opening new "Hippocampus" figure')
       f=hgload([figdir '/SVR1H2015.fig']);
    end
  else
     disp('reusing provided figure')
  end


  %% set gui parameters to match our data and input folder
  % see 01_reorg_for_matlab_gui.bash for files
  setobj = @(x,y) set(findobj(f,'Tag',x),'String',y);

  setobj('DIRsegment', hc_rawdir);  % seg.7 is symlink to "17_7_FlipLR.MPRAGE"
  setobj('DIRscout',   hc_rawdir);  % also use seg.7 symlink as anat.mat
  setobj('SIFileName', hc_rawdir);  % symlinked but same name

  setobj('FOVscout','216');
  setobj('RESscout','216');
  setobj('FOVsegment','216');
  setobj('RESsegment','216');

  % for sid3, the input is the file itself not the folder so we can just push the load button
  % but not here. pushing load button should prompt for selecting the appropriate file
  x = warndlg('You will need to load push load to select the files for each seg, scout, and si before reorienting')
  return

  cbs = findobj(f,'String','Load');

  % inject - create a button that will call code from another button
  b=uicontrol('Parent',f,'Style','pushbutton','String','junk');
  b.Callback=@(x) evalin('caller',x);
  % call each pushbutton
  b.Callback(cbs(3).Callback)
  b.Callback(cbs(2).Callback)
  b.Callback(cbs(1).Callback)

end
