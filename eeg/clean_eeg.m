function [EEG] = clean_eeg(EEGFile,channelMode,ProcessedDataLocation,runPREP,runICA)
%CLEAN_EEG run data through eeglab+PREP+SASICA


if nargin < 2, channelMode=128; end % 64 or 128
if nargin < 3, ProcessedDataLocation='./'; end % where data is saved to
if nargin < 4, runPREP = true; end % ICA PREP on by default
if nargin < 5, runICA = true; end % Independant Component Analysis on by default

%% setup
% get dir and name from input file
[RawDataLocation, EEGfileName, ext] = fileparts(EEGFile);

% append parts to pipeline
PREP_OUTNAME='PREP_HighPass_ICA.set'; 
SAS_OUTNAME='PREP_HighPass_ICA_SAS.set';

%check if the file/folder is a .bdf (biosemi) file
basicOutputFileName=EEGfileName; %remove the '.bdf' string
OutputFileName=sprintf('%s_%s',basicOutputFileName,PREP_OUTNAME); %write a basic output name string
SASICAOutputFileName=sprintf('%s_%s',basicOutputFileName,SAS_OUTNAME); %write a basic output name string
OutputFile=sprintf('%s%s',ProcessedDataLocation,OutputFileName); %write string for the full output directory and file

%if the output file doesn't exist then start processing
if exist(OutputFile, 'file')
    fprintf('Already have %s, loading\n', OutputFile);
    [RawDataLocation, setname] = fileparts(OutputFile);
    EEG=pop_loadset('filename',setname,'filepath',RawDataLocation);
    return
end

% test output folder, make if missing
if ~exist(ProcessedDataLocation,'dir'), mkdir(ProcessedDataLocation); end

% dipfit elp file used for preprocessing
BESAdir = fullfile(fileparts(which('eeglab')),'plugins','dipfit2.3','standard_BESA');
elp = fullfile(BESAdir, 'standard-10-5-cap385.elp');
if ~exist(elp,'file'), error('cannot read elp file %s', elp); end

