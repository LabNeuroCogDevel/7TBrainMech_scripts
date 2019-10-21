function plot_erps_custom_2_mean_conditions_by_channel(file_name,stats,path_to_save)
%plots time frequency charts for 2 conditions 
%INPUTS:
% file_name: name of .mat file with w2_erps_2_conditions_by_channel_EEG
%           results
% sample_EEG: EEG with useful channel location and labels
% path_to_save

m = load(file_name);
P = m.erps;
R = m.itc;
Pboot = m.erpsboot;
Rboot = m.itcboot;
freqs = m.freqs;
timesout = m.timesout;
mbases = m.mbases;
mdata = m.mdata;
g = m.g;
maskerps = m.maskerps;
maskitc = m.maskitc;
resdiff = m.resdiff;
channel_labels = m.channel_labels;
%alltfX = tfX;

if strcmp(stats,'off')
    g.alpha = nan;
end

%loads the results of w2_erps_2_conditions_by_channel_EEG for all sujs
%with the following variables
%erps = {c1_erps,c2_erps,c1_c2_erps};
%erpsboot = {c1_erpsboot,c2_erpsboot,c1_c2_erpsboot};
%tfX = {c1_alltfX,c2_alltfX};
%mbases = {c1_mbases,c2_mbases};
%timesout
%freqs
%g

%plot------------------------------
for ch = 1 : length(channel_labels)
    disp(['About to plot ch' num2str(ch)])
    chanlabel = m.channel_labels{ch}; 
    g.topovec = ch; %index del valor a plotear
    g.plotersp = 'on';
    g.caption = chanlabel;
    
    mdata_to_plot = {squeeze(mdata{1}(ch,:)),squeeze(mdata{2}(ch,:))};
    P_to_plot = {squeeze(P{1}(ch,:,:)),squeeze(P{2}(ch,:,:)),squeeze(P{3}(ch,:,:))};
    R_to_plot = {squeeze(R{1}(ch,:,:)),squeeze(R{2}(ch,:,:)),squeeze(R{3}(ch,:,:))};
    mbase_to_plot = {squeeze(mbases{1}(ch,:)),squeeze(mbases{2}(ch,:)),squeeze(mbases{3}(ch,:))};
    if ~isnan(g.alpha)
        Pboot_to_plot = {squeeze(Pboot{1}(ch,:,:)),squeeze(Pboot{2}(ch,:,:)),squeeze(Pboot{3}(ch,:,:))}; 
        Rboot_to_plot = {squeeze(Rboot{1}(ch,:)),squeeze(Rboot{2}(ch,:)),squeeze(Rboot{3}(ch,:))}; 
        maskerps_to_plot = {squeeze(maskerps{1}(ch,:,:)),squeeze(maskerps{2}(ch,:,:))};
        maskitc_to_plot = {squeeze(maskitc{1}(ch,:,:)),squeeze(maskitc{2}(ch,:,:))};
    else
        Pboot_to_plot = {[],[],[]}; 
        Rboot_to_plot = {[],[],[]}; 
        maskerps_to_plot = {[],[]};
        maskitc_to_plot = {[],[]};
    end
    resdiff_to_plot = {squeeze(resdiff{1}(ch,:,:)),squeeze(resdiff{2}(ch,:,:))};
    hdl = custom_plottimef_2_conditions(g,mdata_to_plot,P_to_plot,R_to_plot,Pboot_to_plot,Rboot_to_plot,freqs, timesout,mbase_to_plot,maskerps_to_plot,maskitc_to_plot,resdiff_to_plot);
    set(hdl,'color', 'none','units','pixels','position',[0,0,1421,356],'PaperUnits', 'centimeters','PaperSize',[37.59,9.42],'PaperPosition', [0 0 37.59 9.42])               
    %[ inches | centimeters | normalized | points | {pixels} | characters ]

    %save image
    prefix_file_name_to_save = [g.title{1} '-' g.title{2}];
    plot_name = fullfile(path_to_save,[chanlabel '_' prefix_file_name_to_save '.tif']);        
    print(hdl,plot_name,'-dtiff','-r0')

    %close figure
    close(hdl)
end