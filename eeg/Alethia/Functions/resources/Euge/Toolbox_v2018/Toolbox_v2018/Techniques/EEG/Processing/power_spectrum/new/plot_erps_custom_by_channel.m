function plot_erps_custom_by_channel(file_name,stats,path_to_save)

m = load(file_name);
channel_labels = m.channel_labels;
channel_nr = length(channel_labels);
P = mean(m.erps,4);
R = mean(m.itc,4);

freqs = m.freqs;
timesout = m.timesout;

g = m.g;

if strcmp(stats,'off') 
    g.alpha = nan;
else
    assert(~isnan(g.alpha),'Error. Stats ON incompatible with data providen.')
end

if ~isnan(g.alpha)
    Pboot = mean(m.erpsboot,4);
    Rboot = mean(m.itcboot,3);
    maskersp = mean(m.maskerps,4);
    maskitc = mean(m.maskitc,4);
else
    Pboot = [];
    Rboot = [];
    maskersp = [];
    maskitc = [];
end

ERP = mean(m.mdata,3);
mbases = mean(m.mbases,3);

if strcmp(stats,'off')
    g.alpha = nan;
end

for ch = 1 : channel_nr
    chanlabel = channel_labels{ch};
    P_to_plot = squeeze(P(ch,:,:));
    R_to_plot = squeeze(R(ch,:,:));
    
    if ~isnan(g.alpha)
        Pboot_to_plot = squeeze(Pboot(ch,:,:)); 
        Rboot_to_plot = squeeze(Rboot(ch,:)); 
        maskersp_to_plot = squeeze(maskersp(ch,:,:));   
        maskitc_to_plot = squeeze(maskitc(ch,:,:));
    else
        Pboot_to_plot = [];
        Rboot_to_plot = [];
        maskersp_to_plot = [];
        maskitc_to_plot = [];
    end
    ERP_to_plot = ERP(ch,:);
    mbase_to_plot = mbases(ch,:); 
    
    g.plotersp = 'on';
    hdl = custom_plottimef(P_to_plot, R_to_plot, Pboot_to_plot, Rboot_to_plot, ERP_to_plot, freqs, timesout, mbase_to_plot, maskersp_to_plot, maskitc_to_plot, g);
    
    %set(hdl,'color', 'none','units','pixels','position',[0,0,1421,356],'PaperUnits', 'centimeters','PaperSize',[37.59,9.42],'PaperPosition', [0 0 37.59 9.42])               
    %[ inches | centimeters | normalized | points | {pixels} | characters ]

    %save image
    plot_name = fullfile(path_to_save,[chanlabel '_' g.title '.tif']);        
    print(hdl,plot_name,'-dtiff','-r0')

    %close figure
    close(hdl)
end