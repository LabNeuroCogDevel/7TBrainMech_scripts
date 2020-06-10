function calStruct = make_cal(subj, VERBOSE, MAKEFIGS)

if nargin<2
    VERBOSE = 0;
end

if nargin<3
    MAKEFIGS = 1;
end

if VERBOSE
    vis = 'on';
    fprintf(1, 'Running calibration for subject %s, with VERBOSE=%d and MAKEFIGS=%d\n', subj, VERBOSE, MAKEFIGS);
else
    vis = 'off';
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

if MAKEFIGS
    figure('Visible', vis);
    set(gcf, 'Position', [475         104        1711        1241]);
end

fitData = [];
for triali = 1:length(trialOnsets)
    
    % extract pre-trial baseline and get robust mean
    
    try
        thisPre = eyeDiff(trialOnsets(triali)-pretaskInds:trialOnsets(triali));
    catch
        fitData(triali, 1:3) = [NaN NaN NaN];
        continue;
    end
    
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
    
    if MAKEFIGS
        yhat = squareWave(b, x);


        subplot(7,7,triali)
        plot(x, thisPost, 'k');
        hold on
        plot(x, yhat, 'r');
    end
    
    % summarize
    try
        fitData(triali,:) = [d.Status(trialOnsets(triali)) b(3) mean(RESIDUAL(ceil(b(1)):floor(b(1)+b(2))).^2)/mean(thisPost(ceil(b(1)):floor(b(1)+b(2))).^2)]; % or RESNORM?
        alignedData(triali,1:length(thisPost)) = thisPost;
    catch
        fitData(triali, 1:3) = [NaN NaN NaN];
    end
end

%
idx = fitData(:,1) <= length(POSITION_LOOKUP) & ~isnan(fitData(:,1));
fitData = fitData(idx,:);

z = zscore(1./fitData(:,3));
scalerange = .9;
w = ( scalerange*(1./(1+exp(-5*z))) )+(1-scalerange);

if MAKEFIGS
    if VERBOSE
        fprintf('%d: %.4f\n', [(1:length(w))' w]')
    end
    
    for triali = 1:length(trialOnsets)
        subplot(7,7,triali)
        ax = get(gca);
        xr = diff(ax.XLim); yr = diff(ax.YLim);
        text(ax.XLim(1)+.6*xr, ax.YLim(1)+.75*yr, sprintf('res = %.3g\nz=%.3f\nw = %.3f', fitData(triali,3), z(triali), w(triali)), 'FontSize', 10);
    end
    
    export_fig(sprintf('fits/calFits_%s.png', subj), '-r100');
end

%%


%[slope,dev,stats] = glmfit(POSITION_LOOKUP(fitData(:,1)), fitData(:,2), 'normal','Constant','off');%,'Weights', max(fitData(:,3)) - fitData(:,3));
mdl = fitlm(POSITION_LOOKUP(fitData(:,1)), fitData(:,2), 'Weights', w);
goodidx = find(abs(zscore(mdl.Residuals.Raw))<=2);
badidx = find(abs(zscore(mdl.Residuals.Raw))>2);
mdl = fitlm(POSITION_LOOKUP(fitData(:,1)), fitData(:,2), 'Weights', w, 'Exclude', badidx);
slope = mdl.Coefficients.Estimate(2);

if MAKEFIGS
    figure('Visible', vis);
    %plot(POSITION_LOOKUP(fitData(:,1)), fitData(:,2), 'or');
    %scatter(POSITION_LOOKUP(fitData(:,1)), fitData(:,2), [], max(fitData(:,3)) - fitData(:,3),'filled'); colormap(jet);    
    scatter(POSITION_LOOKUP(fitData(goodidx,1)), fitData(goodidx,2),100*w(goodidx), 'filled'); colormap(jet);
    hold on
    scatter(POSITION_LOOKUP(fitData(badidx,1)), fitData(badidx,2),100*w(badidx)); colormap(jet);
end


% b is in unites of voltage per screen unit
if MAKEFIGS
    xhat = sort(POSITION_LOOKUP);
    %[yhat,dylo,dyhi] = glmval(slope,xhat,'identity',stats,'Constant','off');
    [yhat,YCI] = predict(mdl, xhat');
    
    hold on
    shadedErrorBar(xhat, yhat, [yhat-YCI(:,1) YCI(:,2)-yhat], 'k', 1);
    
    ax = get(gca);
    xr = diff(ax.XLim); yr = diff(ax.YLim);
    text(ax.XLim(1)+.8*xr, ax.YLim(1)+.75*yr, sprintf('slope = %.3g\nr2=%.3f', slope, mdl.Rsquared.Adjusted), 'FontSize', 10);

    export_fig(sprintf('fits/calRegression_%s.png', subj), '-r100');
end
%%
% convert to voltage per degree
%   width = 53.3cm
%   viewing dist = 58.4cm
%   full screen width in visual angle = 59.0deg
%   visual angle per screen unit = 24.5deg
calStruct.slope = slope/24.5;
calStruct.units = 'voltage per visual angle';
calStruct.id = d.id;
calStruct.r2 = mdl.Rsquared.Adjusted;

if VERBOSE
    uiwait
elseif MAKEFIGS
    close all
end


