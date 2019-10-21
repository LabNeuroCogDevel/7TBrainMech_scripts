function [data] = w2_custom_erps_by_channel_EEG(condition_1,condition_2,cycles,freq_range,alpha,fdr,scale,basenorm,erps_max,prefix_to_save,data);

%-------DESCRIPTION---------------
%Calculates time frequency charts for every set in the specified directory.
%Sets are loaded, and filtered by the conditions completed. If only one condition is completed, 
%sets will be filtered by the input condition; if two conditions are completed, 
%sets will be filtered into two separate objects, their time frequency charts 
%and their difference will be calculated (condition_1 - condition_2); 
%if NO condition is loaded time frequency charts for the unfiltered set will be calculated.
%Sets' epoch types must be named as condition_1 and condition_2, if filtering is selected.
%Results are saved in .mats in the provided directory for the time frequency charts per
%channel and parameters per subject, and overall.
%IMPORANT: sets are assumed to have chanlocs loaded, and their marks
%contain condition_1 and condition_2 as a single string. This is relevant
%when several marks represent a condition, then the epoch types must be
%renamed to a unique string value of condition.
%INPUTS: 
%   * path_to_files: the sets' directory. 
%   * condition_1: string of the name of the first condition. Sets must
%           have epoch types named as this string. Optional.
%   * condition_2: string of the name of the second condition. Sets must
%           have epoch types names as this string. Optional.
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
%   * path_to_save: the directory where the plots and .mat with results are
%                   stored.
%OUTPUTS:
%   * time frequency charts per channel are saved in the specified
%       directory and .mat files per subject and overall are saved with the following results:
% (note: for subject files saved results are named as following with 's_'
% as prefix, and for two conditions each result is a cell with the results for condition1, 
% condition2 and the difference where necessary)
%            ersp   = the time frequency charts per subject (channel,freq,time,subjects) 
%                     matrix of log spectral diffs from baseline
%                     (in dB log scale or absolute scale). 
%            itc    = (channel,nfreqs,timesout,subjects) matrix of complex inter-trial coherencies.
%                     itc is complex -- ITC magnitude is abs(itc); ITC phase in radians
%                     is angle(itc), or in deg phase(itc)*180/pi.
%            mbases  = (channel,freqs,subjects) baseline power spectrum. Note that even, when selecting the 
%                     the 'trialbase' option, the average power spectrum is
%                     returned (not trial based). To obtain the baseline of
%                     each trial, recompute it manually using the tfdata
%                     output described below.
%            timesout  = vector of output times (spectral time window centers) (in ms).
%            freqs/freqsout  = vector of frequency bin centers (in Hz).
%            erspboot  = (nfreqs,2) matrix of [lower upper] ERSP significance.
%            itcboot  = (nfreqs) matrix of [upper] abs(itc) threshold.
%            tfX  = (subject) struct. Optional (nfreqs,timesout,trials) time/frequency decomposition 
%                      of the single data trials. Values are complex.
%           maskerps = (channel,nfreqs,timesout,subjects) mask for ersp charts (if alpha is set, if not empty)
%           maskitc = (channel,nfreqs,timesout,subjects) mask for ersp charts (if alpha is set, if not empty)
%           pa = (subject) struct. output of 'phsamp','on' - deprecated?
%           channel_labels = (channel nr, 1) channel labels
%           resdiff = (channels,freqs,timesout) difference array (of accumulated surrogate data) for the actual (non-shuffled) data, if more than one
%                       arg pair is called, format is a cell array of matrices.
%           g = struct with time frequency paramters
%----------------------------------

%-------PATH MANAGEMENT-----------
%----------------------------------

%modifies paths to include parent directory
path_to_files=data.path_to_files;
path_to_save=data.path_to_save;

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

