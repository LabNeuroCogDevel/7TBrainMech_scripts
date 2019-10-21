function [ERP,P,R,mbase,timesout,freqs,Pboot,Rboot,resdiff,alltfX,PA,maskersp,maskitc,g] = custom_newtimef_2_precalculated_conditions(conditions_struct)

%%%%%%%%%%%%%%%%%%%%%%%
% compare 2 conditions precalculated
%%%%%%%%%%%%%%%%%%%%%%%

%INPUT:
%   * condition1_data: complete name (with path) of the .mat with the
%                      time frequency results for condition 1 (results must
%                      come from custom_newtimef function).
%   * condition2_data: complete name (with path) of the .mat with the
%                      time frequency results for condition 2 (results must
%                      come from custom_newtimef function).

%IMPORTANT: It is assumed that both conditions have the same timesout and
%freqs vectors, if not conditions' 2 will be used. In other words, the
%paramaters for time frequency calculation must be the same and this is
%left to the user....(Can it be checked?) Also assumes that both have the
%same nr of channels (first dimension)

%LOAD DATA 
%loaded variables as a result of custom_newtimef function will be:
%[ERP,P,R,mbase,timesout,freqs,Pboot,Rboot,resdiff,alltfX,PA,maskersp,maski
%tc,g]

ERP1 = conditions_struct.ERP1;
ERP2 = conditions_struct.ERP2;
P1 = conditions_struct.P1;
P2 = conditions_struct.P2;
R1 = conditions_struct.R1;
R2 = conditions_struct.R2;
mbase1 = conditions_struct.mbase1;
mbase2 = conditions_struct.mbase2;
Pboot1 = conditions_struct.Pboot1;
Pboot2 = conditions_struct.Pboot2;
Rboot1 = conditions_struct.Rboot1;
Rboot2 = conditions_struct.Rboot2;
alltfX1 = conditions_struct.alltfX1;
alltfX2 = conditions_struct.alltfX2;
maskersp1 = conditions_struct.maskersp1;
maskersp2 = conditions_struct.maskersp2;
maskitc1 = conditions_struct.maskitc1;
maskitc2 = conditions_struct.maskitc2;
PA1 = conditions_struct.PA1;
PA2 = conditions_struct.PA2;

timesout = conditions_struct.timesout;
freqs = conditions_struct.freqs;
g = conditions_struct.g;

%create an integrated g -> title
if iscell(g.title) && length(g.title) >= 2 % Changed that part because providing titles
    % as cells caused the function to crash (why?)
    % at line 704 (g.tlimits = tlimits) -Jean
    if length(g.title) == 2,
        g.title{3} = [ g.title{1} ' - '  g.title{2} ];
    end;
else
    disp('Warning: title must be a cell array');
    g.title = { 'Condition 1' 'Condition 2' 'Condition 1 minus Condition 2' };
end;


%cond_1_epochs = size(data{1},2);

% if ~isempty(g.timeStretchMarks)
%     [P1,R1,mbase1,timesout,freqs,Pboot1,Rboot1,alltfX1] = ...
%         newtimef( data{1}, frames, tlimits, Fs, g.cycles, 'plotitc', 'off', ...
%         'plotersp', 'off', vararginori{:}, 'lowmem', 'off', ...
%         'timeStretchMarks', g.timeStretchMarks(:,1:cond_1_epochs), ...
%         'timeStretchRefs', g.timeStretchRefs);
% else
% %     [P1,R1,mbase1,timesout,freqs,Pboot1,Rboot1,alltfX1] = ...
% %         newtimef( data{1}, frames, tlimits, Fs, g.cycles, 'plotitc', 'off', ...
% %         'plotersp', 'off', varargin{:}, 'lowmem', 'off');
%     [ERP1,P1,R1,mbase1,timesout,freqs,Pboot1,Rboot1,resdiff1,alltfX1,PA1,maskersp1,maskitc1,g] = ...
%         custom_newtimef( data{1}, frames, tlimits, Fs, g.cycles,g, 'plotitc', 'off', ...
%         'plotersp', 'off', varargin{:}, 'lowmem', 'off');
% 
% end
% 
% custom_verboseprintf(g.verbose,'\nRunning newtimef() on Condition 2 **********************\n\n');
% 
% %[P2,R2,mbase2,timesout,freqs,Pboot2,Rboot2,alltfX2] = ...
% [ERP2,P2,R2,mbase2,timesout,freqs,Pboot2,Rboot2,resdiff1,alltfX2,PA2,maskersp2,maskitc2,g] = ...
%     custom_newtimef( data{2}, frames, tlimits, Fs, g.cycles,g, 'plotitc', 'off', ...
%     'plotersp', 'off', varargin{:}, 'lowmem', 'off', ...
%     'timeStretchMarks', g.timeStretchMarks(:,cond_1_epochs+1:end), ...
%     'timeStretchRefs', g.timeStretchRefs);
%     %'plotersp', 'off', vararginori{:}, 'lowmem', 'off', ...
ERP = {ERP1,ERP2};    
PA = {PA1,PA2};
maskersp = {maskersp1,maskersp2};
maskitc = {maskitc1,maskitc2};

