function  [f, coords, coord_file]=mkspectrum_roi(f, offset, coord_file)
% MKSPECTRUM_ROI - populate SVR1H gui with 12 coordinates 
% run mkspectrum first to get the "f" variable (and setup for a lunaid)
% coord_rearrange.txt from
%  mni_examples/warps/1*_2*/*_scout_cm_*_MP_for_mni.txt/coords_rearranged.txt
if nargin < 1
   error('need figure handle. "ans" from mkspectrum')
end
if nargin < 2
   offset=0
   fprintf('using offset 0; rerun again like ')
   fprintf('  mkspectrum_roi(f,12,coord_file)\n')
end
if mod(offset,12) ~= 0, error('offset to should be a mulitple of 12, not %d', offset); end

% 20200220 - coord fliles now look like
% /Volumes/Hera/Projects/7TBrainMech/subjs/10129_20180917/slice_PFC/MRSI_roi/13MP20200207/MP/coords_rearranged.txt
if nargin < 3
     [fn, pth]= uigetfile({'coords_rearranged.txt'},...
                          'Find in subj/slice*/MRSI_roi/13*/');
     coord_file = fullfile(pth,fn);
end


coords = load(coord_file);

if size(coords,2) ~= 4, error('bad file, not 4 columns! %s', coords_file); end

% function to set string of tag
setobj = @(x,y) set(findobj(f,'Tag',x),'String',y);

% coord_rearrange.txt:
% x y z roinum
% 68 65 50 1
% 149 66 50 2

d.L = 1;  d.R = 1; % intialize left and right count
lr = 'L';
% what coluns are x and y values
xi=1; yi=2;

% 20200220 -- we have 13 rois!
% if max(coords(:,1)) <= 24
%    warnings('not using warp/*/*/coords_rearranged.txt')
%    xi=2; yi=3;
% end

for i = (offset+1):(offset+12)
      % gui requires left and right
      % but we dont care. make the first 6 L, next 6 R
      if i - offset > 6
         lr='R';
      end
      % zero out if we've gone past what we have
      if i > size(coords,1)
         x=0; y=0;
      else
         x = coords(i,xi);
         y = coords(i,yi);
      end

      %% find label based on roi, L/R, and Col/Row
      %  and set to aprop. coord value
      lbl = sprintf('%s%d%s', lr, d.(lr),'Col');
      setobj(lbl, x);
      % and col      
      lbl = sprintf('%s%d%s', lr, d.(lr),'Row');
      setobj(lbl, y);
      
      %% enable radio
      rdo = sprintf('%s%dOn', lr, d.(lr));
      if x == 0 && y == 0
          radval=0;
      else
          radval=1;
      end
      set(findobj(f,'Tag',rdo), 'Value',radval)
      
      % inc l/r count (should switch when > 6)
      d.(lr) = d.(lr) +1;
end

end
