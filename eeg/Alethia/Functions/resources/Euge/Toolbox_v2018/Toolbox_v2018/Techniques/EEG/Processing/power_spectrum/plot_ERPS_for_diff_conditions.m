function plot_ERPS_for_diff_conditions(erpsByROIsCond1,erpsByROIsCond2,file2SaveName,path2save,g,Pboot,ERP,mbase,freqs,timesout,roiStruct)    
%DIFF BETWEEN CONDITIONS:   erpsByROIsCond1 - erpsByROIsCond2;
    %g = gINT; -> asumo que ya está cargado
erpsDIFF = erpsByROIsCond1 - erpsByROIsCond2;
maskerspDIFF = [];
titleName = fullfile(path2save, file2SaveName);

baseln = [];
for index = 1:size(g.baseline,1)        
    tmptime   = find(timesout >= g.baseline(index,1) & timesout <= g.baseline(index,2));
    baseln = union(baseln, tmptime);
end;
g.alpha

for k = 1 : size(roiStruct,2)
    plotTitleName = [titleName '-' roiStruct(k).name];
    channels = roiStruct(k).channels;

    erpsDiff = squeeze(erpsDIFF(k,:,:));
    baselntmp = baseln;
    maskersp = [];

    if g.alpha ~= 0 & ~isnan(g.alpha)
        formula = 'mean(arg1,3);';            
        [ PbootDIFF PboottrialstmpDIFF PboottrialsDIFF] = bootstat(erpsDiff, formula, 'boottype', 'shuffle', ...
            'label', 'ERSP', 'bootside', 'both', 'naccu', g.naccu, ...
            'basevect', baselntmp, 'alpha', g.alpha, 'dimaccu', 2 );

        exactp_ersp = my_compute_pvals(erpsDiff, PboottrialsDIFF');

    %      if weightedSignificance == 1
    %         significantMatrix = exactp_ersp;
    %         [weightedSignificantMatrixMask weightedSignificantMatrix] = CalculateWeightedSignificantMatrix(alpha,significantMatrix,surroundingsWeight);
    %         maskersp = weightedSignificantMatrixMask;
    % 
    %      else
             maskersp = exactp_ersp <= g.alpha;
         %end
    end

     R = [];
     Rboot = [];
     maskitc = [];
     %mbase = 

    %plottimef(plotTitleName,erpsDIFF, R, Pboot, Rboot, ERP, freqs, timesout, mbase, maskersp, maskitc, g);
    my_plot_timef(plotTitleName,erpsDiff, R, Pboot, Rboot, ERP, freqs, timesout, mbase, maskersp, maskitc, g);
    str = ['save ' path2save  file2SaveName 'ERPSOutputsDIFF.mat erpsDiff Pboot ERP maskersp g'];
    eval(str);   
end

