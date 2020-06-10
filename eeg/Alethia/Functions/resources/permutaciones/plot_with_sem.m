

init=EEG.srate*base_time;

[y i_ind]=find(pvals(canal,:)<alpha);

color_code={'b',[1 0 0],[0 .5 0.1]};


data_guardar = {};
for k=1:size(cond,2)

    subplot(2,2,3:4)
    epoch_l=size(cond(k).data,2);
    srate_new=EEG.srate;
    t=[1:epoch_l]/srate_new-base_time;

    cond_avg=mean(cond(k).data(canal,:,:),3);
    max_cond(k)=max(cond_avg);
    min_cond(k)=min(cond_avg);
    cond_std=std(squeeze(cond(k).data(canal,:,:)),[],2)';
	mean_plus_error = cond_avg + (cond_std / sqrt(size(cond(k).data,3))); % no of epochs
	mean_min_error = cond_avg - (cond_std / sqrt(size(cond(k).data,3)));
    h(k) = plot(t,cond_avg, 'Color',color_code{k}, 'LineWidth', 1.5);
    hold on
    f_l=fill([t t(end:-1:1)],[mean_plus_error mean_min_error(end:-1:1)],color_code{k},'EdgeColor',color_code{k}); %shaded error bar
	set(f_l,'FaceAlpha',.1,'EdgeAlpha',.1)
    data_guardar{k}.mean = cond_avg;
    data_guardar{k}.desest = (cond_std / sqrt(size(cond(k).data,3)));
    data_guardar{k}.time = t;
%     [y,i_ind]= max(cond_avg(130:180));
    hold on;
    
end

if ~isempty(i_ind)

    plot(t(i_ind),max(max_cond)*1.1,'*', 'Color','k', 'MarkerSize', 5)

end
    
if size(h,2)==3

    legend([h(1) h(2) h(3)],{cond(1).name cond(2).name cond(3).name},'Location','NorthWest')

else
    
    if size(h,2)
        
        legend([h(1) h(2)],{cond(1).name cond(2).name },'Location','NorthWest')

    end
    
end

title([erp 'Channels: ' num2str(roi.chans)])

 line([0 0],ylim,'Color','k')
 line(xlim,[0 0],'Color','k')
 set(gca,'XTick',(-0.5:0.1:1.5))
 
   time=t;
  