for suj = 1 : file_nr
    file_name = filenames{suj};
    disp(path_to_files)
    disp(file_name)
    
    channel_labels = [];
    %4D matrix where results will be stored (channels, freq, times, subjects)    
    [c1_erps,c2_erps,c1_c2_erps] = deal([],[],[]);
    %5D matrix single trial results (channels,freq,times,epochs,subjects)
    [c1_tfX,c2_tfX] = deal([],[]);
    %4D matrix where statistical results will be stored (channels, freq,
    %times, subjects)
    [c1_erpsboot,c2_erpsboot,c1_c2_erpsboot] = deal([],[],[]);
    %2D matrix, where baseline powers are stored (base,subjects)
    [c1_mbases,c2_mbases,c1_c2_mbases] = deal([],[],[]);
    [c1_data,c2_data] = deal([],[]);
    [c1_itc,c2_itc,c1_c2_itc] = deal([],[],[]);
    [c1_itcboot,c2_itcboot,c1_c2_itcboot] = deal([],[],[]);
    [c1_maskersp,c2_maskersp] = deal([],[]);
    [c1_maskitc,c2_maskitc] = deal([],[]);
    [resdiff1,resdiff2] = deal([],[]);
    [c1_pa,c2_pa] = deal([],[]);
    
    %load set
    EEG = pop_loadset('filename',file_name,'filepath', path_to_files);
    ch_nr = length(EEG.chanlocs); %number of channel
    
    %load EEG according to condition selections
    two_conditions = 0;
    c2_EEG = [];
    if ~isempty(condition_1) && ~isempty(condition_2) %two conditions
        two_conditions = 1;
        c1_EEG = pop_selectevent( EEG, 'type', {condition_1} ,'deleteevents','off','deleteepochs','on','invertepochs','off');
        c2_EEG = pop_selectevent( EEG, 'type', {condition_2} ,'deleteevents','off','deleteepochs','on','invertepochs','off');        
    elseif isempty(condition_1) && isempty(condition_2) %no filtering by condition, one dataset
        c1_EEG = EEG;
        assert(isempty(strtrim(prefix_to_save)) == 0,'Error. If no conditions are loaded, a prefix MUST be defined to save results.');
    else    %only one condition filtering, one dataset
        if isempty(condition_1) && ~isempty(condition_2) %
            condition_1 = condition_2;
            condition_2 = '';
            c1_EEG = pop_selectevent( EEG, 'type', {condition_2} ,'deleteevents','off','deleteepochs','on','invertepochs','off');
        else
            c1_EEG = pop_selectevent( EEG, 'type', {condition_1} ,'deleteevents','off','deleteepochs','on','invertepochs','off');
        end
    end 
    
    %calculate point range 
    tlimits = [EEG.xmin, EEG.xmax]*1000;
    pointrange1 = round(max((tlimits(1)/1000-EEG.xmin)*EEG.srate, 1));
    pointrange2 = round(min((tlimits(2)/1000-EEG.xmin)*EEG.srate, EEG.pnts));
    pointrange = [pointrange1:pointrange2];
     
    for ch = 1 : 1  
    %for ch = 1 : ch_nr        
        chanlabel = EEG.chanlocs(ch).labels;   
        channel_labels{ch} = chanlabel;
        
        c1_tmpsig = c1_EEG.data(ch,pointrange,:);
        c1_tmpsig = reshape( c1_tmpsig, length(ch), size(c1_tmpsig,2)*size(c1_tmpsig,3));
        data_to_process = c1_tmpsig(:,:);
        
        if ~isempty(condition_2)
            c2_tmpsig = c2_EEG.data(ch,pointrange,:);
            c2_tmpsig = reshape( c2_tmpsig, length(ch), size(c2_tmpsig,2)*size(c2_tmpsig,3));
            data_to_process = {c1_tmpsig(:,:),c2_tmpsig(:,:)};
        end

        %calculate timefreq 
        %[P,R,mbase,timesout,freqs,Pboot,Rboot,alltfX,g] = newtimef_2_conditions( {c1_tmpsig(:, :),c2_tmpsig(:, :)}, length(pointrange), [tlimits(1) tlimits(2)], EEG.srate, cycles, 'plotersp','off', 'plotitc' , 'off','topovec', ch, 'elocs', EEG.chanlocs,'title',{condition_1 condition_2},'freqs',freq_range,'alpha',alpha,'mcorrect',fdr,'scale',scale,'basenorm',basenorm,'erspmax',erps_max, 'ntimesout', 400, 'padratio', 4,'baseline',[0],'caption',chanlabel) ;                        
        if two_conditions
            %[P,R,mbase,timesout,freqs,Pboot,Rboot,alltfX,g] = newtimef_2_conditions( data_to_process, length(pointrange), [tlimits(1) tlimits(2)], EEG.srate, cycles, 'plotersp','off', 'plotitc' , 'off','topovec', ch, 'elocs', EEG.chanlocs,'title',{condition_1 condition_2},'freqs',freq_range,'alpha',alpha,'mcorrect',fdr,'scale',scale,'basenorm',basenorm,'erspmax',erps_max, 'ntimesout', 400, 'padratio', 4,'baseline',[0],'caption',chanlabel) ; 
            [ERP,P,R,mbase,timesout,freqs,Pboot,Rboot,resdiff,alltfX,PA,maskersp,maskitc,g] = custom_newtimef(data_to_process, length(pointrange), tlimits, EEG.srate, cycles,[], 'plotersp','off', 'plotitc' , 'off','topovec', ch, 'elocs', EEG.chanlocs,'title',{condition_1 condition_2},'freqs',freq_range,'alpha',alpha,'mcorrect',fdr,'scale',scale,'basenorm',basenorm,'erspmax',erps_max, 'ntimesout', 400, 'padratio', 4,'baseline',[0],'caption',chanlabel);
        else
            %[P,R,mbase,timesout,freqs,Pboot,Rboot,alltfX,PA,g] = m_newtimef( data_to_process, length(pointrange), [tlimits(1) tlimits(2)], EEG.srate, cycles, 'plotersp','off', 'plotitc' , 'off','topovec', ch, 'elocs', EEG.chanlocs,'title',{condition_1 condition_2},'freqs',freq_range,'alpha',alpha,'mcorrect',fdr,'scale',scale,'basenorm',basenorm,'erspmax',erps_max, 'ntimesout', 400, 'padratio', 4,'baseline',[0],'caption',chanlabel) ;                        
            [ERP,P,R,mbase,timesout,freqs,Pboot,Rboot,resdiff,alltfX,PA,maskersp,maskitc,g] = custom_newtimef(data_to_process, length(pointrange), tlimits, EEG.srate, cycles,[], 'plotersp','off', 'plotitc' , 'off','topovec', ch, 'elocs', EEG.chanlocs,'title',condition_1,'freqs',freq_range,'alpha',alpha,'mcorrect',fdr,'scale',scale,'basenorm',basenorm,'erspmax',erps_max, 'ntimesout', 400, 'padratio', 4,'baseline',[0],'caption',chanlabel);
        end        
        
        %load results in matrices of overall results            
        if two_conditions
            c1_data(ch,:,suj) = ERP{1};
            c2_data(ch,:,suj) = ERP{2};
            c1_itc(ch,:,:,suj) = R{1}; 
            c2_itc(ch,:,:,suj) = R{2}; 
            c1_c2_itc(ch,:,:,suj) = R{3}; 
            c1_erps(ch,:,:,suj) = P{1};
            c2_erps(ch,:,:,suj) = P{2};
            c1_c2_erps(ch,:,:,suj) = P{3};

            if ~isnan(alpha)
                c1_erpsboot(ch,:,:,suj) = Pboot{1};
                c2_erpsboot(ch,:,:,suj) = Pboot{2};
                c1_c2_erpsboot(ch,:,:,:,suj) = Pboot{3};
                c1_itcboot(ch,:,suj) = Rboot{1};
                c2_itcboot(ch,:,suj) = Rboot{2};
                c1_c2_itcboot(ch,:,:,:,suj) = Rboot{3};
                c1_maskersp(ch,:,:,suj) = maskersp{1};
                c2_maskersp(ch,:,:,suj) = maskersp{2};
                c1_maskitc(ch,:,:,suj) = maskitc{1};
                c2_maskitc(ch,:,:,suj) = maskitc{2};
            end

            c1_tfX(ch,:,:,:) = alltfX{1};
            c2_tfX(ch,:,:,:) = alltfX{2};
            c1_mbases(ch,:,suj) = mbase{1};        
            c2_mbases(ch,:,suj) = mbase{2}; 
            c1_c2_mbases(ch,:,suj) = mbase{3};
            c1_pa(ch,:,:,:) = PA{1}; 
            c2_pa(ch,:,:,:) = PA{2}; 
            resdiff1(ch,:,:,suj) = resdiff{1}; 
            resdiff2(ch,:,:,suj) = resdiff{2};
        else
            c1_data(ch,:,suj) = ERP;
            c1_itc(ch,:,:,suj) = R; 
            c1_erps(ch,:,:,suj) = P;
            if ~isnan(alpha)
                c1_erpsboot(ch,:,:,suj) = Pboot;   
                c1_itcboot(ch,:,suj) = Rboot;
                c1_maskersp(ch,:,:,suj) = maskersp;
                c1_maskitc(ch,:,:,suj) = maskitc;
            end
            c1_tfX(ch,:,:,:) = alltfX;
            c1_mbases(ch,:,suj) = mbase;        
            c1_pa(ch,:,:,:) = PA; 
        end
    end
    
    %save data for suj
    [filepath,file_name_to_save,ext] = fileparts(file_name);

    prefix_file_name_to_save = [];
    if ~isempty(prefix_to_save)
        prefix_file_name_to_save = [prefix_to_save '_'];
    end
    if two_conditions
        mat_name = fullfile(path_to_save,[prefix_file_name_to_save  file_name_to_save '_' condition_1 '_' condition_2 '.mat']);
        s_data = {c1_data(:,:,suj),c2_data(:,:,suj)};
        s_erps = {c1_erps(:,:,:,suj),c2_erps(:,:,:,suj),c1_c2_erps(:,:,:,suj)};
        s_erpsboot = {c1_erpsboot(:,:,:,suj),c2_erpsboot(:,:,:,suj),c1_c2_erpsboot(:,:,:,suj)};
        s_itc = {c1_itc(:,:,suj),c2_itc(:,:,suj),c1_c2_itc(:,:,suj)};
        s_itcboot = {c1_itcboot(:,:,suj),c2_itcboot(:,:,suj),c1_c2_itcboot(:,:,suj)};
        s_tfX = {c1_tfX,c2_tfX};
        s_resdiff = {resdiff1(:,:,suj),resdiff2(:,:,suj)};
        s_mbases = {c1_mbases(:,:,suj),c2_mbases(:,:,suj),c1_c2_mbases(:,:,suj)};
        s_maskerps = {c1_maskersp(:,:,suj),c2_maskersp(:,:,suj)};
        s_maskitc = {c1_maskitc(:,:,suj), c2_maskitc(:,:,suj)};
        s_pa = {c1_pa,c2_pa};
        
        c1_alltfX(suj).tfX = c1_tfX;
        c2_alltfX(suj).tfX = c2_tfX;
        c1_allpa(suj).PA =  c1_pa;
        c2_allpa(suj).PA = c2_pa;
    else        
        if ~isempty(condition_1)
            mat_name = fullfile(path_to_save,[prefix_file_name_to_save file_name_to_save '_' condition_1 '.mat']);
        else
            mat_name = fullfile(path_to_save,[prefix_file_name_to_save file_name_to_save '.mat']);
        end
        s_resdiff = [];
        s_data = c1_data(:,:,suj);
        s_itc = c1_itc(:,:,suj);
        s_erps = c1_erps(:,:,:,suj);
        s_erpsboot = c1_erpsboot(:,:,:,suj);
        s_itcboot = c1_itcboot(:,:,suj);
        s_maskerps = c1_maskersp(:,:,suj);
        s_maskitc = c1_maskitc(:,:,suj);
        s_tfX = c1_tfX;
        s_mbases = c1_mbases(:,:,suj);    
        s_pa = c1_pa;
        
        c1_alltfX(suj).tfX = c1_tfX;
        c1_allpa(suj).PA =  c1_pa; 
    end

    save(mat_name, 's_erps','s_erpsboot','s_tfX','s_mbases','s_resdiff','s_data','s_itc','s_itcboot','s_maskerps','s_maskitc','s_pa','timesout','freqs','g','channel_labels');
    
    clear s_erps s_erpsboot s_tfX s_mbases s_resdiff s_data s_itc s_itcboot s_maskerps s_maskitc s_pa
