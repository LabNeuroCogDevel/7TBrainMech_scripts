function [ERP,P,R,mbase,timesout,freqs,Pboot,Rboot,resdiff,alltfX,PA,maskersp,maskitc,g] = custom_newtimef(data, frames, tlimits, Fs, varwin,g, varargin)

if isempty(g)
    [g,data,trials,timefreqopts,guicall]  = get_newtimef_g_struct(data, frames, tlimits, Fs, varwin, varargin{:});
    g.trials = trials;
    g.timefreqopts = timefreqopts;
    g.guicall = guicall;
else
    trials = g.trials;
    guicall = g.guicall;
    timefreqopts = g.timefreqopts;
end

if iscell(data)
    [ERP,P,R,mbase,timesout,freqs,Pboot,Rboot,resdiff,alltfX,PA,maskersp,maskitc,g] = custom_newtimef_2_conditions(g,data, frames, tlimits, Fs, varwin, guicall, varargin{:});       
else
    resdiff = [];
    %%%%%%%%%%%%%%%%%%%%%%
    % display text to user (computation perfomed only for display)
    %%%%%%%%%%%%%%%%%%%%%%
    custom_verboseprintf(g.verbose, 'Computing Event-Related Spectral Perturbation (ERSP) and\n');
    switch g.type
        case 'phasecoher',  custom_verboseprintf(g.verbose, '  Inter-Trial Phase Coherence (ITC) images based on %d trials\n',trials);
        case 'phasecoher2', custom_verboseprintf(g.verbose, '  Inter-Trial Phase Coherence 2 (ITC) images based on %d trials\n',trials);
        case 'coher',       custom_verboseprintf(g.verbose, '  Linear Inter-Trial Coherence (ITC) images based on %d trials\n',trials);
    end;
    custom_verboseprintf(g.verbose, '  of %d frames sampled at %g Hz.\n',g.frames,g.srate);
    custom_verboseprintf(g.verbose, 'Each trial contains samples from %1.0f ms before to\n',g.tlimits(1));
    custom_verboseprintf(g.verbose, '  %1.0f ms after the timelocking event.\n',g.tlimits(2));
    if ~isnan(g.alpha)
        custom_verboseprintf(g.verbose, 'Only significant values (permutation statistics p<%g) will be colored;\n',g.alpha)
        custom_verboseprintf(g.verbose, '  non-significant values will be plotted in green\n');
    end
    custom_verboseprintf(g.verbose,'  Image frequency direction: %s\n',g.hzdir);

    if isempty(g.precomputed)
        % -----------------------------------------
        % detrend over epochs (trials) if requested
        % -----------------------------------------
        if strcmpi(g.rmerp, 'on')
            if ndims(data) == 2
                 data = data - mean(data,2)*ones(1, length(data(:))/g.frames);
            else data = data - repmat(mean(data,3), [1 1 trials]);
            end;
        end;

        % ----------------------------------------------------
        % compute time frequency decompositions, power and ITC
        % ----------------------------------------------------
        if length(g.timesout) > 1,   tmioutopt = { 'timesout' , g.timesout };
        elseif ~isempty(g.ntimesout) tmioutopt = { 'ntimesout', g.ntimesout };
        else                         tmioutopt = { 'ntimesout', g.timesout };
        end;

        [alltfX freqs timesout R] = timefreq(data, g.srate, tmioutopt{:}, ...
            'winsize', g.winsize, 'tlimits', g.tlimits, 'detrend', g.detrend, ...
            'itctype', g.type, 'wavelet', g.cycles, 'verbose', g.verbose, ...
            'padratio', g.padratio, 'freqs', g.freqs, 'freqscale', g.freqscale, ...
            'nfreqs', g.nfreqs, 'timestretch', {g.timeStretchMarks', g.timeStretchRefs}, timefreqopts{:});
    else
        alltfX   = g.precomputed.tfdata;
        timesout = g.precomputed.times;
        freqs    = g.precomputed.freqs;
        if strcmpi(g.precomputed.recompute, 'ersp')
            R = [];
        else
            switch g.itctype
                case 'coher',       R = alltfX ./ repmat(sqrt(sum(alltfX .* conj(alltfX),3) * size(alltfX,3)), [1 1 size(alltfX,3)]);
                case 'phasecoher2', R = alltfX ./ repmat(sum(sqrt(alltfX .* conj(alltfX)),3), [1 1 size(alltfX,3)]);
                case 'phasecoher',  R = alltfX ./ sqrt(alltfX .* conj(alltfX));
            end;
            P = []; mbase = []; return;
        end;
    end;

    if g.cycles(1) == 0
        alltfX = 2/0.375*alltfX/g.winsize; % TF and MC (12/11/2006): normalization, divide by g.winsize
        P  = alltfX.*conj(alltfX); % power    
        % TF and MC (12/14/2006): multiply by 2 account for negative frequencies,
        % and ounteract the reduction by a factor 0.375 that occurs as a result of 
        % cosine (Hann) tapering. Refer to Bug 446
        % Modified again 04/29/2011 due to comment in bug 1032
    else 
        P  = alltfX.*conj(alltfX); % power for wavelets
    end;

    % ---------------
    % baseline length
    % ---------------
    if size(g.baseline,2) == 2
        baseln = [];
        for index = 1:size(g.baseline,1)
            tmptime   = find(timesout >= g.baseline(index,1) & timesout <= g.baseline(index,2));
            baseln = union_bc(baseln, tmptime);
        end;
        if length(baseln)==0
            error( [ 'There are no sample points found in the default baseline.' 10 ...
                     'This may happen even though data time limits overlap with' 10 ...
                     'the baseline period (because of the time-freq. window width).' 10 ... 
                     'Either disable the baseline, change the baseline limits.' ] );
        end
    else
        if ~isempty(find(timesout < g.baseline))
             baseln = find(timesout < g.baseline); % subtract means of pre-0 (centered) windows
        else baseln = 1:length(timesout); % use all times as baseline
        end
    end;

    if ~isnan(g.alpha) && length(baseln)==0
        custom_verboseprintf(g.verbose, 'timef(): no window centers in baseline (times<%g) - shorten (max) window length.\n', g.baseline)
        return
    end

    % -----------------------------------------
    % remove baseline on a trial by trial basis
    % -----------------------------------------
    if strcmpi(g.trialbase, 'on'), tmpbase = baseln;
    else                           tmpbase = 1:size(P,2); % full baseline
    end;
    if ndims(P) == 4
        if ~strcmpi(g.trialbase, 'off') && isnan( g.powbase(1) )
            mbase = mean(P(:,:,tmpbase,:),3);
            if strcmpi(g.basenorm, 'on')
                 mstd = std(P(:,:,tmpbase,:),[],3);
                 P = bsxfun(@rdivide, bsxfun(@minus, P, mbase), mstd);
            else P = bsxfun(@rdivide, P, mbase);
            end;
        end;
    else
        if ~strcmpi(g.trialbase, 'off') && isnan( g.powbase(1) )
            mbase = mean(P(:,tmpbase,:),2);
            if strcmpi(g.basenorm, 'on')
                mstd = std(P(:,tmpbase,:),[],2);
                P = (P-repmat(mbase,[1 size(P,2) 1]))./repmat(mstd,[1 size(P,2) 1]); % convert to log then back to normal
            else
                P = P./repmat(mbase,[1 size(P,2) 1]); 
                %P = 10 .^ (log10(P) - repmat(log10(mbase),[1 size(P,2) 1])); % same as above
            end;
        end;
    end;
    if ~isempty(g.precomputed)
        return; % return single trial power
    end;

    % -----------------------
    % compute baseline values
    % -----------------------
    if isnan(g.powbase(1))

        custom_verboseprintf(g.verbose, 'Computing the mean baseline spectrum\n');
        if ndims(P) == 4
            if ndims(P) > 3, Pori  = mean(P, 4); else Pori = P; end; 
            mbase = mean(Pori(:,:,baseln),3);
        else
            if ndims(P) > 2, Pori  = mean(P, 3); else Pori = P; end; 
            mbase = mean(Pori(:,baseln),2);
        end;
    else
        custom_verboseprintf(g.verbose, 'Using the input baseline spectrum\n');
        mbase    = g.powbase; 
        if strcmpi(g.scale, 'log'), mbase = 10.^(mbase/10); end; 
        if size(mbase,1) == 1 % if input was a row vector, flip to be a column
            mbase = mbase';
        end;
    end
    baselength = length(baseln);

    % -------------------------
    % remove baseline (average)
    % -------------------------
    % original ERSP baseline removal
    if ~strcmpi(g.trialbase, 'on')
        if ~isnan( g.baseline(1) ) && any(~isnan( mbase(1) )) && strcmpi(g.basenorm, 'off')
            P = bsxfun(@rdivide, P, mbase); % use single trials
        % ERSP baseline normalized
        elseif ~isnan( g.baseline(1) ) && ~isnan( mbase(1) ) && strcmpi(g.basenorm, 'on')

            if ndims(Pori) == 3, 
                 mstd = std(Pori(:,:,baseln),[],3);
            else mstd = std(Pori(:,baseln),[],2);
            end;
            P = bsxfun(@rdivide, bsxfun(@minus, P, mbase), mstd);
        end;
    end;

    % ----------------
    % phase amp option
    % ----------------
    if strcmpi(g.phsamp, 'on')
        disp( 'phsamp option is deprecated');
        %  switch g.phsamp
        %  case 'on'
        %PA = zeros(size(P,1),size(P,1),g.timesout); % NB: (freqs,freqs,times)
        % $$$ end                                             %       phs   amp
        %PA (freq x freq x time)
        %PA(:,:,j) = PA(:,:,j)  + (tmpX ./ abs(tmpX)) * ((P(:,j)))';
        % x-product: unit phase column
        % times amplitude row

        %tmpcx(1,:,:) = cumulX; % allow ./ below
        %for jj=1:g.timesout
        %    PA(:,:,jj) = PA(:,:,jj) ./ repmat(P(:,jj)', [size(P,1) 1]);
        %end
    end

    % ---------
    % bootstrap
    % --------- % this ensures that if bootstrap limits provided that no
    % 'alpha' won't prevent application of the provided limits
    if ~isnan(g.alpha) | ~isempty(find(~isnan(g.pboot))) | ~isempty(find(~isnan(g.rboot)))% if bootstrap analysis requested . . .

        % ERSP bootstrap
        % --------------
        if ~isempty(find(~isnan(g.pboot))) % if ERSP bootstrap limits provided already
            Pboot = g.pboot(:);
        else
            if size(g.baseboot,2) == 1
                if g.baseboot == 0, baselntmp = [];
                elseif ~isnan(g.baseline(1))
                    baselntmp = baseln;
                else baselntmp = find(timesout <= 0); % if it is empty use whole epoch
                end;
            else
                baselntmp = [];
                for index = 1:size(g.baseboot,1)
                    tmptime   = find(timesout >= g.baseboot(index,1) & timesout <= g.baseboot(index,2));
                    if isempty(tmptime),
                        fprintf('Warning: empty baseline interval [%3.2f %3.2f]\n', g.baseboot(index,1), g.baseboot(index,2));
                    end;
                    baselntmp = union_bc(baselntmp, tmptime);
                end;
            end;
            if prod(size(g.baseboot)) > 2
                fprintf('Permutation statistics will use data in multiple selected windows.\n');
            elseif size(g.baseboot,2) == 2
                fprintf('Permutation statistics will use data in range %3.2g-%3.2g ms.\n', g.baseboot(1),  g.baseboot(2));
            elseif g.baseboot
                fprintf('   %d permutation statistics windows in baseline (times<%g).\n', length(baselntmp), g.baseboot)
            end;

            % power significance
            % ------------------
            if strcmpi(g.boottype, 'shuffle')
                formula = 'mean(arg1,3);';
                [ Pboot Pboottrialstmp Pboottrials] = bootstat(P, formula, 'boottype', 'shuffle', ...
                    'label', 'ERSP', 'bootside', 'both', 'naccu', g.naccu, ...
                    'basevect', baselntmp, 'alpha', g.alpha, 'dimaccu', 2 );
                clear Pboottrialstmp;
            else
                center = 0;
                if strcmpi(g.basenorm, 'off'), center = 1; end;

                % bootstrap signs
                Pboottmp    = P;
                Pboottrials = zeros([ size(P,1) size(P,2) g.naccu ]);
                for index = 1:g.naccu
                    Pboottmp = (Pboottmp-center).*(ceil(rand(size(Pboottmp))*2-1)*2-1)+center;
                    Pboottrials(:,:,index) = mean(Pboottmp,3);
                end;
                Pboot = [];
            end;
            if size(Pboot,2) == 1, Pboot = Pboot'; end;
        end;

        % ITC bootstrap
        % -------------
        if ~isempty(find(~isnan(g.rboot))) % if itc bootstrap provided
            Rboot = g.rboot;
        else
            if ~isempty(find(~isnan(g.pboot))) % if ERSP limits were provided (but ITC not)
                if size(g.baseboot,2) == 1
                    if g.baseboot == 0, baselntmp = [];
                    elseif ~isnan(g.baseline(1))
                        baselntmp = baseln;
                    else baselntmp = find(timesout <= 0); % if it is empty use whole epoch
                    end;
                else
                    baselntmp = [];
                    for index = 1:size(g.baseboot,1)
                        tmptime   = find(timesout >= g.baseboot(index,1) && timesout <= g.baseboot(index,2));
                        if isempty(tmptime),
                            fprintf('Warning: empty baseline interval [%3.2f %3.2f]\n', g.baseboot(index,1), g.baseboot(index,2));
                        end;
                        baselntmp = union_bc(baselntmp, tmptime);
                    end;
                end;
                if prod(size(g.baseboot)) > 2
                    fprintf('Permutation statistics will use data in multiple selected windows.\n');
                elseif size(g.baseboot,2) == 2
                    fprintf('Permutation statistics will use data in range %3.2g-%3.2g ms.\n', g.baseboot(1),  g.baseboot(2));
                elseif g.baseboot
                    fprintf('   %d permutation statistics windows in baseline (times<%g).\n', length(baselntmp), g.baseboot)
                end;
            end;        
            % ITC significance
            % ----------------
            inputdata = alltfX;
            switch g.type
                case 'coher',       formula = [ 'sum(arg1,3)./sqrt(sum(arg1.*conj(arg1),3))/ sqrt(' int2str(size(alltfX,3)) ');' ];
                case 'phasecoher',  formula = [ 'mean(arg1,3);' ]; inputdata = alltfX./sqrt(alltfX.*conj(alltfX));
                case 'phasecoher2', formula = [ 'sum(arg1,3)./sum(sqrt(arg1.*conj(arg1)),3);' ];
            end;
            if strcmpi(g.boottype, 'randall'), dimaccu = []; g.boottype = 'rand';
            else										 dimaccu = 2;
            end;
            [Rboot Rboottmp Rboottrials] = bootstat(inputdata, formula, 'boottype', g.boottype, ...
                'label', 'ITC', 'bootside', 'upper', 'naccu', g.naccu, ...
                'basevect', baselntmp, 'alpha', g.alpha, 'dimaccu', 2 );
            fprintf('\n');
            clear Rboottmp;        
        end;
    else
        Pboot = []; Rboot = [];
    end

    % average the power
    % -----------------
    PA = P;
    if ndims(P) == 4,     P = mean(P, 4);
    elseif ndims(P) == 3, P = mean(P, 3);
    end;

    % correction for multiple comparisons
    % -----------------------------------
    maskersp = [];
    maskitc  = []; 
    if ~isnan(g.alpha)
        if isempty(find(~isnan(g.pboot))) % if ERSP lims not provided
            if ndims(Pboottrials) < 3, Pboottrials = Pboottrials'; end;
            exactp_ersp = custom_compute_pvals(P, Pboottrials);
            if strcmpi(g.mcorrect, 'fdr')
                alphafdr = fdr(exactp_ersp, g.alpha);
                if alphafdr ~= 0
                    fprintf('ERSP correction for multiple comparisons using FDR, alpha_fdr = %3.6f\n', alphafdr);
                else fprintf('ERSP correction for multiple comparisons using FDR, nothing significant\n', alphafdr);
                end;
                maskersp = exactp_ersp <= alphafdr;
            else
                maskersp = exactp_ersp <= g.alpha;
            end;
        end;    
        if isempty(find(~isnan(g.rboot))) % if ITC lims not provided
            exactp_itc  = custom_compute_pvals(abs(R), abs(Rboottrials'));        
            if strcmpi(g.mcorrect, 'fdr')
                alphafdr = fdr(exactp_itc, g.alpha);
                if alphafdr ~= 0
                    fprintf('ITC  correction for multiple comparisons using FDR, alpha_fdr = %3.6f\n', alphafdr);
                else fprintf('ITC  correction for multiple comparisons using FDR, nothing significant\n', alphafdr);
                end;
                maskitc = exactp_itc <= alphafdr;
            else
                maskitc = exactp_itc  <= g.alpha;
            end
        end;
    end;

    % convert to log if necessary
    % ---------------------------
    if strcmpi(g.scale, 'log')
        if ~isnan( g.baseline(1) ) && ~isnan( mbase(1) ) && strcmpi(g.trialbase, 'off'), mbase = log10(mbase)*10; end;
        P = 10 * log10(P);
        if ~isempty(Pboot)
            Pboot = 10 * log10(Pboot);
        end;
    end;
    if isempty(Pboot) && exist('maskersp')
        Pboot = maskersp;
    end;

    % auto scalling
    % -------------
    if isempty(g.erspmax)
        g.erspmax = [max(max(abs(P)))]/2;
        if strcmpi(g.scale, 'abs') && strcmpi(g.basenorm, 'off') % % of baseline
            g.erspmax = [max(max(abs(P)))];
            if g.erspmax > 1
                 g.erspmax = [1-(g.erspmax-1) g.erspmax];
            else g.erspmax = [g.erspmax 1+(1-g.erspmax)];
            end;
        end;
        %g.erspmax = [-g.erspmax g.erspmax]+1;
    end;
    
    if ndims(P) == 3
        P = squeeze(P(2,:,:,:));
        R = squeeze(R(2,:,:,:));
        mbase = squeeze(mbase(2,:));
        ERP = mean(squeeze(data(1,:,:)),2);
    else      
        ERP = mean(data,2);
    end;
    
    % --------------
    % format outputs
    % --------------
    if strcmpi(g.outputformat, 'old')
        R = abs(R); % convert coherence vector to magnitude
        if strcmpi(g.scale, 'log'), mbase = 10^(mbase/10); end;
    end;
    if strcmpi(g.verbose, 'on')
        disp('Note: Add output variables to command line call in history to');
        disp('      retrieve results and use the tftopo function to replot them');
    end;
    mbase = mbase';


end
    