function plot_erps_2_conditions_tiff(P_to_plot,mbase_to_plot,g,freqs,timesout,path_to_save,file_name_to_save,all_tfX)

hdl = m_newtimef_2_conditons_plotting(g,P_to_plot,[],[],[],mbase_to_plot,freqs,timesout,all_tfX);

%plot settings        
set(hdl,'color', 'none','units','pixels','position',[0,0,1421,356],'PaperUnits', 'centimeters','PaperSize',[37.59,9.42],'PaperPosition', [0 0 37.59 9.42])               
%[ inches | centimeters | normalized | points | {pixels} | characters ]

%save image
plot_name = fullfile(path_to_save,[file_name_to_save '.tif']);        
print(hdl,plot_name,'-dtiff','-r0')

%close figure
close(hdl)