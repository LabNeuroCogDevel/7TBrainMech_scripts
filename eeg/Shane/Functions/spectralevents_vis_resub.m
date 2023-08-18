function spectralevents_vis_resub(cfg, specEv_struct, timeseries, TFRs, tVec, fVec)
% SPECTRALEVENTS_VIS Conducts basic analysis for the purpose of
%   visualizing dataset spectral event features and generates spectrogram
%   and probability histogram plots.
%
% SPECTRALEVENTS_VIS(specEv_struct,timeseries,TFRs,tVec,fVec)
%
% Inputs:
%   specEv_struct - spectralevents structure array.
%   timeseries - cell array containing time-series trials by
%       subject/session.
%   TFRs - cell array with each cell containing the time-frequency response
%       (freq-by-time-by-trial) for a given subject/session.
%   tVec - time vector (s) over which the time-frequency responses are
%       shown.
%   fVec - frequency vector (Hz) over which the time-frequency responses
%       are shown.
%
% See also SPECTRALEVENTS, SPECTRALEVENTS_FIND, SPECTRALEVENTS_TS2TFR.

%   -----------------------------------------------------------------------
%   SpectralEvents::spectralevents_vis
%   Copyright (C) 2018  Ryan Thorpe
%
%   This file is part of the SpectralEvents toolbox.
%
%   SpectralEvents is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
%
%   SpectralEvents is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <https://www.gnu.org/licenses/>.
%   -----------------------------------------------------------------------

numSubj = length(specEv_struct); %Number of subjects/sessions

% Spectrograms showing trial-by-trial events (see Figure 2 in Shin et al. eLife 2017)
for subj_i=1:numSubj

    
    % Extract TFR attributes for given subject/session
     %TFR = TFRs{1,subj_i}{1,1}; for multiple subjects

    TFR = TFRs{1,subj_i}; %for one subject
%     TFR_norm = TFR./median(reshape(TFR, size(TFR,1), size(TFR,2)*size(TFR,3)), 2);
    %isempty(specEv_struct{1,subj_i}.TrialSummary) for multiple subjects 
    if isempty(specEv_struct.TrialSummary) %for one subject 
        continue
    end
%     classLabels =
%     specEv_struct{1,subj_i}.TrialSummary.TrialSummary.classLabels; for
%     multiple subjects
%     eventBand = specEv_struct{1,subj_i}.Events.EventBand;

    classLabels = specEv_struct.TrialSummary.TrialSummary.classLabels; %for one subject
    eventBand = specEv_struct.Events.EventBand;
    
    
    %specEv_struct{1,subj_i} for multiple subs
    % Extract event attributes for a given subject/session
    eventThr = specEv_struct.Events.Threshold;
%     trialInd = specEv_struct.Events.Events.trialind;
%     maximaTiming = specEv_struct.Events.Events.maximatiming;
%     maximaFreq = specEv_struct.Events.Events.maximafreq;
    
    eventBand_inds = find(fVec>=eventBand(1) & fVec<=eventBand(2)); %Indices of freq vector within eventBand
    classes = unique(classLabels); %Array of unique class labels
    
    % Make plots for each type of class
    for cls_i=1:numel(classes)
        trial_inds = find(classLabels==classes(cls_i)); %Indices of TFR trials corresponding with the given class
        
        % Calculate average TFR for a given subject/session and determine
        % number of trials to sample
        if numel(trial_inds)>10
            numSampTrials = 10;
            %avgTFR = mean(TFR(:,:,trial_inds),3);
        elseif numel(trial_inds)>1
            numSampTrials = numel(trial_inds);
            %avgTFR = mean(TFR(:,:,trial_inds),3);
        else
            numSampTrials = numel(trial_inds);
        end
        avgTFR = squeeze(mean(TFR(:,:,trial_inds),3));
%         avgTFR_norm = squeeze(mean(TFR_norm(:,:,trial_inds),3));
        
        % Find sample trials to view
        rng('default');
        randTrial_inds = [11,12,13,37,23,68,17,18,29,20]; %randperm(numel(trial_inds),numSampTrials); %Sample trial indices
        
        % Plot average raw TFR
        figure;
        subplot('Position',[0.08 0.75 0.75 0.17])
        imagesc([tVec(1) tVec(end)],[fVec(1) fVec(end)],avgTFR)
        x_tick = get(gca,'xtick');
        set(gca,'xtick',x_tick);
        set(gca,'ticklength',[0.0075 0.025])
        set(gca,'xticklabel',[])
        set(gca,'ytick',union(fVec([1,end]),eventBand))
        ylabel('Hz')
        pos = get(gca,'position');
        colormap jet
        cb = colorbar;
        cb.Position = [pos(1)+pos(3)+0.01 pos(2) 0.008 pos(4)];
        cb.Label.String = 'Spectral power';
        hold on
        line(tVec',repmat(eventBand,length(tVec),1)','Color','k','LineStyle',':')
        hold off
        title({'\fontsize{16}Raw TFR',['\fontsize{12}Channel ',num2str(subj_i),', Trial class ',num2str(classes(cls_i))]})
    
        % Plot 10 randomly sampled TFR trials
        for trl_i=1:numSampTrials
            % Raw TFR trial
            rTrial_sub(trl_i) = subplot('Position',[0.08 0.75-(0.065*trl_i) 0.75 0.05]);
            %clims = [0 mean(eventThr(eventBand_inds))*1.5]; %Standardize upper limit of spectrogram scaling using the average event threshold
            %imagesc([tVec(1) tVec(end)],eventBand,TFR(eventBand_inds(1):eventBand_inds(end),:,trial_inds(randTrial_inds(trl_i))),clims)
            imagesc([tVec(1) tVec(end)],eventBand,TFR(eventBand_inds(1):eventBand_inds(end),:,trial_inds(randTrial_inds(trl_i))))
            x_tick_labels = get(gca,'xticklabels');
            x_tick = get(gca,'xtick');
            set(gca,'xtick',x_tick);
            set(gca,'ticklength',[0.0075 0.025])
            set(gca,'xticklabel',[])
            set(gca,'ytick',eventBand)
            rTrial_pos = get(gca,'position');
            colormap jet
            cb = colorbar;
            cb.Position = [rTrial_pos(1)+rTrial_pos(3)+0.01 rTrial_pos(2) 0.008 rTrial_pos(4)];
            
           % timeseries{1,subj_i}{1,1} for multiple subs
            % Overlay locations of event peaks and the waveform corresponding with each trial
            hold on
            plot(maximaTiming(trialInd==trial_inds(randTrial_inds(trl_i))),maximaFreq(trialInd==trial_inds(randTrial_inds(trl_i))),'w.') %Add points at event maxima
            yyaxis right
            plot(tVec,timeseries{1,subj_i}(:,trial_inds(randTrial_inds(trl_i))),'w')
            %set(gca,'ytick',[])
            set(gca,'yticklabel',[])
            hold off
            
        end
   
    end
end

end
