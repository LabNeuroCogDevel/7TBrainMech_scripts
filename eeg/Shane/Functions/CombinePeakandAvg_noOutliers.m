

AvgPower = subjectID_include.Var2;
MeanAvgPower = mean(AvgPower, 2)';
T = table(subjectID_include.idvalues, MeanAvgPower');
T.Properties.VariableNames{1} = 'idvalues';
T.Properties.VariableNames{2} = 'MeanAvgPower';
writetable(T, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Gamma_Spectral_Analysis_Table_all_allevents_NoOutliers_AvgPower.csv'));


peakPower = subjectID_include.Var2;
MeanpeakPower = mean(peakPower, 2)';
Tpeak = table(subjectID_include.idvalues, MeanpeakPower');
Tpeak.Properties.VariableNames{1} = 'idvalues';
Tpeak.Properties.VariableNames{2} = 'MeanpeakPower';
writetable(Tpeak, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Gamma/Gamma_Spectral_Analysis_Table_all_allevents_NoOutliers_peakPower.csv'));


NumberofEvents = subjectID_include.Var2;
MeanEventNumber = mean(NumberofEvents, 2)';
T = table(subjectID_include.idvalues, MeanEventNumber');
T.Properties.VariableNames{1} = 'idvalues';
T.Properties.VariableNames{2} = 'MeanAvgEventNumber';
writetable(T, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Beta_Spectral_Analysis_Table_all_allevents_NoOutliers_NumberofEvents.csv'));

EventDuration = subjectID_include.Var2;
MeanEventDuration = mean(EventDuration, 2)';
T = table(subjectID_include.idvalues, MeanEventDuration');
T.Properties.VariableNames{1} = 'idvalues';
T.Properties.VariableNames{2} = 'MeanAvgEventDuration';
writetable(T, hera('Projects/7TBrainMech/scripts/eeg/Shane/Results/Power_Analysis/Spectral_events_analysis/Beta/Beta_Spectral_Analysis_Table_all_allevents_NoOutliers_MeanEventDuration.csv'));


