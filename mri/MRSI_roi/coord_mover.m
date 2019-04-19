function [f, coords] = coord_mover(varargin)
%COORD_MOVER Summary of this function goes here
%   Detailed explanation goes here

  % example subj:
  % ld8 = '11323_20180316';
  % [f, orig_coord] = coord_mover('11323_20180316')
  %
  %  or mni coordinates
  % [f, orig_coord] = coord_mover('mkcoords/mni_ijk.txt','mkcoords/slice_mni.nii');
  
  
  %% set mni coords (use for labels
  % read in left and right
  fid=fopen('./mni_coords.txt','r'); 
  roi_mnicoord = strsplit(fread(fid,'*char')','\n');
  fclose(fid);
  roi_label = cellfun(@(x) regexprep(x,':.*',''), roi_mnicoord,'Un',0);
  roi_label = roi_label(~cellfun(@isempty, roi_label));
  
  
  %% if we are only given a lunaid, we can find nii and coord
  if length(varargin) == 1
      ld8 = varargin{1};
       %% find raw dir
      % raw dir collects everything we need. depends on ./000_setupdirs.bash
      rdir = sprintf('/Volumes/Hera/Projects/7TBrainMech/subjs/%s/slice_PFC/MRSI_roi/raw/', ld8);
      if ~exist(rdir,'dir')
         error('cannot read subject raw dir "%s"; run: ./000_setupdirs.bash %s', rdir, ld8)
      end

      %% read mprage
      mprage_file = [rdir '/rorig.nii'];
      if ~exist(mprage_file,'file')
         error('cannot read subject mprage (FS) in slice space "%s"; run: ./000_setupdirs.bash %s', mprage_file, ld8)
      end
      
      % need nii reader in path
      if isempty(which('load_untouch_nii'))
          addpath('/Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI/Codes_yj/NIfTI');
      end
      % grab it
      nii = load_untouch_nii(mprage_file);

      %% get coords_file
      % like /Volumes/Hera/Projects/7TBrainMech/subjs/11323_20180316/slice_PFC/MRSI_roi/raw/slice_roi_CM_11323_20180316_16.txt
      %  0	63  63
      %  1	68  92
      %  2	60  90
      coords_file=sprintf('%s/slice_roi_CM_%s_16.txt',rdir,ld8);
      % TODO: find slice number might not be 16
      if ~exist(coords_file, 'file')
         error('cannot read coord file "%s"; run: ./000_setupdirs.bash %s', coords_file, ld8)
      end
      data.z_free = 0;
      
  elseif length(varargin) == 2
      coords_file=varargin{1};
      nii = load_untouch_nii(varargin{2});
      data.z_free=1;
  else
      error('input should be lunaid or (coordfile, image.nii)')
  end
  
  
  n_rois = length(roi_label); % probably 12

  z_mid = ceil(size(nii.img,3)/2);
  
  coords = load(coords_file);
  coords = coords(coords(:,1)~=0,:); % remove roi 0
  
  % make 3rd coordinate middle of nifti if not provided
  if(size(coords,2) == 3)
      coords(:,4) = z_mid;
  end

  

  if length(coords) ~= n_rois
     warning('expected %d rois, have %d in %s', n_rois, length(coords), coords_file)
     % replace missing rois with 0s
     coords_new = zeros(n_rois,3); 
     coords_new(:,1) = 1:n_rois;
     coords_new(coords(:,1),:) = coords;
     coords = coords_new;
  end
  
  %% keep track of old coords
  data.orig_coords = coords;
  
  % check roi labels match number of coordinates
  if length(roi_label) ~= length(coords)
      error('wrong number of rois in %s vs mni_coords.txt', coords_file)
  end
  
  %% roi choices
  
  % color rois
  % help from  https://www.mathworks.com/matlabcentral/answers/153064-change-color-of-each-individual-string-in-a-listbox
  data.roi_colors = jet(n_rois);
  rgb2hex = @(rgb) sprintf('%s', dec2hex(rgb.*255, 2 )');
  html='<html><font id="%d" color="#%s">%s</font></html>';
  roibox_str = arrayfun(@(i) ...
                 sprintf(html, i, rgb2hex(data.roi_colors(i,:)), roi_label{i}), ...
                 1:n_rois, 'Un',0);
  
  %% GUI figure  
  xdim = nii.hdr.dime.dim(2);
  ydim = nii.hdr.dime.dim(3);
  zdim = nii.hdr.dime.dim(4);
  
  a_w = xdim*2; a_h= ydim*2;
  % where should we show slice
  z_above = z_mid + 5;
  z_below = z_mid - 5;
  % how to update axial images
  funcs.mk_ax = @(x,y) axes('Units','Pixels', ...
                       'Position', [x, y, a_w, a_h]);
  funcs.mk_brain = @(ax, c) imagesc(ax, flipud(rot90(nii.img(:,:,c))));


  % pos: dist from left, dist from bottom, width, hieght
  f = figure('Visible','off','Position',[360 500 3*a_w, 2*a_h+40]);
  
  % put coords into gui data
  data.coords = coords;
  data.funcs = funcs;
  data.z_mid = z_mid;
  data.nii = nii;
  guidata(f,data);
  
  % draw axial images
  colormap bone
  axial_above = make_axl_axis(10,       40, z_above, 'axabove', funcs);
  axial_mid   = make_axl_axis(10+a_w,   40, z_mid,   'axmid',   funcs);
  axial_below = make_axl_axis(10+a_w*2, 40, z_below, 'axbelow', funcs);
  
  % sagital
  sagax  = axes('Units','Pixels', ...
              'Position', [a_w*2, a_h+40, ydim*2, zdim*2]);
  set(sagax,'Tag', 'sag');
  
  %coronal
  corax  = axes('Units','Pixels', ...
              'Position', [a_w, a_h+40, xdim*2, zdim*2]);
  set(corax,'Tag', 'cor');
  
  % draw all the rectangles
  update_display(f); %,[axial_above, axial_mid, axial_below])
  
  % box to select rois
  roibox = uicontrol('Position',[20, a_h+40, floor(a_w/2), a_h-80], ...
                     'String',roibox_str,...
                     'Style','listbox', ...
                     'Tag', 'roibox');
  roibox.Callback = @(s,r) update_display(gcf);


  % Buttons
  rbtn   = uicontrol('Position',[20, a_h+20, 100, 20], ...
                     'String','Reset',...
                     'Tag', 'reset_button', ...
                     'Callback', @reset_coords ...
                     );
                   
  sbtn   = uicontrol('Position',[120, a_h+20, 100, 20], ...
                     'String','Save',...
                     'Tag', 'save_button', ...
                     'Callback', @(s,e) msgbox('not implemented') ...
                     );
  lbtn  = uicontrol('Position',[220, a_h+20, 100, 20], ...
                     'String','Load',...
                     'Tag', 'load_button', ...
                     'Callback', @(s,e) msgbox('not implemented') ...
                     );
  rbtn1  = uicontrol('Position',[320, a_h+20, 100, 20], ...
                     'String','Reset1',...
                     'Tag', 'reset1_button', ...
                     'Callback', @reset_coords1 ...
                     );                 
                 
  % roi positions original and new
  % TODO: combine into one, add html color
  dspcrd = uicontrol('Position',[20+a_w/3, a_h+40, a_w/3, a_h-80], ...
                     'String',sprintf('%d %d %d\n', coords'),...
                     'Style','text', ...
                     'Tag', 'disp_orig');
  crntcrd= uicontrol('Position',[a_w*2/3, a_h+40, a_w/3, a_h-80], ...
                     'String',sprintf('%d %d %d\n', coords'),...
                     'Style','text', ...
                     'Tag', 'disp_current');
  % each click changes the selected roi
  %set(axial_mid,'NextPlot','add')
  axial_above.ButtonDownFcn = @(src, event) set_coord(src, roibox);
  axial_mid.ButtonDownFcn = @(src, event) set_coord(src, roibox);
  axial_below.ButtonDownFcn = @(src, event) set_coord(src, roibox);

  
  
  f.Visible = 'on';
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
  data = guidata(src);
  xyz = get(src, 'CurrentPoint');
  cur_roi = get(roibox, 'Value');
  
  %fprintf('from: '); disp(data.coords(cur_roi,:));
  %fprintf('changing idx: '); disp(toidx);
  %fprintf('to: ');disp(xyz(1,fromidx));
  data.coords(cur_roi,toidx+1) = round(xyz(1,fromidx));  
  guidata(src, data)
  
  root=groot;
  update_display(root.CurrentFigure)
  %fprintf('roi %d: %d %d %d\n',cur_roi, data.coords(cur_roi,2:4))
end

function reset_coords1(varargin)
  f=gcf;
  cur_roi = get(findobj(f,'Tag','roibox'), 'Value');
  data = guidata(f);
  data.coords(cur_roi,:) = data.orig_coords(cur_roi,:);
  guidata(f,data);
  update_display(f);
end

function reset_coords(varargin)
  f=gcf;
  data = guidata(f);
  data.coords = data.orig_coords;
  guidata(f,data);
  update_display(f);
end

function update_display(f,all_ax)
   % rectantles
   data = guidata(f);
      
   if ~isfield(data,'rects'), data.rects={}; end
   
   % get current figure if not provided
   if nargin < 1
       f=gcf;
   end
   % axis if we didn't explicly give them
   if nargin < 2
       axes = arrayfun(@(x) strncmp(x.Tag,'ax',2), f.Children);
       all_ax = f.Children(axes);
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
   if(~isempty(cur_roi)), colors(cur_roi,:) = 1; end
   
   % update all axial
   for ax_i = 1:numel(all_ax)
       set(f,'CurrentAxes',all_ax(ax_i));
       if isempty(cur_roi) || ~data.z_free
           show_rois = 1:nroi;
       else
           roi_z = data.coords(cur_roi,4);
           show_rois = find( abs(data.coords(:,4) - roi_z) < 10 );
           
          
           a = all_ax(ax_i);
           zpos=roi_z -5 + 5*(ax_i-1);
           im_at_coords = flipud(rot90(data.nii.img(:,:,zpos)));
           update_brain(a, im_at_coords);
           update_callback(a, 1, [1 2], roibox);
           text(a,10,10,sprintf('Right; z=%d',zpos) ,'Color','White')

       end
       
       data.rects{ax_i} = arrayfun(@(i) rectangle(...
                  'Position', [data.coords(i,2)-4.5,...
                               data.coords(i,3)-4.5,...
                               9,...
                               9], ...
                  'EdgeColor', colors(i,:), ...
                  'LineWidth', 1,...
                   'HitTest', 'off'), ...
                 show_rois,'Un',0);
   end
   
   % update sag
   s = findobj(f,'Tag','sag');
   if(~isempty(s) && ~isempty(cur_roi))
       roi_x = data.coords(cur_roi,2);
       % update sag view       
       im_at_coords = fliplr(rot90(squeeze(data.nii.img(roi_x,:,:)),3));
       update_brain(s, im_at_coords)
       update_callback(s, data.z_free, [2 3], roibox);
       text(s,10,10,sprintf('x=%d',roi_x) ,'Color','White')

       % draw boxes for rois in range
       show_rois = find( abs(data.coords(:,2) - roi_x) < 10 );
       set(f,'CurrentAxes',s);
       data.rects{numel(all_ax)+1} = ...
           arrayfun(@(i) rectangle(...
                  'Position', [data.coords(i,3)-5, data.coords(i,4) - 5,...
                               9,                  10], ...
                  'EdgeColor', colors(i,:), ...
                  'LineWidth', 1,...
                   'HitTest', 'off'), ...
                 show_rois, 'Un',0);
             
         
   end
   
   % corronal
   c = findobj(f,'Tag','cor');
   if(~isempty(c) && ~isempty(cur_roi))
       roi_y = data.coords(cur_roi,3);
       % update sag view
       im_at_coords = fliplr(rot90(squeeze(data.nii.img(:,roi_y,:)),3));
       update_brain(c, im_at_coords);
       update_callback(c, data.z_free, [1 3], roibox);
       text(c,10,10,sprintf('y=%d',roi_y) ,'Color','White');

       % draw boxes for rois in range
       show_rois = find( abs(data.coords(:,3) - roi_y) < 10 );
       set(f,'CurrentAxes',c);
       data.rects{numel(all_ax)+1} = ...
           arrayfun(@(i) rectangle(...
                  'Position', [data.coords(i,2)-5, data.coords(i,4) - 5,...
                               9,                  10], ...
                  'EdgeColor', colors(i,:), ...
                  'LineWidth', 1,...
                   'HitTest', 'off'), ...
                 show_rois, 'Un',0);
   end
   
   % update text
   t = findobj(f,'Tag','disp_current');
   if(~isempty(t))
     t.String = sprintf('%d %d %d\n', data.coords');
   end
   
   % put rects backinto gui data
   guidata(f,data)
end

% things to do when reploting an axis
function ax = make_axl_axis(x, y, z, tag, funcs)
  ax   = funcs.mk_ax(x, y);
  p = funcs.mk_brain(ax, z);
  % flipud(rot90(nii.img(:,:,z)))
  set(p,'HitTest', 'off');
  set(ax,'YDir','normal');
  set(ax,'Tag',tag);
  text(ax,10,10,'Right','Color','White')

  %set(ax,'HitTest','off')
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