%% run for bdf (raw) instead of .set
if any(regexp(ext,'bdf$'))
    %% Load .bdf file
    eeglab; %open eeglab ...opened and closed within loop to avoid memory issues
    %begin running preprocessing steps
    %create and dispaly a message in the Command Window
    fprintf('preprocessEEGdata: About to import %s for processing\n', EEGFile);
    %import bdf file into EEGLAB using the biosig package
    EEG = pop_biosig(EEGFile); %don't reference here as that will cause issues later (reference channels dissapear)
    EEG.setname=[EEGfileName ext]; %name the EEGLAB set (this is not the set file itself)
    eeglab redraw; %this makes the GUI reflect what the workspace variables are
    %edit channel locations and re-reference to mastoids
    EEG = eeg_checkset( EEG ); %this appears to be a function to check the consistency of the EEG variable in the workspace.  Unsure of its exact utility
    %depending on if we are doing 64 or 128 channel array...
    if(channelMode==64)
        EEG=pop_chanedit(EEG, 'lookup',elp, 'changefield',{67 'X' '-65.5'},'changefield',{67 'X' '80'},'changefield',{67 'Y' '46'},'changefield',{67 'Z' '-54'},'convert',{'cart2all'},'changefield',{68 'X' '80'},'changefield',{68 'Y' '-46'},'changefield',{68 'Z' '-54'},'convert',{'cart2all'},'changefield',{69 'X' '80'},'changefield',{69 'Y' '-26'},'changefield',{69 'Z' '-84'},'convert',{'cart2all'},'changefield',{70 'X' '80'},'changefield',{70 'Y' '-26'},'changefield',{70 'Z' '-24'},'convert',{'cart2all'},'changefield',{71 'X' '90'},'changefield',{71 'Y' '0'},'changefield',{71 'Z' '-54'},'convert',{'cart2all'},'changefield',{72 'X' '0'},'changefield',{72 'Y' '0'},'changefield',{72 'Z' '0'},'convert',{'cart2all'});
        % EEG = eeg_checkset( EEG );
        % EEG = pop_reref( EEG, [65 66] ); %does this "restore" the 40dB of "lost SNR" ? -was it actually lost? ...this is potentially undone by PREP
        % EEG = eeg_checkset( EEG );
        EEG = pop_select( EEG,'nochannel',{'EXG8' 'GSR1' 'GSR2' 'Erg1' 'Erg2' 'Resp' 'Plet' 'Temp'}); %delete unused channels
        EEG = eeg_checkset( EEG );
    elseif(channelMode==128)
        EEG = pop_chanedit(EEG, 'lookup',elp,'changefield',{62 'X' '-65.5'},'changefield',{62 'Y' '18.5'},'changefield',{62 'Z' '-23'},'convert',{'cart2all'},'changefield',{127 'X' '-65.5'},'changefield',{127 'Y' '-18.5'},'changefield',{127 'Z' '-23'},'convert',{'cart2all'},'changefield',{129 'X' '0'},'changefield',{129 'Y' '0'},'changefield',{129 'Z' '0'},'convert',{'cart2all'},'changefield',{130 'X' '0'},'changefield',{130 'Y' '0'},'changefield',{130 'Z' '0'},'convert',{'cart2all'},'changefield',{131 'X' '80'},'changefield',{131 'Y' '46'},'changefield',{131 'Z' '-54'},'convert',{'cart2all'},'changefield',{132 'X' '80'},'changefield',{132 'Y' '-46'},'changefield',{132 'Z' '-54'},'convert',{'cart2all'},'changefield',{133 'X' '80'},'changefield',{133 'Y' '-26'},'changefield',{133 'Z' '-84'},'convert',{'cart2all'},'changefield',{134 'X' '80'},'changefield',{134 'Y' '-26'},'changefield',{134 'Z' '-24'},'convert',{'cart2all'},'changefield',{135 'X' '90'},'changefield',{135 'Y' '0'},'changefield',{135 'Z' '-54'},'convert',{'cart2all'},'changefield',{136 'X' '0'},'changefield',{136 'Y' '0'},'changefield',{136 'Z' '0'},'convert',{'cart2all'},'changefield',{137 'X' '0'},'changefield',{137 'Y' '0'},'changefield',{137 'Z' '0'},'convert',{'cart2all'},'changefield',{138 'X' '0'},'changefield',{138 'Y' '0'},'changefield',{138 'Z' '0'},'convert',{'cart2all'},'changefield',{139 'X' '0'},'changefield',{139 'Y' '0'},'changefield',{139 'Z' '0'},'convert',{'cart2all'},'changefield',{140 'X' '0'},'changefield',{140 'Y' '0'},'changefield',{140 'Z' '0'},'convert',{'cart2all'},'changefield',{141 'X' '0'},'changefield',{141 'Y' '0'},'changefield',{141 'Z' '0'},'convert',{'cart2all'},'changefield',{142 'X' '0'},'changefield',{142 'Y' '0'},'changefield',{142 'Z' '0'},'convert',{'cart2all'},'changefield',{143 'X' '0'},'changefield',{143 'Y' '0'},'changefield',{143 'Z' '0'},'convert',{'cart2all'});
        EEG = eeg_checkset( EEG );
        EEG = pop_select( EEG,'nochannel',{'EXG8' 'GSR1' 'GSR2' 'Erg1' 'Erg2' 'Resp' 'Plet' 'Temp'}); %delete unused channels
        %re-referencing to the empty set [] means average reference,
        %[129 130] are the mastoid externals for the 128 electrode
        %array
        % EEG = pop_reref( EEG, [129 130] ); %does this "restore" the 40dB of "lost SNR" ? -was it actually lost? ...this is potentially undone by PREP
        % EEG = eeg_checkset( EEG );
    else
        disp('channelMode not supported! use 64 or 128');
        return %exit early because the user gave an invalid channelMode
    end
    eeglab redraw;
    EEG = pop_saveset( EEG, 'filename',basicOutputFileName,'filepath',ProcessedDataLocation); %essentially this creates a .set version of the .bdf file
    eeglab redraw;
elseif any(regexp(ext,'set$'))  %%load up the .set files instead
    %% Else load the .set file.  NOTE: User must create this set file from a bdf file
    setname = sprintf('%s.set',basicOutputFileName);
    display(setname);
    EEG = pop_loadset('filename',setname,'filepath',RawDataLocation);
    eeglab redraw;
else
    return;
