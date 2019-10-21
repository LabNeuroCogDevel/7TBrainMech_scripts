function [hdl] =  m_newtimef_2_conditons_plotting(g,P,Pboot,R,Rboot,mbase,freqs,timesout,all_tfX)

% % --------
% % plotting
% % --------
if strcmpi(g.plotersp, 'on') || strcmpi(g.plotitc, 'on')
    if ndims(P) == 3
        P = squeeze(P(2,:,:,:)); %¿Por qué otra vez?
        R = squeeze(R(2,:,:,:));
        mbase = squeeze(mbase(2,:));
        %ERP = mean(squeeze(data(1,:,:)),2);
    else      
        %ERP = mean(data,2);
    end;
    if strcmpi(g.plottype, 'image')
        plottimef_for_2_conditions(P, R, Pboot, Rboot, freqs, times, mbase, maskersp, maskitc, g);
    else
        plotallcurves(P, R, Pboot, Rboot, freqs, times, mbase, g);
    end;
end;


P1 = P{1};
P2 = P{2};
P1_2 = P{3};

Pboot1 = [];
Pboot2 = [];

R1 = [];
R2 = [];
R1_2=[];
Rboot1 = [];
Rboot2 = [];

alltfX1=all_tfX{1}; %suj*channel*freq*tiempo*epoch
alltfX2=all_tfX{2};

if ~isempty(Pboot)
    Pboot1 = Pboot{1};
    Pboot2 = Pboot{2};
end
if ~isempty(R)
    R1 = R{1};
    R2 = R{2};
    R1_2 = R{3};
end
if ~isempty(Rboot)
    Rboot1 = Rboot{1};
    Rboot2 = Rboot{2};
end

% plotting
% --------
hdl = [];
g.plotersp = 'on';
if strcmpi(g.plotersp, 'on') | strcmpi(g.plotitc, 'on') %¿Para  qué está este if? Es obvio que va a entrar.
    hdl = figure;
    g.titleall = g.title;

    % using same color scale
    % ----------------------
    if ~isfield(g, 'erspmax')
        g.erspmax = max( max(max(abs(Pboot1))), max(max(abs(Pboot2))) );
    end;

    subplot(1,3,1); % plot Condition 1
    g.title = g.titleall{1};        
    g = plottimef_for_2_conditions(P1, R1, Pboot1, Rboot1, freqs, timesout, mbase{1}, [], [], g);
    %g = plottimef_for_2_conditions(P1, R1, Pboot1, Rboot1, mean(data{1},2), freqs, timesout, mbase{1}, [], [], g);
    g.itcavglim = [];

    subplot(1,3,2); % plot Condition 2
    g.title = g.titleall{2};        
    g.topovec = [];        
    %plottimef_for_2_conditions(P2, R2, Pboot2, Rboot2, mean(data{2},2), freqs, timesout, mbase{2}, [], [], g);
    plottimef_for_2_conditions(P2, R2, Pboot2, Rboot2,  freqs, timesout, mbase{2}, [], [], g);

    subplot(1,3,3); % plot Condition 1 - Condition 2
    g.title =  g.titleall{3};
end;

if isnan(g.alpha)
    switch(g.condboot)
        case 'abs',  Rdiff = abs(R1)-abs(R2);
        case 'angle',  Rdiff = angle(R1)-angle(R2);
        case 'complex',  Rdiff = R1-R2;
    end;
    if strcmpi(g.plotersp, 'on') | strcmpi(g.plotitc, 'on')
        %g.erspmax = []; g.itcmax  = []; % auto scale inserted for diff
        %plottimef_for_2_conditions(P1-P2, Rdiff, [], [], mean(data{1},2)-mean(data{2},2), freqs, timesout, meanmbase, [], [], g);
        meanmbase = (mbase{1} + mbase{2})/2;
        plottimef_for_2_conditions(P1_2, Rdiff, [], [], freqs, timesout, meanmbase, [], [], g);
    end;
else
    % preprocess data and run compstat() function
    % -------------------------------------------
    alltfX1power = alltfX1.*conj(alltfX1);
    alltfX2power = alltfX2.*conj(alltfX2);

    if ~isnan(mbase{1}(1))
        mbase1 = 10.^(mbase{1}(1:size(alltfX1,3))'/20);
        mbase2 = 10.^(mbase{2}(1:size(alltfX2,3))'/20);
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

    % same as below: plottimef(P1-P2, R2-R1, 10*resimages{1}, resimages{2}, mean(data{1},2)-mean(data{2},2), freqs, times, mbase, g);
    if strcmpi(g.plotersp, 'on') | strcmpi(g.plotitc, 'on')
        g.erspmax = []; % auto scale
        g.itcmax  = []; % auto scale
        plottimef_for_2_conditions(10*resdiff{1}, resdiff{2}, 10*resimages{1}, resimages{2}, ...
            mean(data{1},2)-mean(data{2},2), freqs, timesout, meanmbase, [], [], g);
    end;
    R1 = res1{2};
    R2 = res2{2};
    Rdiff = resdiff{2};
    Pboot = { Pboot1 Pboot2 10*resimages{1} };
    Rboot = { Rboot1 Rboot2 resimages{2} };
end;

return; % ********************************** END FOR MULTIPLE CONDITIONS
end
