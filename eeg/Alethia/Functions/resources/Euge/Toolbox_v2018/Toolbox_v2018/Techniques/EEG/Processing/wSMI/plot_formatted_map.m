function plot_formatted_map(map,labels,caxisValues,colorMap,titleName,newFileName,dosave)

%set diagonal values as Nan
map(logical(eye(size(map)))) = nan;

h = figure;

[nr,nc] = size(map);

%imagesc(map);
pcolor([map nan(nr,1); nan(1,nc+1)]);
shading flat;
set(gca,'ydir','reverse');

set(gca,'YTick',[1:size(labels,1)] );
set(gca,'YTickLabel',labels);      

set(gca,'XTick',[1:size(labels,1)] );
set(gca,'XTickLabel',labels);   

title(titleName)
if ~isempty(caxisValues)
    caxis(caxisValues)
end
axis square
colorbar

% str = ['colormap([0 0 0; ' colorMap '])'];
% eval(str)

rotate_x_labels(gca,90);
set(gca,'position',[0.07 0.125 0.8 0.8]);
if dosave == 1
    %display('do save ON')
    saveas(gcf,newFileName,'fig');
end
