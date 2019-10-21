function hdl = newtimef_plot(g,data,P,Pboot,mbase,alltfX,freqs,timesout)
Pboot1 = Pboot{1};
Pboot2 = Pboot{2};
P1 = P{1};
P2 = P{2};
Rboot1 = [];
Rboot2 = [];
R1 = [];
R2 = [];
alltfX1 = alltfX{1};
alltfX2 = alltfX{2};

% plotting
    % --------
    hdl = figure;
    if strcmpi(g.plotersp, 'on') | strcmpi(g.plotitc, 'on')
        g.titleall = g.title;
        %if strcmpi(g.newfig, 'on'), figure; end; % declare a new figure
        
        % using same color scale
        % ----------------------
        if ~isfield(g, 'erspmax')
            g.erspmax = max( max(max(abs(Pboot1))), max(max(abs(Pboot2))) );
        end;
        if ~isfield(g, 'itcmax')
            g.itcmax  = max( max(max(abs(Rboot1))), max(max(abs(Rboot2))) );
        end;
        
        subplot(1,3,1); % plot Condition 1
        g.title = g.titleall{1};        
        g = plottimef_for_2_conditions(P1, R1, Pboot1, Rboot1, mean(data{1},2), freqs, timesout, mbase{1}, [], [], g);
        g.itcavglim = [];
        
        subplot(1,3,2); % plot Condition 2
        g.title = g.titleall{2};        
        g.topovec = [];        
        plottimef_for_2_conditions(P2, R2, Pboot2, Rboot2, mean(data{2},2), freqs, timesout, mbase{2}, [], [], g);
        
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
            plottimef_for_2_conditions(P1-P2, Rdiff, [], [], mean(data{1},2)-mean(data{2},2), freqs, timesout, meanmbase, [], [], g);
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
                
        % same as below: plottimef(P1-P2, R2-R1, 10*resimages{1}, resimages{2}, mean(data{1},2)-mean(data{2},2), freqs, times, mbase, g);
        if strcmpi(g.plotersp, 'on') | strcmpi(g.plotitc, 'on')
            g.erspmax = []; % auto scale
            g.itcmax  = []; % auto scale
            plottimef_for_2_conditions(10*resdiff{1}, resdiff{2}, 10*resimages{1}, resimages{2}, ...
                mean(data{1},2)-mean(data{2},2), freqs, timesout, meanmbase, [], [], g);
        end;
    end;
end