end

%save results
if two_conditions
    erps = {c1_erps,c2_erps,c1_c2_erps};
    erpsboot = {c1_erpsboot,c2_erpsboot,c1_c2_erpsboot};
    itc = {c1_itc, c2_itc, c1_c2_itc}; 
    itcboot = {c1_itcboot,c2_itcboot,c1_c2_itcboot};
    resdiff = {resdiff1,resdiff2};
    mdata = {c1_data,c2_data};
    tfX = {c1_alltfX,c2_alltfX};
    pa = {c1_allpa,c2_allpa};
    mbases = {c1_mbases,c2_mbases,c1_c2_mbases};
    maskerps = {c1_maskersp,c2_maskersp};
    maskitc = {c1_maskitc,c2_maskitc};
    prefix_file_name_to_save = [prefix_file_name_to_save condition_1 '_' condition_2];
else
    erps = c1_erps;
    erpsboot = c1_erpsboot;
    mdata = c1_data;
    itc = c1_itc;
    itcboot = c1_itcboot;
    tfX = c1_alltfX;
    pa = c1_allpa;
    mbases = c1_mbases;
    resdiff = [];
    maskerps = c1_maskersp;
    maskitc = c1_maskitc;
    prefix_file_name_to_save = [prefix_file_name_to_save condition_1];
end

%save results in mat
mat_name = fullfile(path_to_save,[prefix_file_name_to_save '.mat']);
save(mat_name, 'erps','erpsboot','tfX','mbases','timesout','freqs','g','mdata','itc','itcboot','resdiff','maskerps','maskitc','pa','channel_labels');
