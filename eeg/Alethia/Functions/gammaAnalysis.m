function gammaAnalysis(gammaBroad_i, freqs, files, cfg)

locs = find(freqs > 30);

%% to create age vs gamma power scatter plot and linear regression 

for k = 1:size(gammaBroad_i,1)
    
    
    AllFreq = gammaBroad_i(k,:);
    gammaFreq = AllFreq(locs);
    
    avgGammaFreq = gammaBroad_i(k,:);
    
    % mean(gammaFreq,2);
    
    IDdata = xlsread('H:\Projects\7TBrainMech\scripts\eeg\Alethia\Results\ERPs\EdaDI.csv');
    
    for a = 1:75
        subject = files(a).name;
        ID = str2double(subject(1:5));
        
        loc = find(IDdata(:,2) == ID);
        
        if isempty(loc) == 1
            avgGammaFreq(loc) = [];
            
            continue;
        end
        subjectAge(a) = IDdata(loc,3);
        
    end
    
    average = mean(avgGammaFreq);
    sd = std(avgGammaFreq);
    include = find(avgGammaFreq < 2.5*sd);
    avgGammaFreq = avgGammaFreq(include);
    subjectAge = subjectAge(include);
    
    scatter(subjectAge, avgGammaFreq);
    
    fit = polyfit(subjectAge,avgGammaFreq,1);
    
    predValues = polyval(fit, subjectAge);
    
    hold on;
    plot(subjectAge, predValues);
    
end

%% To create color graph for gamma power

region = cfg.rois{6};
power = zeros(length(region),size(s_erps,2), size(s_erps,3));

for i = length(region)
    channel = region(i); 
    
    power(i,:,:) = squeeze(s_erps(i,:,:)); 
    
end

avgPower = mean(power);

imagesc(squeeze(avgPower));
colorbar













