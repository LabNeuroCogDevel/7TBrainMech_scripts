%%
addpath('/Volumes/Zeus/DB_SQL')
agetbl = db_query('select id as lunaid, to_char(vtimestamp,''YYYYmmdd'') as scandate, age  from visit_study natural join visit natural join enroll where study like ''BrainMechR01'' and etype like ''LunaID'' and vtype like ''%can''');

% remove duplicates
agetbl = unique(agetbl);

if ~exist('datatable', 'var')
    load('eeg_data_20190904.mat');
end

%%
ids = unique(datatable.LunaID);
summary = [];
subjIDs = [];

for subji = 1:height(agetbl)
    id = str2double(agetbl(subji,:).lunaid{1});
    vdate = str2double(agetbl(subji,:).scandate{1});
    age = agetbl(subji,:).age;
    
    idx = find(datatable.LunaID == id);% & datatable.ScanDate == vdate); % WILL ONLY WORK WITH 1 VISIT
    
    if isempty(idx)
        continue
    end
    
    subj = sprintf('%d_%d', datatable(idx(1),:).LunaID, datatable(idx(1),:).ScanDate);
    
%    ageIdx = find(strcmp(agetbl.lunaid, subj));
%    if isempty(ageIdx)
%        ageIdx = find(datatable(idx(1),:).lunaid == ageSubjs);
%    end
    
%     if isempty(ageIdx)
%         age = NaN;
%         fprintf(1, 'No age for %s\n', subj);
%     else
%         age = agetbl(ageIdx,:).age;
%     end
    
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
    
    subjIDs(end+1) = id;
    summary(end+1,:) = [age n u(1) sd(1) se(1) u(2) sd(2) se(2) u(3) sd(3) se(3) u(4) sd(4) se(4) u(5) sd(5) se(5)];
end
cols = {'Age','N','PosErr (deg)','PosErr SD','PosErr SE', 'DispErr (deg)', 'DispErr SD', 'DispErr SE', 'VGS Latency','VGS Latency SD','VGS Latency SE','MGS Latency','MGS Latency SD','MGS Latency SE','MGS-VGS Latency','MGS-VGS Latency SD','MGS-VGS Latency SE'};

savetbl = array2table([subjIDs' summary]);
savetbl.Properties.VariableNames{1} = 'LunaID';
for i = 1:length(cols); savetbl.Properties.VariableNames{i+1} = strrep(strrep(strrep(strrep(cols{i}, '(', ''), ')', ''), ' ', '_'), '-', '_'); end
writetable(savetbl, sprintf('eog_group_data_%s.csv',datestr(now, 'YYYYmmdd')), 'Delimiter', ',');

%%

xi = 1;
ys = [12 13 15 3 4 6];
nx = 2; ny = 3;
figure
set(gcf, 'Position', [272         298        1667        1030]);

for yi = ys
    yi
    subplot(nx, ny, find(yi==ys));
    if any(yi == [3 6 9 12 15])
        sei = yi+2;
    else
        sei = NaN;
    end

    z = abs((summary(:,yi)-mean(summary(:,yi)))/std(summary(:,yi)));
    inds = find(z<3);
    
    if ~isnan(sei)
        errorbar(summary(inds,xi), summary(inds,yi), summary(inds,sei), 'ok');
    else
        plot(summary(inds,xi), summary(inds,yi), 'ok');
    end
    
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