end %end of IF is .bdf file (or else .set file)


%% Run plugins
if exist('EEG','var')==0
    error('no EEG variable!');
end

%% Run PREP
if(runPREP)
    PREPreportPDFpath=sprintf('%s%s.pdf',ProcessedDataLocation,basicOutputFileName);
    PREPreportHTMLpath=sprintf('%s%s.html',ProcessedDataLocation,basicOutputFileName);
    PREPoutputPath=sprintf('%s_PREP_HighPass.set',basicOutputFileName);
    
    if(channelMode==64) %what is 'samples',525312?
        referenceChannels = [1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16   17   18   19   20   21   22   23   24   25   26   27   28   29   30   31   32   33   34   35   36   37   38   39   40   41   42   43   44   45   46   47   48   49   50   51   52   53   54   55   56   57   58   59   60   61   62   63   64   65   66   67   68   69   70 ];
        EEG = pop_prepPipeline(EEG,struct('ignoreBoundaryEvents', true, 'detrendChannels', [1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16   17   18   19   20   21   22   23   24   25   26   27   28   29   30   31   32   33   34   35   36   37   38   39   40   41   42   43   44   45   46   47   48   49   50   51   52   53   54   55   56   57   58   59   60   61   62   63   64   65   66   67   68   69   70 ], 'detrendCutoff', 0.5, 'detrendStepSize', 0.02, 'detrendType', 'High Pass', 'lineNoiseChannels', [1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16   17   18   19   20   21   22   23   24   25   26   27   28   29   30   31   32   33   34   35   36   37   38   39   40   41   42   43   44   45   46   47   48   49   50   51   52   53   54   55   56   57   58   59   60   61   62   63   64   65   66   67   68   69   70 ], 'lineFrequencies', [60  120  180  240  300  360  420  480], 'Fs', 1024, 'p', 0.01, 'fScanBandWidth', 2, 'taperBandWidth', 2, 'taperWindowSize', 4, 'pad', 0, 'taperWindowStep', 1, 'fPassBand', [0  256], 'tau', 100, 'maximumIterations', 10, 'referenceChannels', referenceChannels, 'evaluationChannels', [1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16   17   18   19   20   21   22   23   24   25   26   27   28   29   30   31   32   33   34   35   36   37   38   39   40   41   42   43   44   45   46   47   48   49   50   51   52   53   54   55   56   57   58   59   60   61   62   63   64], 'rereferencedChannels', [1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16   17   18   19   20   21   22   23   24   25   26   27   28   29   30   31   32   33   34   35   36   37   38   39   40   41   42   43   44   45   46   47   48   49   50   51   52   53   54   55   56   57   58   59   60   61   62   63   64   65   66   67   68   69   70], 'ransacOff', false, 'ransacSampleSize', 50, 'ransacChannelFraction', 0.25, 'ransacCorrelationThreshold', 0.75, 'ransacUnbrokenTime', 0.4, 'ransacWindowSeconds', 5, 'srate', 1024, 'robustDeviationThreshold', 5, 'correlationWindowSeconds', 1, 'highFrequencyNoiseThreshold', 5, 'correlationThreshold', 0.4, 'badTimeThreshold', 0.01, 'maxReferenceIterations', 4, 'referenceType', 'Robust', 'reportingLevel', 'Verbose', 'interpolationOrder', 'Post-reference', 'meanEstimateType', 'Median', 'samples', 525312, 'reportMode', 'normal', 'publishOn', true, 'sessionFilePath', PREPreportPDFpath, 'summaryFilePath', PREPreportHTMLpath, 'consoleFID', 1, 'cleanupReference', false, 'keepFiltered', true, 'removeInterpolatedChannels', false));
        
    elseif(channelMode==128)
        %referenceChannels = [129 130]; %mastoids (externals 1 & 2)
        referenceChannels = [1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16   17   18   19   20   21   22   23   24   25   26   27   28   29   30   31   32   33   34   35   36   37   38   39   40   41   42   43   44   45   46   47   48   49   50   51   52   53   54   55   56   57   58   59   60   61   62   63   64   65   66   67   68   69   70   71   72   73   74   75   76   77   78   79   80   81   82   83   84   85   86   87   88   89   90   91   92   93   94   95   96   97   98   99  100  101  102  103  104  105  106  107  108  109  110  111  112  113  114  115  116  117  118  119  120  121  122  123  124  125  126  127  128  129  130  131  132  133  134  135 ];
        EEG = pop_prepPipeline(EEG,struct('ignoreBoundaryEvents', true, 'detrendChannels', [1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16   17   18   19   20   21   22   23   24   25   26   27   28   29   30   31   32   33   34   35   36   37   38   39   40   41   42   43   44   45   46   47   48   49   50   51   52   53   54   55   56   57   58   59   60   61   62   63   64   65   66   67   68   69   70   71   72   73   74   75   76   77   78   79   80   81   82   83   84   85   86   87   88   89   90   91   92   93   94   95   96   97   98   99  100  101  102  103  104  105  106  107  108  109  110  111  112  113  114  115  116  117  118  119  120  121  122  123  124  125  126  127  128  129  130  131  132  133 ], 'detrendCutoff', 0.5, 'detrendStepSize', 0.02, 'detrendType', 'High Pass', 'lineNoiseChannels', [1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16   17   18   19   20   21   22   23   24   25   26   27   28   29   30   31   32   33   34   35   36   37   38   39   40   41   42   43   44   45   46   47   48   49   50   51   52   53   54   55   56   57   58   59   60   61   62   63   64   65   66   67   68   69   70   71   72   73   74   75   76   77   78   79   80   81   82   83   84   85   86   87   88   89   90   91   92   93   94   95   96   97   98   99  100  101  102  103  104  105  106  107  108  109  110  111  112  113  114  115  116  117  118  119  120  121  122  123  124  125  126  127  128  129  130  131  132  133], 'lineFrequencies', [60  120  180  240  300  360  420  480], 'Fs', 1024, 'p', 0.01, 'fScanBandWidth', 2, 'taperBandWidth', 2, 'taperWindowSize', 4, 'pad', 0, 'taperWindowStep', 1, 'fPassBand', [0  512], 'tau', 100, 'maximumIterations', 10, 'referenceChannels', referenceChannels, 'evaluationChannels', [1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16   17   18   19   20   21   22   23   24   25   26   27   28   29   30   31   32   33   34   35   36   37   38   39   40   41   42   43   44   45   46   47   48   49   50   51   52   53   54   55   56   57   58   59   60   61   62   63   64   65   66   67   68   69   70   71   72   73   74   75   76   77   78   79   80   81   82   83   84   85   86   87   88   89   90   91   92   93   94   95   96   97   98   99  100  101  102  103  104  105  106  107  108  109  110  111  112  113  114  115  116  117  118  119  120  121  122  123  124  125  126  127  128], 'rereferencedChannels', [1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16   17   18   19   20   21   22   23   24   25   26   27   28   29   30   31   32   33   34   35   36   37   38   39   40   41   42   43   44   45   46   47   48   49   50   51   52   53   54   55   56   57   58   59   60   61   62   63   64   65   66   67   68   69   70   71   72   73   74   75   76   77   78   79   80   81   82   83   84   85   86   87   88   89   90   91   92   93   94   95   96   97   98   99  100  101  102  103  104  105  106  107  108  109  110  111  112  113  114  115  116  117  118  119  120  121  122  123  124  125  126  127  128  129  130  131  132 ], 'ransacOff', false, 'ransacSampleSize', 50, 'ransacChannelFraction', 0.25, 'ransacCorrelationThreshold', 0.75, 'ransacUnbrokenTime', 0.4, 'ransacWindowSeconds', 5, 'srate', 1024, 'robustDeviationThreshold', 5, 'correlationWindowSeconds', 1, 'highFrequencyNoiseThreshold', 5, 'correlationThreshold', 0.4, 'badTimeThreshold', 0.01, 'maxReferenceIterations', 4, 'referenceType', 'Robust', 'reportingLevel', 'Verbose', 'interpolationOrder', 'Post-reference', 'meanEstimateType', 'Median', 'samples', 525312, 'reportMode', 'normal', 'publishOn', true, 'sessionFilePath', PREPreportPDFpath, 'summaryFilePath', PREPreportHTMLpath, 'consoleFID', 1, 'cleanupReference', false, 'keepFiltered', true, 'removeInterpolatedChannels', false));
        %EEG = pop_prepPipeline(EEG,struct('ignoreBoundaryEvents', true, 'detrendChannels', referenceChannels, 'detrendCutoff', 0.4, 'detrendStepSize', 0.02, 'detrendType', 'High Pass', 'lineNoiseChannels', referenceChannels, 'lineFrequencies', [60  120  180  240  300  360  420  480], 'Fs', 1024, 'p', 0.01, 'fScanBandWidth', 2, 'taperBandWidth', 2, 'taperWindowSize', 4, 'pad', 0, 'taperWindowStep', 1, 'fPassBand', [0  512], 'tau', 100, 'maximumIterations', 10, 'referenceChannels', referenceChannels, 'evaluationChannels', referenceChannels, 'rereferencedChannels', referenceChannels, 'ransacOff', false, 'ransacSampleSize', 50, 'ransacChannelFraction', 0.25, 'ransacCorrelationThreshold', 0.75, 'ransacUnbrokenTime', 0.4, 'ransacWindowSeconds', 5, 'srate', 1024, 'robustDeviationThreshold', 5, 'correlationWindowSeconds', 1, 'highFrequencyNoiseThreshold', 5, 'correlationThreshold', 0.4, 'badTimeThreshold', 0.01, 'maxReferenceIterations', 4, 'referenceType', 'Robust', 'reportingLevel', 'Verbose', 'interpolationOrder', 'Post-reference', 'meanEstimateType', 'Median', 'samples', 525312, 'reportMode', 'normal', 'publishOn', true, 'sessionFilePath', PREPreportPDFpath, 'summaryFilePath', PREPreportHTMLpath, 'consoleFID', 1, 'cleanupReference', false, 'keepFiltered', true, 'removeInterpolatedChannels', false));
        
    end
    eeglab redraw;
    EEG = pop_saveset( EEG, 'filename',PREPoutputPath,'filepath',ProcessedDataLocation); %save PREP preprocessed output
    eeglab redraw;
    
