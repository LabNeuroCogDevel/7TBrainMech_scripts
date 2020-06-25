
bins_to_plot = 3; 
condition = 'cueR';
channels_to_plot = 65; 

%Load in the original file from ICAWholeClean_Homogenize
OriginalFile = pop_loadset('/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Alethia/Prep/AfterWhole/ICAwholeClean_homogenize/10129_20180919_mgs_Rem_rerefwhole_ICA_icapru.set');


%Load in the eventfile with epoch names 
EEG = pop_importeegeventlist( EEG, '/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Alethia/Prep/eventList.txt' , 'ReplaceEventList', 'on' );


%Create bin based epochs. window: [0 2000ms]. none - no baseline correction done
EEG = pop_epochbin( EEG , [0.0  2000.0],  'none');


%Creates averaged ERPs. Including total power spectrum and evoked power spectrum 
ERP = pop_averager( ALLEEG , 'Criterion', 'good', 'DSindex',  3, 'ExcludeBoundary', 'on', 'SEM', 'on' );
ERP_TFFT = pop_averager( ALLEEG , 'Compute', 'TFFT', 'Criterion', 'good', 'DSindex',  3, 'ExcludeBoundary', 'on', 'SEM', 'on' );
ERP_EFFT = pop_averager( ALLEEG , 'Compute', 'EFFT','Criterion', 'good', 'DSindex',  3, 'ExcludeBoundary', 'on', 'SEM', 'on' );


%Creates bins for each epoch minus baseline (ISI). Takes the average of every channel in ISI and then subtracts that from every point in each channel in each epoch
ERP = pop_binoperator( ERP, {  'b8 =b2-mean(b1,2)',  'b9 = b3 - mean(b1,2)',  'b10 = b4 - mean(b1,2)',  'b11 = b5-mean(b1,2)',  'b12= b6-mean(b1,2)','b13 = b7-mean(b1,2)'});


%Creates another channel that is a combination of other channels. Creates ROI
ERP = pop_erpchanoperator( ERP, {  'ch65 = (ch5+ch6+ch7)/3 label = ROI Frontal'} , 'ErrorMsg', 'popup', 'KeepLocations',  0, 'Warning', 'on' );


%Plots the ERP for specified bins and channels
ERP_plot  = pop_ploterps( ERP,  bins_to_plot,  channels_to_plot , 'AutoYlim', 'on', 'Axsize', [ 0.05 0.08], 'BinNum', 'on', 'Blc', 'pre', 'Box', [ 1 1], 'ChLabel', 'on',...
 'FontSizeChan',  10, 'FontSizeLeg',  12, 'FontSizeTicks',  10, 'LegPos', 'bottom', 'Linespec', {'k-' }, 'LineWidth',  1, 'Maximize', 'on',...
 'Position', [ 103.714 29.6429 106.857 31.9286], 'Style', 'Classic', 'Tag', 'ERP_figure', 'Transparency',  0, 'xscale', [ 0.0 1993.0   0:400:1600 ],...
 'YDir', 'normal' );

save(['/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Alethia/Results/ERPs/ERP_data/FrontalROI' subjectID '_' condition '.mat'], '-struct', 'ERP_plot'); 

saveas(gcf, ['/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Alethia/Results/ERPs/ERP_Graphs/' subjectID '_' condition '_ERP.jpg']);