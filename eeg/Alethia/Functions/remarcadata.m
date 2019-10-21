function [EEG] = remarcadata(path_file,outputpath)
eeglab
%directory of EEG data
[path,folder] = fileparts(path_file);
d =[path,'/',folder,'/'];
% d ='/Users/macbookpro/Documents/MBCS/BA/DMT_experiment/drive-download-20190719T191352Z-001/';
% names = dir([d,'*mgs.bdf']);

namesOri = dir([d,'*.bdf']);
nameslist = {namesOri.name}.';

names = namesOri(find (cellfun (@any,regexpi (nameslist, 'mgs'))));

% names = dir([d,'*eyecal.bdf']);

names = {names(~[names.isdir]).name}; %cell array with EEG file names
nr_eegsets = size(names,2); %number of EEG sets to preprocess

for idx = 1:nr_eegsets
    
    currentName = names{idx}(1:end-4);
    
    %to know how far your script is with running
    disp(currentName)
    
    %load EEG set
%     EEG = pop_biosig([d currentName '.bdf'],'ref',[65 66] );
    EEG = pop_biosig([d currentName '.bdf']);
    EEG.setname=[currentName 'Rem']; %name the EEGLAB set (this is not the set file itself)

    eeglab redraw
    
      [micromed_time,mark]=make_photodiodevector(EEG);
%     plot([micromed_time;micromed_time],[-100;0],'r')
%     figure(5);plot(micromed_time ,mark ,'r*')
    
    %%
    mark = mark - min(mark);
    mark(mark>65000) = 0;
    % isi (150+x) and iti (254) are different
    %    event inc in 50: (50-200: cue=50,img=100,isi=150,mgs=200)
    %    category inc in 10 (10->30: None,Outdoor,Indoor)
    %    side inc in 1 (1->4: Left -> Right)
    %        61 == cue:None,Left
    %        234 == mgs:Indoor,Right
    %1 254 = ITI
    %2 50<cue<100 [50+(c 10,20,30)+(s,1-4)]
    %3 100<img.dot<150 [100+(c 10,20,30)+(s,1-4)] +/-
    %4 150<delay<200 [150+(c 10,20,30)]
    %5 200<mgs<250 [200+(c 10,20,30)+(s,1-4)]
    
    ending = mod(mark',10);
    

    simple = nan(size(mark));
    simple(mark == 254)= 1;
    simple(mark>=50 & mark<100)= 2;
    % simple mark(mark>=100 & mark<150)= 3;
    simple(mark>=100 & mark<150 & ((ending == 1) + (ending == 2))')= -3;
    simple(mark>=100 & mark<150 & ((ending == 3) + (ending == 4))')= 3;
    
    simple(mark>=150 & mark<200)= 4;
    simple(mark>=200 & mark<250 & ((ending == 1) + (ending == 2))')= -5;
    simple(mark>=200 & mark<250 & ((ending == 3) + (ending == 4))')= 5;
    
%     figure(8);plot(micromed_time ,simple ,'r*')
    
    % cond = {'newbloque','ITI','cue','dot.ima'(L/R),'delay','mgs'(L/R)};
    for i=unique(simple)
        mmark=find(simple==i);
        if ~isempty(mmark)
            for j = 1:length(mmark)
                %             EEG.event(mmark).type = cond{i+1};
                EEG = pop_editeventvals(EEG,'changefield',{mmark(j) 'type' i});
            end
        end
    end
    %% GUARDO EL DATASET

EEG = pop_saveset( EEG, 'filename',[currentName '_Rem.set'],'filepath',outputpath);
% [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

end
clear all 
close all