end

%% run ICA
if(runICA)
    if ~exist('interpolatedChannels','var')
        warning('No interpolatedChannels variable!, setting to empty');
        interpolatedChannels=[];
    end
    numInterpChan=numel(interpolatedChannels); %find the number of channels that PREP has interpolated
    %note: this interpolatedChannels will not exist if PREP was not
    %run.
    numExternals=7; %set number of externals
    newRank = EEG.nbchan - numExternals - numInterpChan; %subtract the NumberInterpolatedChannels and Externals from total EEG channels
    EEG = pop_runica(EEG, 'extended',1,'stop',1e-07,'interupt','on','pca',newRank);
    EEG = eeg_checkset( EEG );
    %EEG = pop_runica(EEG, 'extended',1,'stop',1e-07,'interupt','on'); %run ICA
    EEG = pop_saveset( EEG, 'filename',OutputFileName,'filepath',ProcessedDataLocation); %save final preprocessed output
    
    %% SASICA Command
    
    %Then the user would pull up ICA'd results, and run SAS:
    EEG = eeg_SASICA(EEG,'MARA_enable',0,'FASTER_enable',1,'FASTER_blinkchanname','EXG5 EXG6','ADJUST_enable',1,'chancorr_enable',1,'chancorr_channames','No channel','chancorr_corthresh','auto 4','EOGcorr_enable',0,'EOGcorr_Heogchannames','No channel','EOGcorr_corthreshH','auto 4','EOGcorr_Veogchannames','No channel','EOGcorr_corthreshV','auto 4','resvar_enable',0,'resvar_thresh',15,'SNR_enable',1,'SNR_snrcut',1,'SNR_snrBL',[-Inf 0] ,'SNR_snrPOI',[0 Inf] ,'trialfoc_enable',0,'trialfoc_focaltrialout','auto','focalcomp_enable',1,'focalcomp_focalICAout','auto','autocorr_enable',1,'autocorr_autocorrint',20,'autocorr_dropautocorr','auto','opts_noplot',0,'opts_nocompute',0,'opts_FontSize',14);
    EEG = pop_saveset( EEG, 'filename',SASICAOutputFileName,'filepath',ProcessedDataLocation); %save final preprocessed output
    
end

disp('Finished');

end

