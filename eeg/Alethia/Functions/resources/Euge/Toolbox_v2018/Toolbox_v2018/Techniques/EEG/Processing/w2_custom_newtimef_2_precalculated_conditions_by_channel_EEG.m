function data = w2_custom_newtimef_2_precalculated_conditions_by_channel_EEG(path_to_c1,path_to_c2,condition1,condition2,path_to_save,EEG,data)
%Calculates time frequency difference for two conditions whose time
%frequency charts were calculated separately. 
%INPUT:
%   * path_to_files: directory where that files are stored.
%   * condition1_data: filename (.mat) with the time frequency results for
%           condition 1 calculated with w2_custom_erps_by_channel_EEG.m for one
%           condition only. 
%   * condition2_data: filename (.mat) with the time frequency results for
%           condition 2 calculated with w2_custom_erps_by_channel_EEG.m for one
%           condition only.
%   * path_to_save: directory where results for the time frequency
%           difference for two conditions will be stored.

%Note loading conditions' data files will load into workspace the following
%variables:
%([ERP,P,R,mbase,timesout,freqs,Pboot,Rboot,resdiff,alltfX,PA,maskersp,maskitc,g] -> outputs from w2_custom_erps_by_channel_EEG)
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

%-------PATH MANAGEMENT-----------
%----------------------------------
%add path of preprocessing 
% addpath(genpath(fullfile(data.ieeglab_path,'processing')));

%modifies paths to include parent directory

%check if path to files exist
%assert(exist(path_to_files, 'dir') == 7,['Directory not found! path_to_files: ' path_to_files '.']);

%create directory where the trimmed sets will be stored
if ~exist(path_to_save, 'dir')
  mkdir(path_to_save);
end

%-------LOAD PARAMETERS------------
%----------------------------------
%assert if files exist???!!!
cond1_file_name = path_to_c1;
assert(exist(cond1_file_name, 'file') == 2,['File not found! condition1_data: ' cond1_file_name '.']);

cond2_file_name = path_to_c2;
assert(exist(cond2_file_name, 'file') == 2,['File not found! condition2_data: ' cond2_file_name '.']);

%---------RUN---------------------
%---------------------------------
clear freqs
%load condition 1
c1 = load(cond1_file_name);
all_ERP1 = c1.mdata;
all_P1 = c1.erps;
all_R1 = c1.itc;
all_mbase1 = c1.mbases;
all_Pboot1 = c1.erpsboot;
all_Rboot1 = c1.itcboot;
channel_nr = length(c1.channel_labels);
channel_labels = c1.channel_labels;
assert(channel_nr == size(all_P1,1),'Error. Number of channel labels do not match calculated channel number.');
suj_nr = size(all_P1,4);
%resdiff -> should be empty, will be calculated in this function
all_tfX1 = c1.tfX; %aca seguro hay que hacer algo

all_PA1 = c1.pa; 
all_maskersp1 = c1.maskerps;
all_maskitc1 = c1.maskitc;
g1 = c1.g;
condition_1 = g1.title;

%load condition 2
c2 = load(cond2_file_name);
all_ERP2 = c2.mdata;
all_P2 = c2.erps;

assert(channel_nr == size(all_P2,1),'Error. Different channel number for conditions.');
assert(suj_nr == size(all_P2,4),'Error. Different subject number for conditions.');

all_R2 = c2.itc;
all_mbase2 = c2.mbases;
all_Pboot2 = c2.erpsboot;
all_Rboot2 = c2.itcboot;
%resdiff -> should be empty, will be calculated in this function
all_tfX2 = c2.tfX;

all_PA2 = c2.pa; 
all_maskersp2 = c2.maskerps;
all_maskitc2 = c2.maskitc;
g2 = c2.g;
condition_2 = g2.title;

%result matrices
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

