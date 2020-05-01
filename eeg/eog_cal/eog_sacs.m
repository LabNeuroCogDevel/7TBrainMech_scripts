% extract saccades from provided
function [Latency, meanEOG, VelDisplacement, saccades] = eog_sacs(eogsm_t, velThresh, Gd, Fs)
    SAVEFIGS=0;
    MAKEFIGS=0;
    VERBOSE=0;

    % initialize return values
    Latency=-Inf;
    meanEOG=-Inf;
    VelDisplacement=-Inf;
    saccades=[];

    % eogms likely filter(w,1,diff(eogSm));
    % N.B. shouldn't calc here because we want the vel before diff+integrate?
    vel = diff(eogsm_t);

    %% get saccades

    % get pre-saccade baseline
    baselineInds = 1:100;%max(1,preZero-100):preZero;
    baseline = mean(eogsm_t(baselineInds));
    eogsm = eogsm_t - baseline;
    
    % find all velocity peaks
    [PKS,LOCS]= findpeaks(abs(vel));
    peaks = zeros(1, length(vel));
    peaks(LOCS) = 1;

    % find LOCAL MAX/MIN and SACCADE and NOT TOO SOON
    saccades = find(peaks & abs(vel)>=velThresh & (1:length(vel) > .05*Fs));
    if length(saccades) == 0
        fprintf('No saccades found, skipping\n');
        return;
    end

    saccadeSign = sign(vel(saccades));
    returnSaccadeIdx = find(saccadeSign==-1*saccadeSign(1), 1, 'first');
    if isempty(returnSaccadeIdx)
        saccades(end+1)=length(vel);
        returnSaccadeIdx=length(saccades);
        dur_of_mean = (saccades(end)-saccades(1))/Fs;
        fprintf('Warning: no return saccade!? using rest for meanEOG (%.02f secs)\n', dur_of_mean)
    end

    % find preceding and following zero
    velSignChangeInds = find(diff(sign(vel)));
    preZero = velSignChangeInds(max(find(velSignChangeInds<saccades(1))));
    postZero = velSignChangeInds(min(find(velSignChangeInds>saccades(1))));

    % get integral of saccade vel
    VelDisplacement = sum(vel(preZero:postZero));

    %% output
    Latency = (saccades(1)-Gd/2) / Fs;
    if length(saccades) == 1
        saccades(2) = length(vel);
    end
    Duration = ((saccades(2) - saccades(1))-Gd/2) / Fs;
    meanEOG = mean(eogsm(saccades(1):saccades(returnSaccadeIdx)));

    %% INSPECT
    if MAKEFIGS
        subplot(3,1,1)
        %subplot('position', [.05 .3 .4 .2])
        title('saccades')
        xlim([0 length(eogsm)/Fs])
        plot((1:length(eogsm))/Fs, eogsm, '--k')
        hold on
        plot((saccades(1):saccades(returnSaccadeIdx))/Fs, meanEOG*ones(1, saccades(returnSaccadeIdx)-saccades(1)+1), '-r')
        plot((saccades(1):saccades(returnSaccadeIdx))/Fs, VelDisplacement*ones(1, saccades(returnSaccadeIdx)-saccades(1)+1), '--r')
        ylabel('EOG');

        % plot #2
        vel_fix = vel.*(abs(vel)<velThresh);
        vel_sac = vel.*(abs(vel)>=velThresh);

        %subplot('position', [.05 .05 .4 .2])
        subplot(3,1,2)
        title('vel fix(black) vs sac (red)')
        xlim([0 length(eogsm)/Fs])
        plot((1:length(vel_fix))/Fs, vel_fix, 'k');
        hold on
        plot((1:length(vel_sac))/Fs, vel_sac, 'r');

        %subplot('position', [.05 .05 .4 .2])
        subplot(3,1,3)
        title('velocity')
        %xlim([0 length(eogsm)/Fs])
        plot(saccades(1)/Fs, vel(saccades(1)), 'og');
        plot(saccades(returnSaccadeIdx)/Fs, vel(saccades(returnSaccadeIdx)), 'ob');
        plot(preZero/Fs, vel(preZero), 'ok');
        plot(postZero/Fs, vel(postZero), 'ok');
        xlabel('Time (sec)');
        ylabel('EOG Velocity');
    end
end