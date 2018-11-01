%function score_eog(subj)

% get all subjects
if ~exist('allSubjs', 'var')
    d=eeg_data('#cal', {'Status'});
    allSubjs = {d.id};
end
data = [];%nan*ones(1,7);

VERBOSE = 0;

PRETASK_DURATION = .3; % seconds
POSTONSET_DURATION = 30; % seconds
FILTER_WIDTH = 50;

w = gausswin(FILTER_WIDTH);
w = w./sum(w);


for subji = 1:length(allSubjs)
    subj = allSubjs{subji};%;
    fprintf(1, '\nProcessing subject %s (%d/%d)\n', subj, subji, length(allSubjs));
    parts = strsplit(subj, '_');
    subjid = parts{1};
    scandate = parts{2};
    clear d

    % Load Data
    if ~exist('d', 'var')
        try
            d=eeg_data('#mgs', {'Status','horz_eye'}, 'subjs', {subj});
        catch
            fprintf(1, '--> %s: Could not load MGS data, skipping\n', subj);
            continue;
        end
    end

    if ~exist('cal','var') || ~strcmp(d(1).id, cal.id)
        try
            cal = make_cal(subj);
        catch
            fprintf(1, '--> %s: Could not load calibration data, skipping\n', subj);
            continue;
        end
    end

    % merge in case of more than one run
    if length(d)>1
        newd = d(1);
        newd.Status = [d.Status];
        newd.eye_l = [d.eye_l];
        newd.eye_r = [d.eye_r];
        d = newd;
        clear newd;
    end

    % Get left - right
    eyeDiff = d.eye_l - d.eye_r;

    % isi (150+x) and iti (254) are different
    %    event inc in 50: (50-200: cue=50,img=100,isi=150,mgs=200)  
    %    category inc in 10 (10->30: None,Outdoor,Indoor)
    %    side inc in 1 (1->4: Left -> Right)
    %        61 == cue:None,Left
    %         234 == mgs:Indoor,Right

    statusOnsetInds = find(diff(d.Status) >0)+1;
    statusOnsets = d.Status(statusOnsetInds);

    trialOnsets = statusOnsets(find(statusOnsets>=50 & statusOnsets<100));
    trialOnsetInds = statusOnsetInds(find(statusOnsets>=50 & statusOnsets<100));

    % confirm
    %[trialOnsetInds' trialOnsets' d.Status(trialOnsetInds)']
    nTrials = length(trialOnsetInds);

    fprintf(1, '\tFound %d trials\n', nTrials);
        %triali = 88;
    for triali = 1:nTrials
        if VERBOSE
            close all
            triali
        end

        if triali < nTrials
            inds = max(1,round(trialOnsetInds(triali)-PRETASK_DURATION*d.Fs)):round(trialOnsetInds(triali+1));
        else
            inds = max(1,round(trialOnsetInds(triali)-PRETASK_DURATION*d.Fs)):length(d.Status);
        end

        dur = length(inds)/d.Fs;
        t = linspace(-1*PRETASK_DURATION, dur, dur*d.Fs);

        % extract timecourse
        statusTS = d.Status(inds);
        eogTS = eyeDiff(inds);

        meanPretask = mean(eogTS(1:round(PRETASK_DURATION*d.Fs)));
        eogTS = eogTS - meanPretask;
        eogSm = filter(w,1,eogTS);
        vel = diff(eogSm);%filter(w,1,diff(eogSm));
        Gd = FILTER_WIDTH/2;%18.6348;

        if VERBOSE
            % visualize
            plot(t, statusTS, 'b')
            hold on
            plot(t, eogTS, 'g')
            plot(t-Gd/d.Fs, eogSm, 'k')
            plot(t-Gd/d.Fs, [0 vel]*max(eogSm)/(2*max(vel)), 'r')

            statusTSinds = (find(diff(statusTS)>0)+1);
            labels = statusTS(statusTSinds);
            for i = 1:length(labels)
                text(statusTSinds(i)/d.Fs - PRETASK_DURATION - 150/d.Fs, -50, sprintf('%d', labels(i)));
            end
            set(gcf, 'Position', [324         793        1371         449]);
        end

        % get data intervals
        intInds = find(diff(statusTS)>0)+1;
        intCodes = statusTS(intInds);

        cueInd = intInds(find(intCodes>=50 & intCodes<100, 1, 'first'));
        vgsInd = intInds(find(intCodes>=100 & intCodes<150 & intCodes~=128 & intInds>cueInd, 1, 'first'));
        isiInd = intInds(find(intCodes>=150 & intCodes<200 & intInds>cueInd, 1, 'first'));
        mgsInd = intInds(find(intCodes>=201 & intCodes<250 & intInds>cueInd, 1, 'first'));
        itiInd = intInds(find(intCodes==254 & intInds>cueInd, 1, 'first'));
        if isempty(itiInd)
            itiInd = length(eogSm)-1;
        end

        if isempty(cueInd) | isempty(vgsInd) | isempty(isiInd) | isempty(mgsInd)
            fprintf(1, '--> %s, trial %d: missing index, skipping\n', subj, triali);
            continue;
        end
        
        if VERBOSE
            [cueInd vgsInd isiInd mgsInd itiInd]
        end


        % get median velocity distribution between cue and vgs
    %    fixVel = median(abs(vel(cueInd:vgsInd)));
        fixVel = median(abs(vel(vgsInd:mgsInd)));
        velThresh = fixVel*12;

        % ------------ VGS ------------

        % get saccades for VGS
        if VERBOSE
            figure
            set(gcf, 'Position', [323   292   560   420]);
        end

        vgsVel = vel(vgsInd:mgsInd);
        vgsEogSm = eogSm(vgsInd:mgsInd);

        if VERBOSE
            vel_fix = vgsVel.*(abs(vgsVel)<velThresh);
            vel_sac = vgsVel.*(abs(vgsVel)>=velThresh);
            subplot(2,1,1)
            plot(vel_fix, 'k');
            hold on
            plot(vel_sac, 'r');
        end

        % find all velocity peaks
        [PKS,LOCS]= findpeaks(abs(vgsVel));
        peaks = zeros(1, length(vgsVel));
        peaks(LOCS) = 1;

        % find LOCAL MAX/MIN and SACCADE and NOT TOO SOON
        saccades = find(peaks & abs(vgsVel)>=velThresh & (1:length(vgsVel) > .05*d.Fs));
        if length(saccades) == 0
            if VERBOSE
                return;
            end
            
            fprintf(1, '--> %s, trial %d: No VGS saccades found, skipping\n', subj, triali);
            continue;
        end
        saccadeSign = sign(vgsVel(saccades));
        returnSaccadeIdx = find(saccadeSign==-1*saccadeSign(1), 1, 'first');

        % find preceding and following zero
        velSignChangeInds = find(diff(sign(vgsVel)));
        preZero = velSignChangeInds(max(find(velSignChangeInds<saccades(1))));
        postZero = velSignChangeInds(min(find(velSignChangeInds>saccades(1))));

        % get integral of saccade vel
        vgsVelDisplacement = sum(vgsVel(preZero:postZero));

        % get pre-saccade baseline
        baselineInds = max(1,preZero-100):preZero;
        vgsBaseline = mean(vgsEogSm(baselineInds));

        if VERBOSE
            plot(saccades(1), vgsVel(saccades(1)), 'og');
            plot(saccades(returnSaccadeIdx), vgsVel(saccades(returnSaccadeIdx)), 'ob');
            plot(preZero, vgsVel(preZero), 'ok');
            plot(postZero, vgsVel(postZero), 'ok');
        end

        vgsLatency = (saccades(1)-Gd/2) / d.Fs;
        if length(saccades) == 1
            saccades(2) = length(vgsVel);
        end
        vgsDuration = ((saccades(2) - saccades(1))-Gd/2) / d.Fs;
        meanVGSEOG = mean(vgsEogSm(saccades(1):saccades(returnSaccadeIdx)));

        if VERBOSE
            subplot(2,1,2)
            plot(vgsEogSm, '--k')
            hold on
            plot(saccades(1):saccades(returnSaccadeIdx), meanVGSEOG*ones(1, saccades(returnSaccadeIdx)-saccades(1)+1), '-r')
            plot(saccades(1):saccades(returnSaccadeIdx), vgsVelDisplacement*ones(1, saccades(returnSaccadeIdx)-saccades(1)+1), '--r')
        end

        % ------------ MGS ------------

        % get saccades for MGS
        if VERBOSE
            figure
            set(gcf, 'Position', [887   292   560   420]);
        end

        mgsVel = vel(mgsInd:itiInd);
        mgsEogSm = eogSm(mgsInd:itiInd);

        % use 10x fixVel as threshold for saccade
        vel_fix = mgsVel.*(abs(mgsVel)<velThresh);
        vel_sac = mgsVel.*(abs(mgsVel)>=velThresh);
        if VERBOSE
            subplot(2,1,1)
            plot(vel_fix, 'k');
            hold on
            plot(vel_sac, 'r');
        end

        % find all velocity peaks
        [PKS,LOCS]= findpeaks(abs(mgsVel));
        peaks = zeros(1, length(mgsVel));
        peaks(LOCS) = 1;

        % find LOCAL MAX/MIN and SACCADE and NOT TOO SOON
        saccades = find(peaks & abs(mgsVel)>=velThresh & (1:length(mgsVel) > .02*d.Fs));
        if length(saccades) == 1
            saccades(2) = length(mgsVel);
            returnSaccadeIdx = 2;
        elseif length(saccades) == 0
            fprintf(1, '--> %s, trial %d: No MGS saccades found, skipping\n', subj, triali);
            continue;
        else
            saccadeSign = sign(mgsVel(saccades));
            returnSaccadeIdx = find(saccadeSign==-1*saccadeSign(1), 1, 'first');
            if isempty(returnSaccadeIdx)
                saccades(2) = length(mgsVel);
                returnSaccadeIdx = 2;
            end
        end

        % find preceding and following zero
        velSignChangeInds = find(diff(sign(mgsVel)));
        preZero = velSignChangeInds(max(find(velSignChangeInds<saccades(1))));
        postZero = velSignChangeInds(min(find(velSignChangeInds>saccades(1))));

        % get integral of saccade vel
        mgsVelDisplacement = sum(mgsVel(preZero:postZero));

        % get pre-saccade baseline
        baselineInds = max(1,preZero-100):preZero;
        mgsBaseline = mean(mgsEogSm(baselineInds));

        if VERBOSE
            plot(saccades(1), mgsVel(saccades(1)), 'og');
            plot(saccades(returnSaccadeIdx), mgsVel(saccades(returnSaccadeIdx)), 'ob');
            plot(preZero, mgsVel(preZero), 'ok');
            plot(postZero, mgsVel(postZero), 'ok');
        end

        mgsLatency = (saccades(1)-Gd/2) / d.Fs;
        mgsDuration = ((saccades(returnSaccadeIdx) - saccades(1))-Gd/2) / d.Fs;
        meanMGSEOG = mean(mgsEogSm(saccades(1):saccades(returnSaccadeIdx)));

        if VERBOSE
            subplot(2,1,2)
            plot(mgsEogSm, '--k')
            hold on
            plot(saccades(1):saccades(returnSaccadeIdx), meanMGSEOG*ones(1, saccades(returnSaccadeIdx)-saccades(1)+1), '-r')    
            plot(saccades(1):saccades(returnSaccadeIdx), mgsVelDisplacement*ones(1, saccades(returnSaccadeIdx)-saccades(1)+1), '--r')
        end

        if VERBOSE
            triali
            latencies = [vgsLatency mgsLatency]
            eogPositions = [meanVGSEOG meanMGSEOG meanMGSEOG-meanVGSEOG]/cal.slope
            eogAdjPositions = [meanVGSEOG-vgsBaseline meanMGSEOG-mgsBaseline (meanMGSEOG-mgsBaseline)-(meanVGSEOG-vgsBaseline)]/cal.slope
            saccadeDists = [vgsVelDisplacement mgsVelDisplacement mgsVelDisplacement-vgsVelDisplacement]/cal.slope
        end

        data(end+1,:) = [str2double(subjid) str2double(scandate) triali ((meanMGSEOG-mgsBaseline)-(meanVGSEOG-vgsBaseline))/cal.slope (mgsVelDisplacement-vgsVelDisplacement)/cal.slope vgsLatency mgsLatency];
        
        if VERBOSE
            fprintf(1, '%d\t%', data(end, 1:2));
            fprintf(1, '%.4f\t', data(end, 3:end));
            fprintf(1, '\n');
            uiwait
        end
    end
end

datatable = array2table(data);
datatable.Properties.VariableNames = {'LunaID','ScanDate','Trial','PositionError','DisplacementError','vgsLatency','mgsLatency'};