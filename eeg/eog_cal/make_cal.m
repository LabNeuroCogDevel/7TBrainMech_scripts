function calStruct = make_cal(subj, VERBOSE)

if nargin<2
    VERBOSE = 0;
end

d=eeg_data('#cal', {'Status','horz_eye'}, 'subjs', {subj});
if length(d)>1
    newd = d(1);
    newd.Status = [d.Status];
    newd.eye_l = [d.eye_l];
    newd.eye_r = [d.eye_r];
    d = newd;
    clear newd;
end
subjind = find(strcmp({d.id},subj));

POSITION_LOOKUP = [ 0.2       ,  0.23684211,  0.27368421,  0.31052632,  0.34736842, ...
       0.38421053,  0.42105263,  0.45789474,  0.49473684,  0.53157895, ...
       0.56842105,  0.60526316,  0.64210526,  0.67894737,  0.71578947, ...
       0.75263158,  0.78947368,  0.82631579,  0.86315789,  0.9       , ...
      -0.2       , -0.23684211, -0.27368421, -0.31052632, -0.34736842, ...
      -0.38421053, -0.42105263, -0.45789474, -0.49473684, -0.53157895, ...
      -0.56842105, -0.60526316, -0.64210526, -0.67894737, -0.71578947, ...
      -0.75263158, -0.78947368, -0.82631579, -0.86315789, -0.9       ];
  
PRETASK_DURATION = .2; % seconds
POSTONSET_DURATION = 1; % seconds

OPTS = optimoptions(@lsqcurvefit,'Display','off');


pretaskInds = round(PRETASK_DURATION*d.Fs);
posttaskInds = round(POSTONSET_DURATION*d.Fs);

% Get left - right
eyeDiff = d.eye_l - d.eye_r;

% Find start of each trial, by looking for moments when Status changes from
% 0->x, where 0<x<=40
trialOnsets = find(diff(d.Status) >0 & diff(d.Status)<=40)+1;

squareWave = @(b,t) b(3)*(t>b(1)).*(t<(b(1)+b(2)))+b(4)*(t>=(b(1)+b(2))); % b(1)=onset, b(2)=duration, b(3) = amplitude, b(4) = return position
alignedData = nan*ones(length(trialOnsets), 1+posttaskInds);
w = gausswin(20);
w = w./sum(w);

if VERBOSE
    figure
    set(gcf, 'Position', [475         104        1711        1241]);
end

fitData = [];
for triali = 1:length(trialOnsets)
    
    % extract pre-trial baseline and get robust mean
    thisPre = eyeDiff(trialOnsets(triali)-pretaskInds:trialOnsets(triali));
    
    z = (thisPre - nanmean(thisPre))/nanstd(thisPre);
    u = nanmean(thisPre(abs(z)<4));
    v = nanstd(thisPre(abs(z)<4));
    
    % compute post-onset data, adjusting for baseline
    thisPost = eyeDiff(trialOnsets(triali):min(trialOnsets(triali)+posttaskInds,length(eyeDiff))) - u;
    
    % smooth it a little
    thisPost = filter(w,1,thisPost);
    
    % fit a square wave
    onsetGuess = find(abs(thisPost/v) > 5, 1, 'first');
    if isempty(onsetGuess)
        onsetGuess = .2*d.Fs;
    end
    
    [~,ampGuessIdx] = max(abs(thisPost));
    ampGuess = thisPost(ampGuessIdx);
    %[triali onsetGuess ampGuess]
    
    x = 1:length(thisPost);
    [b,RESNORM,RESIDUAL,EXITFLAG,OUTPUT,LAMBDA,JACOBIAN] = lsqcurvefit(squareWave, [onsetGuess .4*d.Fs ampGuess thisPost(end)], x, thisPost, [], [], OPTS);
    
    if VERBOSE
        yhat = squareWave(b, x);


        subplot(7,7,triali)
        plot(x, thisPost, 'k');
        hold on
        plot(x, yhat, 'r');
    end
    
    % summarize
    fitData(triali,:) = [d.Status(trialOnsets(triali)) b(3) RESNORM];
    alignedData(triali,1:length(thisPost)) = thisPost;
end

if VERBOSE
    figure
    %plot(POSITION_LOOKUP(fitData(:,1)), fitData(:,2), 'or');
    %scatter(POSITION_LOOKUP(fitData(:,1)), fitData(:,2), [], max(fitData(:,3)) - fitData(:,3),'filled'); colormap(jet);
    scatter(POSITION_LOOKUP(fitData(:,1)), fitData(:,2),'filled'); colormap(jet);
end

[slope,dev,stats] = glmfit(POSITION_LOOKUP(fitData(:,1)), fitData(:,2), 'normal','Constant','off');%,'Weights', max(fitData(:,3)) - fitData(:,3));

% b is in unites of voltage per screen unit



if VERBOSE
    xhat = sort(POSITION_LOOKUP);
    [yhat,dylo,dyhi] = glmval(slope,xhat,'identity',stats,'Constant','off');
    hold on
    shadedErrorBar(xhat, yhat, [dylo dyhi], 'k', 1);
end

% convert to voltage per degree
%   width = 53.3cm
%   viewing dist = 58.4cm
%   full screen width in visual angle = 59.0deg
%   visual angle per screen unit = 24.5deg
calStruct.slope = slope/24.5;
calStruct.units = 'voltage per visual angle';
calStruct.id = d.id;