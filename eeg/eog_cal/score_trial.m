% 20241219WF - init extracted from score_anti
%TIME UNIT IS SECONDS!!!!!! NOT MILLISECONDS!
function [antilat, iscorrect, varargout] = score_trial(eogTS, side_sign, calslope, pretask_n_ind, filter_width, Fs)
   % SCORE_TRIAL - score eogTS as a single trial 
   %               could be called by score_anti, calls eog_sacs
   % eogTS:  eyeDiff, includes PRETASK_DURATION prepended to front
   % side_sign: sign (-1 left, 1 right) of expected correct saccade
   % calslope: cal.slope for from (make_cal.m)
   % pretask_n_ind: PRETASK_DURATION*d.Fs -- number of samples before event
   %                used for normalization
   % filter_width:  size of guasswin used for smoothing data. (eg. 50)
   % Fs:  sampling frequency (e.g. 512)

    lat=NaN;
    iscorrect=-1;
    out=struct('reason',NaN);
    second_end=NaN;
    farthest_otherside=NaN;

    
    % filter
    % constants
    Gd = filter_width/2; 
    w = gausswin(filter_width);
    w = w./sum(w);


    % normalize position to pre task fixation (un-drift)
    meanPretask = mean(eogTS(1:pretask_n_ind));
    eogTS = eogTS - meanPretask;
    eogSm = filtfilt(w,1,eogTS);
    

    % diff then integrate (remove intercept?)
    eogSm_orig = eogSm;
    vel = diff(eogSm);%filter(w,1,diff(eogSm));
    vel_detrend = vel - median(vel);
    eogSm_integral = cumsum(vel_detrend);
    eogSm_integral(end+1) = eogSm_integral(end);
    eogSm = eogSm_integral;
    

    % get median velocity distribution between eg. cue and anti

    % TODO: this is weird! maybe we want pretask idx intead?
    samplerange=(pretask_n_ind+1):(length(eogTS)-1);
    fixVel = median(abs(vel(samplerange)));
    velThresh = 30 * abs(calslope) / Fs; %fixVel*12;


    % get saccade latency
    eogsm_t = eogSm((pretask_n_ind+1):length(eogTS));
    [antilat, meanEOG, VelDisplacement, saccades] = ...
       eog_sacs(eogsm_t, velThresh, Gd, Fs);



    if isempty(saccades)
       fprintf('Error: no saccades\n')
       out.reason = 'No saccades';
    else
       iscorrect = 1.*sign(side_sign) == sign(meanEOG/calslope);
       % no saccades found? drop it
       if any(~isfinite(antilat))
        iscorrect(~isfinite(antilat)) = NaN;
       end
    end
    
%% exclusion criteria
    %exclude trials with lat <100
    if lat < 0.1
       warning('latency quicker than 100ms')
       iscorrect=-1;
       out.reason = 'fast lat';
    end
    
    % determine interval before stimulus appears + before a non-express saccade (100 samples + 100ms)
    % determine number of samples corresponding to 100ms (and add to 100 samples)
    ind=round(Fs*(0.1));
    int_end=pretask_n_ind + ind;
    
    %determine velocity during interval and use its max
    pre_sac_ts= vel_detrend(1:int_end);
    %if interval has a greater velocity than established threshold, skip over it
    %(meaning the eyes did not start steady at baseline and we cannot confidently score)
    pre_max_vel = max(pre_sac_ts);
    if pre_max_vel > velThresh
       warning('greater velocity than threshold during pre- interval')
       out.reason = sprintf('pre_sac max (%.02f) > %.02f', pre_max_vel, velThresh);
       iscorrect=-1;
       lat=NaN;
    end

    % TODO: change iscorrect to 2 if error corrected
    if iscorrect == 0
        %% TODO: maybe just lookat max EOG value?
        farthest_otherside = max(abs(eogSm(sign(eogSm) ~= sign(meanEOG))));
        if farthest_otherside  > 50
            warning('crossed center by %.02f (incorrect mean %0.2f); expect error corrected\n', farthest_otherside, meanEOG)
        end

        %% looking at saccades
        %% TODO: maybe while loop over each interval?
        orig_vel = sign(vel_detrend(saccades(1)+pretask_n_ind));
        saccadeSign = sign(vel_detrend);
        corrected = saccadeSign==-1*orig_vel & abs(vel_detrend) > velThresh;
        next_sac = find(corrected, 1, 'first');
        % plot(vel_detrend); hold on; plot(corrected); hold off;
        if(~isempty(next_sac))
            end_next_sac = find(corrected(next_sac:end) == 0, 1, 'first');
            if(isempty(end_next_sac))
                warning('found potential error correcting saccade but never stabilizes')
            else
                second_end = eogSm(end_next_sac+next_sac);

                % error corrected!
                if sign(second_end) ~= sign(meanEOG)
                    iscorrect = 2;
                end
                posdiff = abs(second_end-meanEOG);
                if posdiff < 20
                    warning('marked trial as error correct but second sac (%.02f) ends %.02f from first (%.02f)', ...
                        second_end, posdiff, meanEOG)
                end
            end
        end
    end
    

    % info useful for plotting or debugging
    if nargout > 2 % first two arg outs are required
       out.eogSm_org=eogSm_orig;
       out.eogSm=eogSm;
       out.meanEOG = meanEOG;
       out.vel_detrend = vel_detrend;
       out.VelDisplacement = VelDisplacement;
       out.saccades = saccades;
       out.calslope = calslope;
       out.fixVel = fixVel;
       out.velThresh = velThresh;
       out.Fs = Fs;
       out.Gd = Gd;
       out.stim_onset_ind = pretask_n_ind;
       out.second_end = second_end;
       out.farthest_otherside = farthest_otherside;
       out.lat = antilat;
       out.score = iscorrect;
       % set to first varable output
       varargout{1} = out;
    end
end 

%!test
%! [antilat, iscorrect, varargout] = score_trial(zeros(1,100), 1, 1, 10, 50, 512)
%! assert(iscorrect == -1)
