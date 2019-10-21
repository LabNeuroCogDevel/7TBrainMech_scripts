function [erpsMapsByTrial, meanERPSMaps, R, Pboot, Rboot, ERP, freqs, timesout, mbase, maskersp, maskitc, g,Pboottrialsmean] = plot_ERPS_map_2(EEG,channels,tlimits,cycles,frequencyRange,alpha,fdrCorrect,titleName,weightedSignificance,surroundingsWeight,scale,baseline,basenorm,erpsMax,marktimes)

%channels must be a vector with the channels used to calculate the power
%spectrum
typeproc = 1; %deprecated - useless

erpsMaps = [];
erpsMapsByTrial = [];
Pboottrialstotal = []; 
counter = 0;
for num = channels
    counter = counter + 1;
    [P,R,mbase,timesout,freqs,Pboot,Rboot,alltfX,PA,ERP,maskersp, maskitc, g,Pboottrials] = my_pop_new_timef_2(EEG, typeproc, num, tlimits, cycles, frequencyRange,alpha,fdrCorrect,scale,baseline,basenorm,erpsMax,marktimes, 'plotitc' , 'off', 'plotphase', 'off', 'padratio', 1,'mcorrect','fdr');
                                                                                                                                                
    erpsMaps(:,:,counter) = P;
    if ~isempty(Pboottrials)
        Pboottrialstotal(:,:,counter) = Pboottrials;
    end
    erpsMapsByTrial = cat(3,erpsMapsByTrial,PA);
end

meanERPSMaps = mean(erpsMaps,3);
Pboottrialsmean = mean(Pboottrialstotal,3);

if weightedSignificance == 1
    exactp_ersp = mycompute_pvals(meanERPSMaps, Pboottrialsmean);
    significantMatrix = exactp_ersp;
    [weightedSignificantMatrixMask weightedSignificantMatrix] = calculate_weighted_significant_matrix(alpha,significantMatrix,surroundingsWeight);
    maskersp = weightedSignificantMatrixMask;
end
%ERP = zeros(1535,1);
my_plot_timef(titleName,squeeze(meanERPSMaps), R, Pboot, Rboot, ERP, freqs, timesout, mbase, maskersp, maskitc, g);

meanERPSMaps = squeeze(meanERPSMaps);