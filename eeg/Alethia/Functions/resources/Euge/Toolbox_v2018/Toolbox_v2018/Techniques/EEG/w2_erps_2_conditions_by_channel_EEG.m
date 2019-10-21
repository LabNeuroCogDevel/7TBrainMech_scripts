function [EEG, data] = w2_erps_2_conditions_by_channel_EEG(condition_1,condition_2,cycles,freq_range,alpha,fdr,scale,basenorm,erps_max,path_to_save,EEG,data)
%-------DESCRIPTION---------------
%Every set in the specified directory is loaded and separated into two EEG structs for each condition.
%Sets' epoch types must be named as conditions_1 and condition_2.
%Then time frequency charts are plotted for each condition and their
%difference (condition_1 - condition_2) in one graph. Plots are saved in
%the provided directory, as well as .mat with the time frequency charts per
%channel per subject.
%IMPORANT: sets are assumed to have chanlocs loaded, and their marks
%contain condition_1 and condition_2 as a single string. This is relevant
%when several marks represent a condition, then the epoch types must be
%renamed to a unique string value of condition.
%INPUTS: 
%   * condition_1: string of the name of the first condition. Sets must
%           have epoch types named as this string.
%   * condition_2: string of the name of the second condition. Sets must
%           have epoch types names as this string.
%   * cycles:       [real] indicates the number of cycles for the time-frequency 
%                        decomposition {default: 0}
%                     If 0, use FFTs and Hanning window tapering.  
%                     If [real positive scalar], the number of cycles in each Morlet 
%                        wavelet, held constant across frequencies.
%                     If [cycles cycles(2)] wavelet cycles increase with 
%                        frequency beginning at cycles(1) and, if cycles(2) > 1, 
%                        increasing to cycles(2) at the upper frequency,
%                      If cycles(2) = 0, use same window size for all frequencies 
%                        (similar to FFT when cycles(1) = 1)
%                      If cycles(2) = 1, cycles do not increase (same as giving
%                         only one value for 'cycles'). This corresponds to a pure
%                         wavelet decomposition, same number of cycles at each frequency.
%                      If 0 < cycles(2) < 1, cycles increase linearly with frequency:
%                         from 0 --> FFT (same window width at all frequencies) 
%                         to 1 --> wavelet (same number of cycles at all frequencies).
%                     The exact number of cycles in the highest frequency window is 
%                     indicated in the command line output. Typical value: 'cycles', [3 0.5]
%   * freq_range: [min max] frequency limits. 
%   * alpha:    If non-0, compute two-tailed permutation significance 
%                      probability level. Show non-signif. output values 
%                      as green.                              {default: 0}
%   * fdr:      ['none'|'fdr'] correction for multiple comparison
%                     'fdr' uses false detection rate (see function fdr()).
%                     Not available for condition comparisons.
%                     {default:'none'} 
%   * scale:    ['log'|'abs'] visualize power in log scale (dB) or absolute
%                     scale. {default: 'log'}
%   * basenorm: ['on'|'off'] 'on' normalize baseline in the power spectral
%                     average; else 'off', divide by the average power across 
%                     trials at each frequency (gain model). {default:
%                     'off'}
%   * erps_max: [real] set the ERSP max. For the color scale (min= -max)
%                       {auto}

%OUTPUTS:
%   * time frequency charts per channel are saved in the specified
%       directory and a .mat is saved with: 
%            ersp   = the time frequency charts per subject (channel,freq,time,subjects) 
%                     matrix of log spectral diffs from baseline
%                     (in dB log scale or absolute scale). 
%          powbase  = baseline power spectrum. Note that even, when selecting the 
%                     the 'trialbase' option, the average power spectrum is
%                     returned (not trial based). To obtain the baseline of
%                     each trial, recompute it manually using the tfdata
%                     output described below.
%            times  = vector of output times (spectral time window centers) (in ms).
%            freqs  = vector of frequency bin centers (in Hz).
%         erspboot  = (nfreqs,2) matrix of [lower upper] ERSP significance.
%          tfdata  = optional (nfreqs,timesout,trials) time/frequency decomposition 
%                      of the single data trials. Values are complex.
%----------------------------------

%-------PATH MANAGEMENT-----------
%----------------------------------
%add path of preprocessing 
%addpath(genpath(fullfile(data.ieeglab_path,'processing')));

