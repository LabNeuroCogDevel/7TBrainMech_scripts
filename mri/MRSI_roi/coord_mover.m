function [f, coords] = coord_mover(ld8, varargin)
%COORD_MOVER move subject coordinates about the z plane
%   can take a subject id (and will find needed files)
%    coord_mover('10129_20180917')
%   or set subjid to
%    coord_mover('','subjcoords', 'coordinate.txt', 'brain','t1.nii')
%   can also specify 
%    coord_mover(...,'roilist','mni_label_file.txt')
%
% coordinate.txt has columns: roi#, x, and y. (z is optional)
%  1	64  69
%  2	150  68
%  ...
% labels for roi number are extracted from 'mni_label_file'
%
% EXAMPLE SUBJ:
% [f, orig_coord] = coord_mover('11323_20180316')
%  loads slice_roi_CM_%s_16.txt, rorig.nii, and gm_sum.nii from subj dir
%
% EXAMPLE FF:
% [f, orig_coord] = coord_mover('FF') % loads default labels and coords; prompts to pick rorig.nii.gz
%
% EXAMPLE CORD BUILDER
%   # seq 1 24|sed s/$/:/ > tmp/roilist_labels.txt
%   # sed 's/:/\t50\t50/g' tmp/roilist_labels.txt > tmp/empty_coords.txt
%   [f, orig_coord] = coord_mover('11323_20180316', 'labels_MP20191015.txt','tmp/roilist_labels.txt','subjcoords', 'tmp/empty_coords.txt')
%
% EXAMPLE view warped
% 
%   # cd /Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI_roi/mni_examples
%   # ./warp_to_example_subjs.bash ../mkcoords/ROI_mni_MP_20191004.nii.gz 10129_20180917 11734_20190128
%   [f, orig_coord] = coord_mover('10129_20180917', 'roilist','tmp/roilist_labels.txt','subjcoords', 'mni_examples/scout_space/ROI_mni_MP_20191004/10129_20180917_scout_cm.txt')
%
% EXAMPLE MNI COORDS
%  [f, orig_coord] = coord_mover('','subjcoords','mkcoords/mni_ijk.txt','brain','mkcoords/slice_mni.nii');

  mni_label_file='./mni_coords_MPOR_20190425_labeled.txt';

  NIFTIDIR='/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI/Codes_yj/NIfTI';
  % need nii reader in path
  if isempty(which('load_untouch_nii'))
      addpath(NIFTIDIR);
  end
  
  RAWDIRROOT='/Volumes/Hera/Projects/7TBrainMech/subjs/%s/slice_PFC/MRSI_roi/raw/';


  disp(varargin)
  p = inputParser;
  p.addRequired('ld8');
  p.addOptional('roilist', mni_label_file, @isfile);
  p.addOptional('subjcoords', '', @isfile);
  p.addOptional('brain', '', @isfile); 
  p.addOptional('gm', '', @isfile); 
  p.addOptional('show_grid', 1, @islogical); 
  p.addOptional('who', []); 
  parse(p,ld8,varargin{:});

  % pop up file selector on subject id 'FF' or 'pick'
  % FF has default label and coords (empty)
  if strcmp(p.Results.ld8, 'FF')
     roilist = p.Results.roilist;
     if strcmp(roilist, mni_label_file), roilist = fullfile(pwd,'FF/FF_labels.txt'); end
     subjcoords = p.Results.subjcoords;
     if isempty(subjcoords), subjcoords = fullfile(pwd,'FF/FF_coord.txt'); end
     [f, pth]= uigetfile({'*.nii','*.nii.gz'},'rorig brain in scout nifti');
     brain=fullfile(pth, f);
     if ~exist(brain, 'file'); error('need brain to continue'); end
     newargs={'FF', 'brain',brain,'subjcoords', subjcoords, 'roilist',roilist};
     
     [f, pth]= uigetfile({'*.nii','*.nii.gz'},'gm sum mask');
     if ~isempty(f) 
         newargs={newargs{:},'gm',fullfile(pth,f)};
     end
     data.z_free = 0;
     parse(p,newargs{:});

  elseif strcmp(p.Results.ld8, 'pick')
     error('still working on this!')
  end


  disp(p.Results)
  mni_label_file = p.Results.roilist;

  
  
  %% set mni coords (use for labels
  % read in left and right
  fid=fopen(mni_label_file,'r'); 
  roi_mnicoord = strsplit(fread(fid,'*char')','\n');
  fclose(fid);
  roi_label = cellfun(@(x) regexprep(x,':.*',''), roi_mnicoord,'Un',0);
  roi_label = roi_label(~cellfun(@isempty, roi_label));

  if ~isempty(p.Results.gm)
     fprintf('[INFO] loading greymatter mask %s\n', p.Results.gm)
     mask_nii = load_untouch_nii(p.Results.gm);
     mask_nii = mask_nii.img;
  else
     % potentially loaded if lunaid is only specfied argument
     mask_nii = [];
  end

  %% pull from parsed data
  data.roi_label = roi_label;
  % store grid spacing
  data.show_grid = p.Results.show_grid;
  % and id info
  data.ld8=ld8;
  % label name with "labels" and ".txt"
  %[ ~, label_fname, ~ ] = fileparts(mni_label_file);
  %data.label=regexprep(regexprep(label_fname, '_?label(s|ed)?_?',''));
  % e.g.  'mni_coords_MPOR_20190425' from ./mni_coords_MPOR_20190425_labeled.txt;
  %% if we are only given a lunaid, we can find nii and coord
  if isempty(p.Results.brain)
      fprintf('[INFO] no brain specified, looking up by id: %s\n', ld8)
       %% find raw dir
      % raw dir collects everything we need. depends on ./000_setupdirs.bash
      rdir = sprintf(RAWDIRROOT, ld8);
      if ~exist(rdir,'dir')
         error('cannot read subject raw dir "%s"; run: ./000_setupdirs.bash %s', rdir, ld8)
      end
      data.rdir=rdir;

      %% read mprage
      mprage_file = [rdir '/rorig.nii'];
      if ~exist(mprage_file,'file')
         error('cannot read subject mprage (FS) in slice space "%s"; run: ./000_setupdirs.bash %s', mprage_file, ld8)
      end

      % grab it
      nii = load_untouch_nii(mprage_file);

      %% look for parc files -- can give rough est of gm
      gm_file = [rdir '/gm_sum.nii'];
      if ~exist(gm_file,'file')
         warning('cannot read subject gm parc file in slice space "%s"; run: ./000_setupdirs.bash %s', gm_file, ld8)
      else
          mask_nii = load_untouch_nii(gm_file);
          mask_nii = mask_nii.img;
      end
      
      
      %% get coords_file
      % like /Volumes/Hera/Projects/7TBrainMech/subjs/11323_20180316/slice_PFC/MRSI_roi/raw/slice_roi_MPOR20190425_CM_11323_20180316_16.txt
      %  0	63  63
      %  1	68  92
      %  2	60  90
      if isempty(p.Results.subjcoords)
         % TODO: find slice number might not be 16
         coords_file=sprintf('%s/slice_roi_MPOR20190425_CM_%s_16.txt',rdir,ld8);
      else
         coords_file = p.Results.subjcoords,
      end

      if ~exist(coords_file, 'file')
         error('cannot read coord file "%s"; run: ./000_setupdirs.bash %s', coords_file, ld8)
      end
      

      %% we are moving in a fixed slice. z is not free
      data.z_free = 0;
      
  elseif ~isempty(p.Results.subjcoords)
      fprintf('[INFO] loading specified brain and coords %s %s\n', p.Results.brain, p.Results.subjcoords)
      coords_file = p.Results.subjcoords;
      mprage_file = p.Results.brain;
      nii = load_untouch_nii(mprage_file);
      % only if we haven't already set it
      if ~ismember('z_free', fieldnames(data))
        data.z_free=1;
      end
  else
      error('input should be lunaid or ('''',''coord'',''coordfile'',''brain'',''image.nii'')')
  end
  
  if isempty(mask_nii) 
      fprintf('[INFO] no greymatter mask\n')
      mask_nii = nan(size(nii.img));
  end

  if ~all(size(mask_nii) == size(nii.img))
      error('mask (gm) is not the same size as the input nifti!')
  end
  
  n_rois = length(roi_label); % probably 12

  z_mid = ceil(size(nii.img,3)/2);
  
  coords = read_coords(coords_file, n_rois, z_mid);

  
  %% keep track of old coords
  data.orig_coords = coords;

  % input filename
  data.coords_file = coords_file;
  
  % check roi labels match number of coordinates
  if length(roi_label) ~= size(coords,1)
      roi_label,
      coords,
      error('wrong number of rois in %s vs %s', coords_file, mni_label_file)
  end
  
  %% roi choices
  
  % color rois
  % help from  https://www.mathworks.com/matlabcentral/answers/153064-change-color-of-each-individual-string-in-a-listbox
  data.roi_colors = jet(n_rois);
  rgb2hex = @(rgb) sprintf('%s', dec2hex(round(rgb.*255), 2 )');
  html='<html><font id="%d" color="#%s">%d %s</font></html>';
  roibox_str = arrayfun(@(i) ...
                 sprintf(html, i, rgb2hex(data.roi_colors(i,:)), i, roi_label{i}), ...
                 1:n_rois, 'Un',0);
  
  %% GUI figure  
  xdim = nii.hdr.dime.dim(2);
  ydim = nii.hdr.dime.dim(3);
  zdim = nii.hdr.dime.dim(4);
  
  a_w = xdim*2; a_h= ydim*2;
  % where should we show slice
  % how to update axial images
  mk_ax = @(x,y,t) axes('Units','Pixels', ...
                       'Position', [x, y, a_w, a_h],...
                       'Tag', t);


  % pos: dist from left, dist from bottom, width, hieght
  f = figure('Visible','off','Position',[360 500 3*a_w 2*a_h+40]);
  
  % put coords into gui data
  data.coords = coords;
  data.z_mid = z_mid;
  data.vox_size = [9 9 10];
  data.nii = nii;
  data.mask = mask_nii;
  data.mprage_file = mprage_file;

  % initialize undo
  nundos=20;
  data.undo=zeros([nundos, size(data.coords)]);
  
  % get initials (who) and add to data
  if ~isempty(p.Results.who)
     data.who = {p.Results.who};
  else
     data.who = inputdlg('Your Initials (then TAB, then ENTER)');
  end
  if isempty(data.who)
     data.who = 'UNKOWN';
  else
     data.who = upper(data.who{1});
  end
  
  % save data to figure
  guidata(f,data);
  
  % draw axial images
  colormap bone;
  mk_ax(10,       40, 'axabove');
  mk_ax(10+a_w,   40, 'axmid');
  mk_ax(10+a_w*2, 40, 'axbelow');
  
  % sagital
  axes('Units','Pixels', ...
       'Position', [a_w*2, a_h+40, ydim*2, zdim*2], ...
       'Tag', 'sag');
  
  %coronal
  axes('Units','Pixels', ...
       'Position', [a_w, a_h+40, xdim*2, zdim*2], ...
       'Tag', 'cor');
  

  % box to select rois
  buttonx=20;
  roibox = uicontrol('Position',[buttonx, a_h+40, floor(a_w/2), a_h-80], ...
                     'String',roibox_str,...
                     'Style','listbox', ...
                     'Tag', 'roibox', ...
                     'Callback', @(s,r) update_display(gcf));

  %% Buttons
  uicontrol('Position',[buttonx, a_h+20, 100, 20], ...
            'String','mni',...
            'Tag', 'mni_button', ...
            'Callback', @mni ...
            );    
  buttonx=buttonx+100;

  uicontrol('Position',[buttonx, a_h+20, 100, 20], ...
            'String','Reset',...
            'Tag', 'reset_button', ...
            'Callback', @reset_coords ...
            );
  buttonx=buttonx+100;

  uicontrol('Position',[buttonx, a_h+20, 100, 20], ...
            'String','Reset1',...
            'Tag', 'reset1_button', ...
            'Callback', @reset_coords1 ...
            );                 
  buttonx=buttonx+100;
  % move to best GM spot
  uicontrol('Position',[buttonx, a_h+20, 100, 20], ...
            'String','GM search',...
            'Tag', 'gmsearch_button', ...
            'Callback', @gm_search ...
            );      
  buttonx=buttonx+100;

  uicontrol('Position',[buttonx, a_h+20, 100, 20], ...
            'String','GM1',...
            'Tag', 'gmsearch1_button', ...
            'Callback', @gm_search1 ...
            );      
  buttonx=buttonx+100;
  % undo
  uicontrol('Position',[buttonx, a_h+20, 100, 20], ...
            'String','Undo',...
            'Tag', 'undo_button', ...
            'Callback', @undo_crd ...
            );      
  buttonx=buttonx+100;

  % toggle grid
  uicontrol('Position',[buttonx, a_h+20, 100, 20], ...
            'String','grid',...
            'Tag', 'grid_button', ...
            'Callback', @toggle_grid ...
            );      
  buttonx=buttonx+100;

  uicontrol('Position',[buttonx, a_h+20, 100, 20], ...
            'String','Save',...
            'Tag', 'save_button', ...
            'Callback', @(s,e) save_coords() ...
            );
  buttonx=buttonx+100;

  uicontrol('Position',[buttonx, a_h+20, 100, 20], ...
            'String','Load',...
            'Tag', 'load_button', ...
            'Callback', @(s,e) load_coords(n_rois,z_mid) ...
            );
  buttonx=buttonx+100;

  uicontrol('Position',[buttonx, a_h+20, 100, 20], ...
            'String','Help',...
            'Tag', 'help_button', ...
            'Callback', @roihelp ...
            );
  buttonx=buttonx+100;

  %% position table
  % roi positions original and new
  % TODO: combine into one, add html color
  uicontrol('Position',[20+a_w/3, a_h+40, a_w/3, a_h-80], ...
            'String',sprintf('%d %d %d\n', coords(:,1:3)'),...
            'Style','text', ...
            'Tag', 'disp_orig');
  uicontrol('Position',[a_w*2/3, a_h+40, a_w/3, a_h-80], ...
            'String',sprintf('%d %d %d\n', coords'),...
            'Style','text', ...
            'Tag', 'disp_current');


  % draw all the rectangles
  update_display(f); %,[axial_above, axial_mid, axial_below])
  set(f,'windowscrollWheelFcn', @scroll_cb);
  % cannot bind to individual axis :(
  % could use mousemove to see if we are in an image
  % ax.windowscrollWheelFcn = @scroll_cb;
  % Unrecognized property 'windowscrollWheelFcn' for class
  % 'matlab.graphics.axis.Axes'
  
  set(f,'KeyPressFcn', @keyboard_cb);
  
  f.Visible = 'on';
end

function scroll_cb(src, event)
  data = guidata(src);
  root=groot;
  % 1 is down
  if event.VerticalScrollCount==1 
    undo_crd();
  else % -1 is up
  % TODO if up, gm search; down = undo
    gm_search1();
  end
end

function keyboard_cb(src, event)
  switch event.Key
    case 'rightarrow'
      shift_roi(1,1);
    case 'leftarrow'
      shift_roi(1,-1);
    case 'uparrow'
      shift_roi(2,1);
    case 'downarrow'
      shift_roi(2,-1);
    case 'g'
      gm_search1()
    case 'u'
      undo_crd();
    case 'r'
      reset_coords1();
    case 'equal' % actually looking at + or |
      toggle_grid();
    case 'backslash'
      toggle_grid();
    case 'pagedown'
      roibox=findobj(src,'Tag','roibox');
      set(roibox, 'Value', roibox.Value+1);
      update_display()
    case 'pageup'
      roibox=findobj(src,'Tag','roibox');
      set(roibox, 'Value', roibox.Value-1);
      update_display()

    % go to nearest roi
    case 'n'
      data = guidata(src);
      roibox=findobj(src,'Tag','roibox');
      cur = get(roibox, 'Value');
      dist = squareform(pdist(data.coords(:,2:3)));
      others = setdiff(1:length(data.coords),cur);
      [~, closest_roi] = min(dist(others,cur));
      % we took out cur, add back if closest is after cur
      if closest_roi >= cur, closest_roi=closest_roi+1; end
      set(roibox, 'Value', closest_roi);
      update_display()
      
    % number 1-9
    case arrayfun(@num2str,1:9,'Uni',0)
      set(findobj(src,'Tag','roibox'), 'Value', str2num(event.Key));
      update_display()
    case {'h','slash'}
      roihelp();
      
    otherwise
      fprintf('no binding for %s\n',event.Key);
      return
  end

end

function shift_roi(xy,amnt)
  f=gcf;
  data = guidata(f);
  cur_roi = get(findobj(f,'Tag','roibox'), 'Value');
  i=xy+1; % first col is roi number
  data.coords(cur_roi,i) = data.coords(cur_roi,i) + amnt;
  guidata(f,data);
  update_display(f);
end

function roihelp(varargin)
      msgbox({'pageup/down, 1-9: change roi'
               'n: go to nearsest roi'
               'arrows: move roi 1 px'
               'right click:  select closest roi'
               'left click: position roi'
               'g, scroll up: position in best gm (-5:5 px)' 
               'u, scroll down: undo'
               '= |: toggle grid'
               'r: reset this roi coord'
               '!! google doc url placed on clipboard !!' ...
               });
      url='https://docs.google.com/document/d/1d6KCGho1bERh7dXoNBs0QXBdNbq6SHhjFFbDGg4Bgu8'
      clipboard('copy',url)
end


function set_coord(src, roibox, fromidx, toidx)
% src is the plot source
% roibox is the listbox with current roi
% fromidx is x,y of plot
% toidx is coord dimensions
  if nargin < 3
      fromidx=1:2;
      toidx=1:2;
  end
  
  %% get info
  xyz = get(src, 'CurrentPoint');
  data = guidata(src);
  root=groot;

  if strncmp(get(root.CurrentFigure,'SelectionType'), 'alt', 3)
  %% right click: update current roi using closest location
    xys=data.coords(:,toidx+1);
    click=xyz(1,fromidx);
    click_dist = squareform(pdist([click; xys]));
    % first pair is where we clicked, dont inclue that in the min search
    % only care about one row or column in dist matrix. pick first column to search
    [~, closest_roi] = min(click_dist(2:end,1));
    set(roibox, 'Value', closest_roi);
  else
  %% left click: update position of cur roi to clicked location
    cur_roi = get(roibox, 'Value');
    data.coords(cur_roi,toidx+1) = round(xyz(1,fromidx));
    guidata(src, data)
  end

  update_display(root.CurrentFigure)
  %fprintf('from: '); disp(data.coords(cur_roi,:));
  %fprintf('changing idx: '); disp(toidx);
  %fprintf('to: ');disp(xyz(1,fromidx));
  %fprintf('roi %d: %d %d %d\n',cur_roi, data.coords(cur_roi,2:4))
end

function i = rng(center,sz)
   i = (center-floor(sz/2)):(center+floor(sz/2));
end
function [mask_sum, nvox]  = ngm(crd, mask, vsz)
   mask_sum = 0;
   nvox = 0;
   % only highlight current rois if we have it
   if(crd(1) == 0 || crd(2) == 0 || isempty(mask) ), return; end
   mcnt = mask(rng(crd(1),vsz(1)),...
               rng(crd(2),vsz(2)),...
               rng(crd(3),vsz(3)) );
   mask_sum = sum(mcnt(:));
   nvox = numel(mcnt);
end

function best_crd = gm_searchr(r, data)
     crd = data.coords(r,2:4);
     best_crd = crd;
     best_sum = ngm(crd, data.mask, data.vox_size);
     orig_sum = best_sum;
     % dumb slow search of 11x11 grid for best local gm value
     for shifti=-5:5
        for shiftj=-5:5
           moveby = [shifti, shiftj, 0];
           thiscrd = crd + moveby;
           thisgm = ngm(thiscrd, data.mask, data.vox_size);
           if thisgm > best_sum
              best_crd = thiscrd;
              best_sum = thisgm;
           end
        end
     end
     fprintf('roi %d: %s\t(%d,%d)=%d moved to (%d,%d)=%d\n', ...
        r, data.roi_label{r}, crd(1),crd(2),orig_sum,best_crd(1),best_crd(2),best_sum);
end
function gm_search(varargin)
  f=gcf;
  data = guidata(f);
  nroi = size(data.coords, 1);
  for r = 1:nroi
     best_crd = gm_searchr(r, data);
     data.coords(r,2:4) = best_crd;
  end
  guidata(f,data);
  update_display(f);
end
function gm_search1(varargin)
  f=gcf;
  data = guidata(f);
  r = get(findobj(f,'Tag','roibox'), 'Value');
  best_crd = gm_searchr(r, data);
  data.coords(r,2:4) = best_crd;
  guidata(f,data);
  update_display(f);
end

function reset_coords1(varargin)
  f=gcf;
  cur_roi = get(findobj(f,'Tag','roibox'), 'Value');
  data = guidata(f);
  data.coords(cur_roi,:) = data.orig_coords(cur_roi,:);
  guidata(f,data);
  update_display(f);
end
function toggle_grid(varargin)
  f=gcf;
  data = guidata(f);
  data.show_grid = ~data.show_grid;
  guidata(f,data);
  update_display(f);
end

function mni(varargin)
  f=gcf;
  data = guidata(f);
  outname = save_coords();
  savedir = fileparts(outname);

  %% take coorddinates into mni space 
  % see 050_ROIs.bash (initial coord lookup),
  %   [called by coord_builder:]
  %     subjcoord2mni.bash (makes blob),
  %     subjroimni2mniroi.bash (makes sphere) 
  % requires lncd preproc directory (for warp coefs)
  preprocdir = [data.rdir '/../../ppt1'];
  slicedir = [data.rdir '../..'];
  cmd = sprintf('env -i bash -lc "./coord_builder.bash subj-to-mni %s %s %s %s"', ...
        outname, preprocdir, slicedir, savedir)
  system(cmd)

  % TODO: only run afni if it's not already running (check pgrep?)
  system(sprintf('afni %s', savedir))
end

function reset_coords(varargin)
  f=gcf;
  data = guidata(f);
  data.coords = data.orig_coords;
  guidata(f,data);
  update_display(f);
end

function outname=save_coords()
  f=gcf;
  data = guidata(f);
  %% TODO: launch afni?
  % inputs are subj, label, who
  savedir = fullfile(fileparts(data.coords_file), data.who);
  mkdir(savedir)
  outname=fullfile(savedir,'picked_coords.txt');
  dlmwrite(outname, data.coords, 'delimiter','\t');
end

function inname=load_coords(n_rois,z_mid)
  inname='DNE';
  f=gcf;
  data = guidata(f);
  [n, fn]  = uigetfile(data.coords_file,'Coord File');
  if isempty(n), return, end
  inname = fullfile(fn,n);
  data.coords = read_coords(inname,n_rois,z_mid);
  guidata(f,data);
  update_display(f);
  % todo use recommend (2019a): writematrix(data.coords, outname)
end

function coords = read_coords(coords_file, n_rois, z_mid)
  coords = load(coords_file);
  coords = coords(coords(:,1)~=0,:); % remove roi 0
  
  % make 3rd coordinate middle of nifti if not provided
  if(size(coords,2) == 3)
      coords(:,4) = z_mid;
  end

  n_coords = size(coords, 1)
  if n_coords ~= n_rois
     warning('expected %d rois, have %d in %s', n_rois, n_coords, coords_file)
     % replace missing rois with 0s
     coords_new = zeros(n_rois,size(coords,2)); % TODO: dont hardcode?
     coords_new(:,4) = 50; % set z to 50
     coords_new(:,1) = 1:n_rois;
     coords_new(coords(:,1),:) = coords;   
       
     coords = coords_new;
  end
end

function m = update_undo(m, crd)
   if all(reshape(squeeze(m(1,:,:)) == crd,1,[])), return, end
   topgone = m(1:(end-1),:,:);
   crd = reshape(crd,[1 size(crd)]);
   m = [crd; topgone];
end
function undo_crd(varargin)
   f=gcf;
   data = guidata(f);
   crds = squeeze(data.undo(2,:,:));
   % dont do anything if we've reached the end of the undos
   if(all(reshape(crds==0,[],1))), return; end
   data.coords = crds;

   data.undo = [ data.undo(2:end,:,:); zeros([1,size(crds)]) ];
   guidata(f,data);
   update_display(f, [], 0);
end

function update_display(f, all_ax, updateundo)
   % defaults
   if nargin < 1, f=gcf;        end % get current figure if not provided
   if nargin < 2, all_ax=[];    end % axis if we didn't explicly give them
   if nargin < 3, updateundo=1; end % default to updating undo

   % rectantles
   data = guidata(f);
   if ~isfield(data,'rects'), data.rects={}; end
   % undos
   if updateundo && isfield(data,'undo'), data.undo = update_undo(data.undo, data.coords); end
   % axes
   if isempty(all_ax)
       axs = arrayfun(@(x) strncmp(x.Tag,'ax',2), f.Children);
       all_ax = f.Children(axs);
   end
   
   % remove any previous rectangles
   for rr=data.rects
       for r=rr{1}
           if ~isempty(r),  delete(r{1}); end
       end
   end
   
   
   nroi = size(data.roi_colors,1);
   % set colors. current ROI is white
   colors = data.roi_colors;
   roibox = findobj(f,'Tag','roibox');
   cur_roi = get(roibox, 'Value');
   if ~isempty(cur_roi)
       % cur_roi = 1;
       colors(cur_roi,:) = 1;
   end

   %% Calc number of true voxels in it
   crd = data.coords(cur_roi,2:4);
   [data.mask_sum, nvox] = ngm(crd, data.mask, data.vox_size);
   
   
   %% update all axial
   for ax_i = 1:numel(all_ax)
       set(f,'CurrentAxes',all_ax(ax_i));
       if isempty(cur_roi)
           roi_z = data.z_mid;
           show_rois = 1:nroi;
       else
           roi_z = data.coords(cur_roi,4);
           show_rois = find( abs(data.coords(:,4) - roi_z) < 10 );
       end
       
       % put axial images up
       a = all_ax(ax_i);
       zpos=roi_z -5 + 5*(ax_i-1);
       % no z? center at half
       if(zpos<=0), zpos=floor(size(data.nii.img,3)/2); end
       
       im_at_coords = flipud(rot90(data.nii.img(:,:,zpos)));
       update_brain(a, im_at_coords);
       update_callback(a, 1, [1 2], roibox);
       
       % when we want the grid show it on the middle axial
       pixdims = data.vox_size(1:2); % [9,9]
       if data.show_grid && ax_i == 2
           draw_grid(size(im_at_coords), pixdims);
       end         

       
       % GM count and row/col label
       xy = get(f, 'CurrentPoint');
              
       info_label = sprintf('Right; z=%d; %dGM (%dvox) @ row=%d, col=%d', ...
                    zpos, data.mask_sum, nvox, xy(2), xy(1));
       text(a,10,10, info_label ,'Color','White')
       
       % draw rois
       data.first_ax=1; % only need to draw once if z isn't free
       data.rects{ax_i} = arrayfun(@(i) ...
          draw_rect(data.coords(i,2), data.coords(i,3), colors(i,:), pixdims),...
          show_rois,'Un',0);
       
       % point spread with red fill if overlap
       % TODO: fix psf thres
       psfthres=mean(pixdims)*2;
       data.circles{ax_i} = draw_psf(data.coords(show_rois,2:3), colors(show_rois,:), pixdims.*2, psfthres);
   end
   
   %% update sag
   s = findobj(f,'Tag','sag');
   if(~isempty(s) && ~isempty(cur_roi))
       roi_x = data.coords(cur_roi,2);
       % update sag view
       if(roi_x <= 0), roi_x = floor(size(data.nii.img,1)/2); end
       im_at_coords = fliplr(rot90(squeeze(data.nii.img(roi_x,:,:)),3));
       update_brain(s, im_at_coords);
       update_callback(s, data.z_free, [2 3], roibox);
       text(s,10,10,sprintf('x=%d',roi_x) ,'Color','White')

       % draw boxes for rois in range
       show_rois = find( abs(data.coords(:,2) - roi_x) < 10 );
       set(f,'CurrentAxes',s);
       data.rects{numel(all_ax)+1} = arrayfun(@(i) ...
            draw_rect(data.coords(i,3), data.coords(i,4), colors(i,:), [9, 10]),...
            show_rois, 'Un',0);
             
         
   end
   
   %% coronal
   c = findobj(f,'Tag','cor');
   if(~isempty(c) && ~isempty(cur_roi))
       roi_y = data.coords(cur_roi,3);
       if(roi_y <= 0), roi_y = floor(size(data.nii.img,2)/2); end
       
       % update sag view
       im_at_coords = fliplr(rot90(squeeze(data.nii.img(:,roi_y,:)),3));
       update_brain(c, im_at_coords);
       update_callback(c, data.z_free, [1 3], roibox);
       
       % say where we are
       text(c,10,10,sprintf('y=%d',roi_y) ,'Color','White');

       % draw boxes for rois in range
       show_rois = find( abs(data.coords(:,3) - roi_y) < 10 );
       set(f,'CurrentAxes',c);
       data.rects{numel(all_ax)+1} = arrayfun(@(i) ...
           draw_rect(data.coords(i,2), data.coords(i,4), colors(i,:), [9, 10]),...
           show_rois, 'Un',0);
   end
   
   % update text
   t = findobj(f,'Tag','disp_current');
   if(~isempty(t))
     t.String = sprintf('%d %d %d %d\n', data.coords');
   end
   

   
   % put rects backinto gui data
   guidata(f,data)
end

function o = draw_psf(coords, colors, pxd, thres)
% DRAW_PSF - draw cirlces of radius r. fill if any coord overlaps
  n = length(coords);
  d = pdist(coords);
  tooclose = any(squareform(d < thres));
  o = arrayfun(@(i) ...
     draw_rect(coords(i,1), coords(i,2), colors(i,:), pxd, 1, tooclose(i)),...
     1:n,'Un',0);
end

function r = draw_rect(x, y, color, d, iscircle, dofill)
   % x, y is center
   % d is width, and height
   %% default options: no cirlce, no fill
   if nargin == 4
       iscircle=0;
       dofill=0;
   end

   %% define options
   % rectange: lower left corner, size
   pos = [x-d(1)/2, y-d(2)/2, d(1), d(2)];
   opts={...
      'Position', pos, ...
      'EdgeColor', color, ...
      'LineWidth', 1,...
      'HitTest', 'off', ...
   };
   % circles change linestyle and have curvature
   if iscircle, opts={opts{:},'Curvature', 1, 'LineStyle', ':'}; end
   % always red, alpha of .3 if fill
   if dofill,   opts={opts{:},'FaceColor', [1 0 0 .3]}; end

   %% plot
   r = rectangle(opts{:});
end

function g = draw_grid(xymax, vxsize)
  x = 0:vxsize(1):xymax(1);
  y = 0:vxsize(2):xymax(2);
  [X, Y] = meshgrid(x,y);
  hold on
  g = { plot(X, Y, 'g'); ...
        plot(X',Y','g')};
end

function p = update_brain(ax, imdata)
   % update view given data
   this_tag = get(ax,'Tag');
   p =imagesc(ax, imdata);
   set(p,'HitTest', 'off');
   set(ax,'YDir', 'normal');
   set(ax,'Tag', this_tag); % this gets lost every imagesc
end

function update_callback(ax, isfree, coord_idxs, roibox)
   if isfree
      ax.ButtonDownFcn = @(src, event) set_coord(src, roibox, 1:2, coord_idxs);
   else
      ax.ButtonDownFcn = @(src, event) set_coord(src, roibox, 1, coord_idxs(1));
   end
end

% not in older matlabs
function r=isfile(f)
   r=exist(f,'file');
end