%mean over sujbects by channel 
for ch = 1 : channel_nr
    suj.ERP1 = squeeze(mean(all_ERP1(ch,:,:),3));
    suj.ERP2 = squeeze(mean(all_ERP2(ch,:,:),3));
    suj.P1 = squeeze(mean(all_P1(ch,:,:,:),4));
    suj.P2 = squeeze(mean(all_P2(ch,:,:,:),4));
    suj.R1 = squeeze(mean(all_R1(ch,:,:,:),4));
    suj.R2 = squeeze(mean(all_R2(ch,:,:,:),4));
    suj.mbase1 = squeeze(mean(all_mbase1(ch,:,:),3));
    suj.mbase2 = squeeze(mean(all_mbase2(ch,:,:),3));
    suj.Pboot1 = squeeze(mean(all_Pboot1(ch,:,:,:),4));
    suj.Pboot2 = squeeze(mean(all_Pboot2(ch,:,:,:),4));
    suj.Rboot1 = squeeze(mean(all_Rboot1(ch,:,:),3));
    suj.Rboot2 = squeeze(mean(all_Rboot2(ch,:,:),3));

    for i = 1 : suj_nr
        temp_alltfX1(:,:,i) = squeeze(mean(all_tfX1(i).tfX(ch,:,:,:),4));
        temp_alltfX2(:,:,i) = squeeze(mean(all_tfX2(i).tfX(ch,:,:,:),4));
        temp_allpa1(:,:,i) = squeeze(mean(all_PA1(i).PA(ch,:,:,:),4));
        temp_allpa2(:,:,i) = squeeze(mean(all_PA2(i).PA(ch,:,:,:),4));
    end

    suj.alltfX1 = temp_alltfX1;
    suj.alltfX2 = temp_alltfX2;
    suj.PA1 = temp_allpa1;
    suj.PA2 = temp_allpa2;
    suj.maskersp1 = squeeze(mean(all_maskersp1(ch,:,:,:),4));
    suj.maskersp2 = squeeze(mean(all_maskersp2(ch,:,:,:),4));
    suj.maskitc1 = squeeze(mean(all_maskitc1(ch,:,:,:),4));
    suj.maskitc2 = squeeze(mean(all_maskitc2(ch,:,:,:),4));
    
    suj.timesout = c1.timesout;
    suj.freqs = c1.freqs;
    c1.g.caption = c1.channel_labels(ch);
    c1.g.title = {condition_1,condition_2};
    suj.g = c1.g; %set other conditions such as alpha and fdr, for example, before calling precalculated function

    [ERP,P,R,mbase,timesout,freqs,Pboot,Rboot,resdiff,alltfX,PA,maskersp,maskitc,g] = custom_newtimef_2_precalculated_conditions(suj);
    
    %load in results matrix
    c1_data(ch,:) = ERP{1};
    c2_data(ch,:) = ERP{2};
    c1_itc(ch,:,:) = R{1}; 
    c2_itc(ch,:,:) = R{2}; 
    c1_c2_itc(ch,:,:) = R{3}; 
    c1_erps(ch,:,:) = P{1};
    c2_erps(ch,:,:) = P{2};
    c1_c2_erps(ch,:,:) = P{3};

    if ~isnan(suj.g.alpha)
        c1_erpsboot(ch,:,:) = Pboot{1};
        c2_erpsboot(ch,:,:) = Pboot{2};
        c1_c2_erpsboot(ch,:,:,:) = Pboot{3};
        c1_itcboot(ch,:) = Rboot{1};
        c2_itcboot(ch,:) = Rboot{2};
        c1_c2_itcboot(ch,:,:,:) = Rboot{3};
        c1_maskersp(ch,:,:) = maskersp{1};
        c2_maskersp(ch,:,:) = maskersp{2};
        c1_maskitc(ch,:,:) = maskitc{1};
        c2_maskitc(ch,:,:) = maskitc{2};
    end

    c1_tfX(ch,:,:,:) = alltfX{1};
    c2_tfX(ch,:,:,:) = alltfX{2};
    c1_mbases(ch,:) = mbase{1};        
    c2_mbases(ch,:) = mbase{2}; 
    c1_c2_mbases(ch,:) = mbase{3};
    c1_pa(ch,:,:,:) = PA{1}; 
    c2_pa(ch,:,:,:) = PA{2}; 
    resdiff1(ch,:,:) = resdiff{1}; 
    resdiff2(ch,:,:) = resdiff{2};
end

%save results matrix
erps = {c1_erps,c2_erps,c1_c2_erps};
erpsboot = {c1_erpsboot,c2_erpsboot,c1_c2_erpsboot};
itc = {c1_itc, c2_itc, c1_c2_itc}; 
itcboot = {c1_itcboot,c2_itcboot,c1_c2_itcboot};
resdiff = {resdiff1,resdiff2};
mdata = {c1_data,c2_data};
tfX = {c1_tfX,c2_tfX};
pa = {c1_pa,c2_pa};
mbases = {c1_mbases,c2_mbases,c1_c2_mbases};
maskerps = {c1_maskersp,c2_maskersp};
maskitc = {c1_maskitc,c2_maskitc};
prefix_file_name_to_save = [condition_1 '_' condition_2];

mat_name = fullfile(path_to_save,[prefix_file_name_to_save '.mat']);
save(mat_name, 'erps','erpsboot','tfX','mbases','timesout','freqs','g','mdata','itc','itcboot','resdiff','maskerps','maskitc','pa','channel_labels');