%modifies paths to include parent directory
% path_to_files = fullfile(data.parent_directory, path_to_files);
% path_to_save = fullfile(data.parent_directory, path_to_save);

path_to_files=data.path_to_files;
% path_to_save=data.path_to_save;

%check if path to files exist
assert(exist(path_to_files, 'dir') == 7,['Directory not found! path_to_files: ' path_to_files '.']);

%create directory where the trimmed sets will be stored
if ~exist(path_to_save, 'dir')
  mkdir(path_to_save);
end

%-------LOAD PARAMETERS------------
%----------------------------------
cycles = str2num(cycles);
freq_range = str2num(freq_range);
alpha = str2num(alpha);
if alpha == 0
    alpha = NaN;
end
erps_max = str2num(erps_max);

%---------RUN---------------------
%---------------------------------

%load .set 
files = dir(fullfile(path_to_files,'*.set'));
filenames = {files.name}';  
file_nr = size(filenames,1);

    c1_erps = []; %4D matrix where results will be stored (channels, freq, times, subjects)
    c2_erps = [];
    c1_c2_erps = [];
    c1_erpsboot = []; %4D matrix where statistical results will be stored (channels, freq, times, subjects)
    c2_erpsboot = [];
    c1_c2_erpsboot = [];
    c1_mbases = []; %2D matrix, where baseline powers are stored (base,subjects)
    c2_mbases = [];

    sample_EEG = pop_loadset('filename',filenames{1},'filepath', path_to_files);
for suj = 1 : file_nr
    
    c1_tfX = [];
    c2_tfX = [];
    
    file_name = filenames{suj};
    disp(path_to_files)
    disp(file_name)

    %load set
    EEG = pop_loadset('filename',file_name,'filepath', path_to_files);
    ch_nr = length(EEG.chanlocs); %number of channels
    %condition 1 EEG
    c1_EEG = pop_selectevent( EEG, 'type', {condition_1} ,'deleteevents','off','deleteepochs','on','invertepochs','off');
    %condition 2 EEG
    c2_EEG = pop_selectevent( EEG, 'type', {condition_2} ,'deleteevents','off','deleteepochs','on','invertepochs','off');    
      
    tlimits = [EEG.xmin, EEG.xmax]*1000;
    pointrange1 = round(max((tlimits(1)/1000-EEG.xmin)*EEG.srate, 1));
    pointrange2 = round(min((tlimits(2)/1000-EEG.xmin)*EEG.srate, EEG.pnts));
    pointrange = [pointrange1:pointrange2];
        
    for ch = 1 : ch_nr        
        chanlabel = EEG.chanlocs(ch).labels;      
        
        c1_tmpsig = c1_EEG.data(ch,pointrange,:);
        c1_tmpsig = reshape( c1_tmpsig, length(ch), size(c1_tmpsig,2)*size(c1_tmpsig,3));
        c2_tmpsig = c2_EEG.data(ch,pointrange,:);
        c2_tmpsig = reshape( c2_tmpsig, length(ch), size(c2_tmpsig,2)*size(c2_tmpsig,3));

        %calculate timefreq for each condition and their subtraction
        %condition_1 - condition_2
        %NOTE: plotersp is set to off because of a bug generated while
        %using varargin in recursive calls, which becomes larger with each
        %call and the settings are not respected (several undesired plots were
        %generated)
        %plot
        [P,R,mbase,timesout,freqs,Pboot,Rboot,alltfX,g] = newtimef_2_conditions({c1_tmpsig(:, :),c2_tmpsig(:, :)}, length(pointrange), [tlimits(1) tlimits(2)], EEG.srate, cycles, 'plotersp','off', 'plotitc' , 'off','topovec', ch, 'elocs', EEG.chanlocs,'title',{condition_1 condition_2},'freqs',freq_range,'alpha',alpha,'mcorrect',fdr,'scale',scale,'basenorm',basenorm,'erspmax',erps_max, 'ntimesout', 400, 'padratio', 4,'baseline',[0],'caption',chanlabel) ;                        
        
        %load results in matrices of overall results    
        c1_erps(ch,:,:,suj) = P{1};
        c2_erps(ch,:,:,suj) = P{2};
        c1_c2_erps(ch,:,:,suj) = P{3};
                
        if ~isnan(alpha)
            c1_erpsboot(ch,:,:,suj) = Pboot{1};
            c2_erpsboot(ch,:,:,suj) = Pboot{2};
            c1_c2_erpsboot(ch,:,:,:,suj) = Pboot{3};
        end
            
         c1_tfX(ch,:,:,:) = alltfX{1}; %channel*freq*tiempo*epoch
         c2_tfX(ch,:,:,:) = alltfX{2};
         c1_mbases(ch,:,suj) = mbase{1}; %channel*freq*sujeto       
         c2_mbases(ch,:,suj) = mbase{2};                        
    end
    
    %save data for suj
    s_erps = {c1_erps(:,:,:,suj),c2_erps(:,:,:,suj),c1_c2_erps(:,:,:,suj)}; %channel*freq*tiempo
    if ~isnan(alpha)
        s_erpsboot = {c1_erpsboot(:,:,:,suj),c2_erpsboot(:,:,:,suj),c1_c2_erpsboot(:,:,:,suj)};
    else
        s_erpsboot = [];
    end
    s_tfX = {c1_tfX,c2_tfX};
    s_mbases = {c1_mbases(:,:,suj),c2_mbases(:,:,suj)};
    
    [filepath,file_name_to_save,ext] = fileparts(file_name);    
    mat_name = fullfile(path_to_save,[file_name_to_save '_' condition_1 '_' condition_2 '.mat']);
    save(mat_name, 's_erps','s_tfX','s_erpsboot','s_mbases','timesout','freqs','g');
    
    clear s_erps s_tfX s_erpsboot s_mbases 
    c1_alltfX(suj).tfX = c1_tfX; %array con N° elementos= cant de sujetos, cada elemento es de channel*freq*tiempo*epoch.
    c2_alltfX(suj).tfX = c2_tfX;
