function [sym, count] = s_transf(X,cfg)%SF, kernel)
tic


chan_sel  = cfg.chan_sel;
data_sel  = cfg.data_sel;
taus   = cfg.taus;
kernel = cfg.kernel;

for tau = 1:size(taus,2)  %% 1: or 3:    
    %%% filter -> this one uses fieldtrip but please replace it and
    %%% compare the results

    %filter_freq = 80/taus(tau);
    filter_freq = cfg.sf/taus(tau)/cfg.kernel;

    disp(['Filtering @ ' num2str(filter_freq) ' Hz'])

    nTrials = size(X,3);
    Xf      = zeros(size(X));

    for nT =1:nTrials
        Xf(:,:,nT) = ft_preproc_lowpassfilter(squeeze(X(:,:,nT)),cfg.sf,filter_freq );
    end

    %disp('done filtering...')

    %%%
    Xf = Xf(chan_sel,data_sel,:); %%%
    %%%%
    %%% PE calculation

    %disp('PE calculation')

    sym{tau} = zeros(size(Xf,1),size(Xf,2)-(kernel-1)*taus(tau),size(Xf,3));
    count{tau} = zeros(size(Xf,1),factorial(kernel),size(Xf,3));


    for trial = 1:size(Xf,3)

        %disp(['trial ' num2str(trial) ' of ' num2str(size(Xf,3))])

        [sym{tau}(:,:,trial), count{tau}(:,:,trial), ~] = pe_paralel(squeeze(Xf(:,:,trial))',kernel,taus(tau));

        count{tau}(:,:,trial) = count{tau}(:,:,trial)/size(sym{tau},2);

    end
end


end




