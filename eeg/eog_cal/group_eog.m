agetbl = readtable('~/eeg_ages.csv');
ageSubjs = [];
for i = 1:height(agetbl)
    parts = strsplit(agetbl(i,:).lunaid{1}, '_');
    ageSubjs(i) = str2double(parts{1});
end

ids = unique(datatable.LunaID);
summary = [];

for subji = 1:length(ids)
    idx = find(datatable.LunaID == ids(subji));
    subj = sprintf('%d_%d', datatable(idx(1),:).LunaID, datatable(idx(1),:).ScanDate);
    
    ageIdx = find(strcmp(agetbl.lunaid, subj));
    if isempty(ageIdx)
        ageIdx = find(datatable(idx(1),:).LunaID == ageSubjs);
    end
    
    if isempty(ageIdx)
        age = NaN;
        fprintf(1, 'No age for %s\n', subj);
    else
        age = agetbl(ageIdx,:).age;
    end
    
    perf = table2array(datatable(idx,4:end));
    perf(:,5) = perf(:,4) - perf(:,3);
    
    u = nanmean(abs(perf));
    sd = nanstd(abs(perf));
    z = abs((abs(perf)-u)./sd);
    perf(z>3) = NaN;
    
    u = nanmean(abs(perf));
    sd = nanstd(abs(perf));
    n = size(perf,1);
    se = sd / sqrt(n);
    
    summary(subji,:) = [age n u(1) se(1) u(2) se(2) u(3) se(3) u(4) se(4) u(5) se(5)];
end

cols = {'Age','N','PosErr (deg)','PosErr_SE', 'DispErr (deg)', 'DispErr_SE', 'VGS Latency','VGS Latency SE','MGS Latency','MGS Latency SE','MGS-VGS Latency','MGS-VGS Latency SE'};

xi = 1;

for yi = [2 3 5 7 9 11]
    yi
    figure
    sei = yi+1;

    z = abs((summary(:,yi)-mean(summary(:,yi)))/std(summary(:,yi)));
    inds = find(z<3);
    
    errorbar(summary(inds,xi), summary(inds,yi), summary(inds,sei), 'ok');
    xhat = min(summary(inds,1)):.1:max(summary(inds,1));
    distr = 'normal'; link = 'identity';

    % linear fit
    [b_lin,dev,stats_lin] = glmfit(summary(inds,xi), summary(inds,yi), distr);
    p_lin = stats_lin.p(2);

    % inverse fit
    [b_inv,dev,stats_inv] = glmfit(1./summary(inds,xi), summary(inds,yi), distr);
    p_inv = stats_inv.p(2);

    if p_lin < p_inv
        [yhat,dylo,dyhi] = glmval(b_lin, xhat, link, stats_lin);
        text(22, .9*max(summary(inds,yi)), sprintf('p = %.3f', p_lin), 'FontSize',20);
    else
        [yhat,dylo,dyhi] = glmval(b_inv, 1./xhat, link, stats_inv);
        text(22, .9*max(summary(inds,yi)), sprintf('p = %.3f', p_inv), 'FontSize',20);
    end

    hold on
    shadedErrorBar(xhat, yhat, dylo, '--r', 1)
    xlabel(cols{xi});
    ylabel(cols{yi});
    set(gca, 'FontSize', 14);
    set(gcf, 'color','w');
    
    %uiwait
end