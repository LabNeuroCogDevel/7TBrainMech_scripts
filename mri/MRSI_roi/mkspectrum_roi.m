function  [f, coords, coord_file]=mkspectrum_roi(f, offset, coord_file)
% MKSPECTRUM_ROI - populate SVR1H gui with 12 coordinates 
% run mkspectrum first to get the "f" variable (and setup for a lunaid)
if nargin < 1
   error('need figure handle. "ans" from mkspectrum')
end
if nargin < 2
   offset=0
end
if mod(offset,12) ~= 0, error('offset to should be a mulitple of 12, not %d', offset); end

if nargin < 3
     [fn, pth]= uigetfile({'coords_rearranged.txt'},'coords_rearranged.txt');
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
for i = (offset+1):(offset+12)
      if i - offset > 6
         lr='R';
      end
      if i > size(coords,1)
         x=0; y=0;
      else
         x = coords(i,1);
         y = coords(i,2);
      end

      lbl = sprintf('%s%d%s', lr, d.(lr),'Col');
      setobj(lbl, x);
      % and col      
      lbl = sprintf('%s%d%s', lr, d.(lr),'Row');
      setobj(lbl, y);
      
      % enable radio
      rdo = sprintf('%s%dOn', lr, d.(lr));
      if x == 0 && y == 0
          radval=0;
      else
          radval=1;
      end
      set(findobj(f,'Tag',rdo), 'Value',radval)
      
      d.(lr) = d.(lr) +1;
end

end