end

%save results
erps = {c1_erps,c2_erps,c1_c2_erps};
if ~isnan(alpha)
    erpsboot = {c1_erpsboot,c2_erpsboot,c1_c2_erpsboot};
else 
    erpsboot = [];
end

all_tfX = {c1_alltfX,c2_alltfX}; %la información de los alltfX están en all_tfX{1}(suj).tfX (hay "suj" elementos dentro de ese array, cada uno de los cuales es de channel*freq*tiempo*epoch
mbases = {c1_mbases,c2_mbases};

%save results in mat
prefix_file_name_to_save = [condition_1 '_' condition_2];
mat_name = fullfile(path_to_save,[prefix_file_name_to_save '.mat']);
save(mat_name, 'erps','erpsboot','all_tfX','mbases','timesout','freqs','g');

%plot -> TODO add conditional
plot_erps_2_conditions_by_channel(mat_name,sample_EEG,path_to_save,prefix_file_name_to_save)

% %calculate mean erps for all subjects, and mean baseline
% mean_base1 = mean(mbases{1},3);
% mean_base2 = mean(mbases{2},3);
% mean_P1 = mean(c1_erps,4);
% mean_P2 = mean(c2_erps,4);
% mean_P1_2 = mean(c1_c2_erps,4);
% mean_base = {mean_base1,mean_base2};
% P_all = {mean_P1, mean_P2,mean_P1_2};    
% 
% %plot------------------------------
% %for ch = 1 : 2
% for ch = 1 : ch_nr
%     disp(['About to plot ch' num2str(ch)])
%     chanlabel = EEG.chanlocs(ch).labels; 
%     P_to_plot = {squeeze(P_all{1}(ch,:,:)),squeeze(P_all{2}(ch,:,:)),squeeze(P_all{3}(ch,:,:))};
%     mbase_to_plot = {squeeze(mean_base{1}(ch,:,:)) squeeze(mean_base{2}(ch,:,:))};
%     g.topovec = ch; %index del valor a plotear
%     hdl = m_newtimef_2_conditons_plotting(g,P_to_plot,[],[],[],mbase_to_plot,freqs,timesout);
%     %plot settings        
%     set(hdl,'color', 'none','units','pixels','position',[0,0,1421,356],'PaperUnits', 'centimeters','PaperSize',[37.59,9.42],'PaperPosition', [0 0 37.59 9.42])               
%     %[ inches | centimeters | normalized | points | {pixels} | characters ]
% 
%     %save image
%     plot_name = fullfile(path_to_save,[chanlabel '_' condition_1 '-' condition_2 '.tif']);        
%     print(hdl,plot_name,'-dtiff','-r0')
% 
%     %close figure
%     close(hdl)
% end