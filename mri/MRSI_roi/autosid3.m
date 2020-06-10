function f = autosid3(subj, f)
  sid3dir='/opt/ni_tools/matlab_toolboxes/sid3_MRRC/';
  addpath(sid3dir);
  % wont work if dir doesnt exist
  try
     cd(sid3dir)
  catch e
     f=[];
     disp(e)
     warning('not running sid3, not installed')
     return
  end
  def4

  if nargin < 2
    f=hgload('new10.fig');
  end

  % where to find things and how to change them
  % see buttom siarray_ifft_gui.m for more
  has_str = find(arrayfun(@(x) isprop(x,'String'),f.Children, 'Un', 1));
  att_str = arrayfun(@(x) get(x,'String'),f.Children(has_str), 'Un', 0);
  att_tag = arrayfun(@(x) get(x,'Tag'),f.Children(has_str), 'Un', 0);
  findtag = @(n) f.Children(strcmp(n,att_tag));
  findstr = @(n) f.Children(strcmp(n,att_str));
  setbytag = @(n,v) set(findtag(n),'String',v);


  pfcrawdir=['/Volumes/Hera/Projects/7TBrainMech/subjs/' subj '/slice_PFC/MRSI_roi/raw/'];

  setbytag('SIName',    [pfcrawdir 'siarray.1.1']);
  setbytag('ScoutName', [pfcrawdir 'seg.7']);  % is symlink to "17_7_FlipLR.MPRAGE"
  setbytag('ScoutRes',  '216');
  setbytag('ImageRes',  '216');

  cbs = findstr('Load'),
  % inject 
  b=uicontrol('Parent',f,'Style','pushbutton','String','junk');
  b.Callback=@(x) evalin('caller',x);
  % pushbuttons are in revers order from display?
  b.Callback(cbs(3).Callback)
  b.Callback(cbs(2).Callback)
  b.Callback(cbs(1).Callback)
  pwd

end
