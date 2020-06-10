%%
%addpath('/Volumes/Zeus/DB_SQL')
%agetbl = db_query('select id as lunaid, to_char(vtimestamp,''YYYYmmdd'') as scandate, age  from visit_study natural join visit natural join enroll where study like ''BrainMechR01'' and etype like ''LunaID'' and vtype like ''%can''');

[s, r] = system('selld8 l |grep eeg|cut -f 1,2 > eeg_age_info.csv');
agetbl = readtable('eeg_age_info.csv', 'Delimiter', '\t');
agetbl.Properties.VariableNames = {'ses_id', 'age'};
head(agetbl);

% remove duplicates
agetbl = unique(agetbl);

if ~exist('datatable', 'var')
    load('eeg_data_20200417.mat');
end

ses_id = {};
for i = 1:height(datatable)
    ses_id{i} = sprintf('%d_%d', datatable(i,:).LunaID, datatable(i,:).ScanDate);
end
datatable.ses_id = ses_id';

%%
ses_ids = unique(datatable.ses_id);
summary = [];
subjIDs = [];
vdates = [];

for subji = 1:length(ses_ids)
    this_ses = ses_ids{subji};
    parts = strsplit(this_ses, '_');
    
    id = str2double(parts{1});
    vdate = str2double(parts{2});
    
    ageidx = find(strcmp(agetbl.ses_id, this_ses));
    if length(ageidx) == 0
        age = NaN;
    else
        age = agetbl(ageidx,:).age;
    end
    
    idx = find(strcmp(datatable.ses_id, this_ses));
    
    if isempty(idx)
        continue
    end
    
    calr2 = datatable(idx(1), :).calR2;
        
    perf = table2array(datatable(idx,4:end-1));
    perf(:,5) = perf(:,4) - perf(:,3);
    
    perf_mad = mad(perf, [], 1);
    ntrials = size(perf, 1);
    mad_rep = repmat(perf_mad, [ntrials 1]);
    mad_diff = abs(perf - mad_rep);
    
%     for thresh = 1:.5:10
%         fprintf(1, '%.1f: %.3f%%\n', thresh, 100*sum(mad_diff(:) > thresh)/length(mad_diff(:)));
%     end
    perf(mad_diff > 5) = NaN;

    u = nanmean(abs(perf));
%    sd = nanstd(abs(perf));
    sorted_perf = sort(abs(perf));
    sd = nanstd(sorted_perf(3:end-2));
    z = abs((abs(perf)-u)./sd);
    perf(z>2) = NaN;
    
    u = nanmean(abs(perf));
    m = nanmedian(abs(perf));
    sd = nanstd(abs(perf));
    n = size(perf,1);
    se = sd / sqrt(n);
    
    subjIDs(end+1) = id;
    vdates(end+1) = vdate;
    summary(end+1,:) = [age n calr2 u(1) sd(1) se(1) m(1) ...
                                    u(2) sd(2) se(2) m(2) ...
                                    u(3) sd(3) se(3) m(3) ...
                                    u(4) sd(4) se(4) m(4) ...
                                    u(5) sd(5) se(5) m(5)];
end
cols = {'vdate','Age','N','calR2', ...
    'PosErr (deg)','PosErr SD','PosErr SE', 'PosErr Median', ...
    'DispErr (deg)', 'DispErr SD', 'DispErr SE', 'DispErr Median', ...
    'VGS Latency','VGS Latency SD','VGS Latency SE', 'VGS Latency Median', ...
    'MGS Latency','MGS Latency SD','MGS Latency SE', 'MGS Latency Median', ...
    'MGS-VGS Latency','MGS-VGS Latency SD','MGS-VGS Latency SE', 'MGS-VGS Latency Median'};

savetbl = array2table([subjIDs' vdates' summary]);
savetbl.Properties.VariableNames{1} = 'LunaID';
for i = 1:length(cols); savetbl.Properties.VariableNames{i+1} = strrep(strrep(strrep(strrep(cols{i}, '(', ''), ')', ''), ' ', '_'), '-', '_'); end
writetable(savetbl, sprintf('eog_group_data_%s.csv',datestr(now, 'YYYYmmdd')), 'Delimiter', ',');


return

%%

xi = 1;
ys = [13 14 16 4 5 7];
nx = 2; ny = 3;
figure('visibile','off')
set(gcf, 'Position', [272         298        1667        1030]);

summary = summary(find(summary(:,3)>.9),:);
for yi = ys
    yi
    subplot(nx, ny, find(yi==ys));
    if any(yi == [4 7 10 13 16])
        sei = yi+2;
    else
        sei = NaN;
    end

    z = abs((summary(:,yi)-mean(summary(:,yi)))/std(summary(:,yi)));
    inds = find(z<3);
    
    if ~isnan(sei)
        plot(summary(inds,xi), summary(inds,yi), '.k');
        loessline(.9, 'loess', 'b')
        errorbar(summary(inds,xi), summary(inds,yi), summary(inds,sei), 'ok');
    else
        plot(summary(inds,xi), summary(inds,yi), 'ok');
        loessline(.75, 'loess', 'b')
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

export_fig('~/mgs_eog_perf.png', '-r100');
