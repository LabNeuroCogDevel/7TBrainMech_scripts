function [erpsMapsByTrialByROIs,erpsByROIs, meanERPSMap, R, Pboot, Rboot, ERP, freqs, timesout, mbase, maskersp, maskitc, g,PboottrialsByROI] = plot_ERPS_by_ROI_2(patientROI,EEG,tlimits,cycles,frequencyRange,alpha,fdrCorrect,titleName,weightedSignificance,surroundingsWeight,scale,baseline,basenorm,erpsMax,marktimes)

erpsByROIs = [];
PboottrialsByROI = [];

for i = 1 : size(patientROI,2)
    plotTitleName = [titleName ' - ' patientROI(i).name];
    channels = patientROI(i).channels;
    [erpsMapsByTrial meanERPSMap, R, Pboot, Rboot, ERP, freqs, timesout, mbase, maskersp, maskitc, g,Pboottrials] = plot_ERPS_map_2(EEG,channels,tlimits,cycles,frequencyRange,alpha,fdrCorrect,plotTitleName,weightedSignificance,surroundingsWeight,scale,baseline,basenorm,erpsMax,marktimes);
                                                                                                                                                                                         
    erpsByROIs(i,:,:) = meanERPSMap;
    erpsMapsByTrialByROIs(i).erpsByTrial = erpsMapsByTrial;
    PboottrialsByROI(i).pboot = Pboottrials;
end