custom_verboseprintf(g.verbose,'\nComputing difference **********************\n\n');

% recompute power baselines
% -------------------------
if ~isnan( g.baseline(1) ) && ~isnan( mbase1(1) ) && isnan(g.powbase(1)) && strcmpi(g.commonbase, 'on')
    disp('Recomputing baseline power: using the grand mean of both conditions ...');
    mbase = (mbase1 + mbase2)/2;
    P1 = P1 + repmat(mbase1(1:size(P1,1))',[1 size(P1,2)]);
    P2 = P2 + repmat(mbase2(1:size(P1,1))',[1 size(P1,2)]);
    P1 = P1 - repmat(mbase (1:size(P1,1))',[1 size(P1,2)]);
    P2 = P2 - repmat(mbase (1:size(P1,1))',[1 size(P1,2)]);
    if ~isnan(g.alpha)
        Pboot1 = Pboot1 + repmat(mbase1(1:size(Pboot1,1))',[1 size(Pboot1,2) size(Pboot1,3)]);
        Pboot2 = Pboot2 + repmat(mbase2(1:size(Pboot1,1))',[1 size(Pboot1,2) size(Pboot1,3)]);
        Pboot1 = Pboot1 - repmat(mbase (1:size(Pboot1,1))',[1 size(Pboot1,2) size(Pboot1,3)]);
        Pboot2 = Pboot2 - repmat(mbase (1:size(Pboot1,1))',[1 size(Pboot1,2) size(Pboot1,3)]);
    end;
    custom_verboseprintf(g.verbose, '\nSubtracting the common power baseline ...\n');
    meanmbase = mbase;
    mbase = { mbase mbase mbase};
elseif strcmpi(g.commonbase, 'on')
    mbase = { NaN NaN NaN};
    meanmbase = mbase{1}; %Ramon :for bug 1657 
else
    meanmbase = (mbase1 + mbase2)/2;
    mbase = { mbase1 mbase2 meanmbase};
end;

if isnan(g.alpha)
    switch(g.condboot)
        case 'abs',  Rdiff = abs(R1)-abs(R2);
        case 'angle',  Rdiff = angle(R1)-angle(R2);
        case 'complex',  Rdiff = R1-R2;
    end;    
else
    % preprocess data and run compstat() function
    % -------------------------------------------
    alltfX1power = alltfX1.*conj(alltfX1);
    alltfX2power = alltfX2.*conj(alltfX2);

    if ~isnan(mbase{1}(1))
        mbase1 = 10.^(mbase{1}(1:size(alltfX1,1))'/20);
        mbase2 = 10.^(mbase{2}(1:size(alltfX1,1))'/20);
        alltfX1 = alltfX1./repmat(mbase1/2,[1 size(alltfX1,2) size(alltfX1,3)]);
        alltfX2 = alltfX2./repmat(mbase2/2,[1 size(alltfX2,2) size(alltfX2,3)]);
        alltfX1power = alltfX1power./repmat(mbase1,[1 size(alltfX1power,2) size(alltfX1power,3)]);
        alltfX2power = alltfX2power./repmat(mbase2,[1 size(alltfX2power,2) size(alltfX2power,3)]);
    end;

    %formula = {'log10(mean(arg1,3))'};              % toby 10.02.2006
    %formula = {'log10(mean(arg1(:,:,data),3))'};

    formula = {'log10(mean(arg1(:,:,X),3))'};
    switch g.type
        case 'coher', % take the square of alltfx and alltfy first to speed up
            formula = { formula{1} ['sum(arg2(:,:,data),3)./sqrt(sum(arg1(:,:,data),3)*length(data) )'] };
            if strcmpi(g.lowmem, 'on')
                for ind = 1:2:size(alltfX1power,1)
                    if ind == size(alltfX1,1), indarr = ind; else indarr = [ind:ind+1]; end;
                    [resdifftmp resimagestmp res1tmp res2tmp] = ...
                        condstat(formula, g.naccu, g.alpha, {'both' 'upper'}, { '' g.condboot}, ...
                        { alltfX1power(indarr,:,:) alltfX2power(indarr,:,:) }, {alltfX1(indarr,:,:) alltfX2(indarr,:,:)});
                    resdiff{1}(indarr,:)     = resdifftmp{1};   resdiff{2}(indarr,:)     = resdifftmp{2};
                    resimages{1}(indarr,:,:) = resimagestmp{1}; resimages{2}(indarr,:,:) = resimagestmp{2};
                    res1{1}(indarr,:)        = res1tmp{1};      res1{2}(indarr,:)        = res1tmp{2};
                    res2{1}(indarr,:)        = res2tmp{1};      res2{2}(indarr,:)        = res2tmp{2};
                end;
            else
                alltfXpower = { alltfX1power alltfX2power };
                alltfX      = { alltfX1 alltfX2 };
                alltfXabs   = { alltfX1abs alltfX2abs };
                [resdiff resimages res1 res2] = condstat(formula, g.naccu, g.alpha, {'both' 'upper'}, { '' g.condboot}, alltfXpower, alltfX, alltfXabs);
            end;
        case 'phasecoher2', % normalize first to speed up

            %formula = { formula{1} ['sum(arg2(:,:,data),3)./sum(arg3(:,:,data),3)'] };
            % toby 10/3/2006

            formula = { formula{1} ['sum(arg2(:,:,X),3)./sum(arg3(:,:,X),3)'] };
            alltfX1abs = sqrt(alltfX1power); % these 2 lines can be suppressed
            alltfX2abs = sqrt(alltfX2power); % by inserting sqrt(arg1(:,:,data)) instead of arg3(:,:,data))
            if strcmpi(g.lowmem, 'on')
                for ind = 1:2:size(alltfX1abs,1)
                    if ind == size(alltfX1,1), indarr = ind; else indarr = [ind:ind+1]; end;
                    [resdifftmp resimagestmp res1tmp res2tmp] = ...
                        condstat(formula, g.naccu, g.alpha, {'both' 'upper'}, { '' g.condboot}, ...
                        { alltfX1power(indarr,:,:) alltfX2power(indarr,:,:) }, {alltfX1(indarr,:,:) ...
                        alltfX2(indarr,:,:)}, { alltfX1abs(indarr,:,:) alltfX2abs(indarr,:,:) });
                    resdiff{1}(indarr,:)     = resdifftmp{1};   resdiff{2}(indarr,:)     = resdifftmp{2};
                    resimages{1}(indarr,:,:) = resimagestmp{1}; resimages{2}(indarr,:,:) = resimagestmp{2};
                    res1{1}(indarr,:)        = res1tmp{1};      res1{2}(indarr,:)        = res1tmp{2};
                    res2{1}(indarr,:)        = res2tmp{1};      res2{2}(indarr,:)        = res2tmp{2};
                end;
            else
                alltfXpower = { alltfX1power alltfX2power };
                alltfX      = { alltfX1 alltfX2 };
                alltfXabs   = { alltfX1abs alltfX2abs };
                [resdiff resimages res1 res2] = condstat(formula, g.naccu, g.alpha, {'both' 'upper'}, { '' g.condboot}, alltfXpower, alltfX, alltfXabs);
            end;
        case 'phasecoher',

            %formula = { formula{1} ['mean(arg2,3)'] };              % toby 10.02.2006
            %formula = { formula{1} ['mean(arg2(:,:,data),3)'] };

            formula = { formula{1} ['mean(arg2(:,:,X),3)'] };
            if strcmpi(g.lowmem, 'on')
                for ind = 1:2:size(alltfX1,1)
                    if ind == size(alltfX1,1), indarr = ind; else indarr = [ind:ind+1]; end;
                    alltfX1norm = alltfX1(indarr,:,:)./sqrt(alltfX1(indarr,:,:).*conj(alltfX1(indarr,:,:)));
                    alltfX2norm = alltfX2(indarr,:,:)./sqrt(alltfX2(indarr,:,:).*conj(alltfX2(indarr,:,:)));
                    alltfXpower = { alltfX1power(indarr,:,:) alltfX2power(indarr,:,:) };
                    alltfXnorm  = { alltfX1norm alltfX2norm };
                    [resdifftmp resimagestmp res1tmp res2tmp] = ...
                        condstat(formula, g.naccu, g.alpha, {'both' 'both'}, { '' g.condboot}, ...
                        alltfXpower, alltfXnorm);
                    resdiff{1}(indarr,:)     = resdifftmp{1};   resdiff{2}(indarr,:)     = resdifftmp{2};
                    resimages{1}(indarr,:,:) = resimagestmp{1}; resimages{2}(indarr,:,:) = resimagestmp{2};
                    res1{1}(indarr,:)        = res1tmp{1};      res1{2}(indarr,:)        = res1tmp{2};
                    res2{1}(indarr,:)        = res2tmp{1};      res2{2}(indarr,:)        = res2tmp{2};
                end;
            else
                alltfX1norm = alltfX1./sqrt(alltfX1.*conj(alltfX1));
                alltfX2norm = alltfX2./sqrt(alltfX2.*conj(alltfX2)); % maybe have to suppress preprocessing -> lot of memory
                alltfXpower = { alltfX1power alltfX2power };
                alltfXnorm  = { alltfX1norm alltfX2norm };
                [resdiff resimages res1 res2] = condstat(formula, g.naccu, g.alpha, {'both' 'both'}, { '' g.condboot}, ...
                    alltfXpower, alltfXnorm);
            end;
    end;

    R1 = res1{2};
    R2 = res2{2};
    Rdiff = resdiff{2};
    Pboot = { Pboot1 Pboot2 10*resimages{1} };
    Rboot = { Rboot1 Rboot2 resimages{2} };
end;
P = { P1 P2 P1-P2 };
R = { R1 R2 Rdiff };

if nargout >= 8, alltfX = { alltfX1 alltfX2 }; end;

return; % ********************************** END FOR MULTIPLE CONDITIONS
