function custom_plotallcurves(P, R, Pboot, Rboot, ERP, freqs, times, mbase, g)

if ~isreal(R)
    Rangle = angle(R);
    R = abs(R); % convert coherence vector to magnitude
    setylim = 1;
else
    Rangle = zeros(size(R)); % Ramon: if isreal(R) then we get an error because Rangle does not exist
    Rsign = ones(size(R));
    setylim = 0;
end;

if strcmpi(g.plotitc, 'on') | strcmpi(g.plotersp, 'on')
    verboseprintf(g.verbose, '\nNow plotting...\n');
    pos = get(gca,'position');
    q = [pos(1) pos(2) 0 0];
    s = [pos(3) pos(4) pos(3) pos(4)];
end;

% time unit
% ---------
if times(end) > 10000
    times = times/1000;
    timeunit = 's';
else
    timeunit = 'ms';
end;

if strcmpi(g.plotersp, 'on')
    %
    %%%%%%% image the ERSP %%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    if strcmpi(g.plotitc, 'on'), subplot(2,1,1); end;
    set(gca, 'tag', 'ersp');
    alllegend = {};

    for index = 1:length(freqs)
        alllegend{index} = [ num2str(freqs(index)) 'Hz baseline ' num2str(mbase(index)) ' dB' ];
    end;
    if strcmpi(g.plotmean, 'on') && freqs(1) ~= freqs(end)
        alllegend = { alllegend{:} [ num2str(freqs(1)) '-' num2str(freqs(end)) ...
            'Hz mean baseline ' num2str(mean(mbase)) ' dB' ] };
    end;
    plotcurve(times, P, 'maskarray', Pboot, 'title', 'ERSP', ...
        'xlabel', [ 'Time (' timeunit ')' ], 'ylabel', 'dB', 'ylim', [-g.erspmax g.erspmax], ...
        'vert', g.vert, 'marktimes', g.marktimes, 'legend', alllegend, ...
        'linewidth', g.linewidth, 'highlightmode', g.highlightmode, 'plotmean', g.plotmean);
end;

if strcmpi(g.plotitc, 'on')
    %
    %%%%%%%%%%%% Image the ITC %%%%%%%%%%%%%%%%%%
    %
    if strcmpi(g.plotersp, 'on'), subplot(2,1,2); end;
    set(gca, 'tag', 'itc');
    if abs(R(1,1)-1) < 0.0001, g.plotphaseonly = 'on'; end;
    if strcmpi(g.plotphaseonly, 'on') % plot ITC phase instead of amplitude (e.g. for continuous data)
        RR = Rangle/pi*180;
    else RR = R;
    end;

    % find regions of significance
    % ----------------------------
    alllegend = {};
    for index = 1:length(freqs)
        alllegend{index} = [ num2str(freqs(index)) 'Hz baseline ' num2str(mbase(index)) ' dB' ];
    end;
    if strcmpi(g.plotmean, 'on') && freqs(1) ~= freqs(end)
        alllegend = { alllegend{:} [ num2str(freqs(1)) '-' num2str(freqs(end)) ...
            'Hz mean baseline ' num2str(mean(mbase)) ' dB' ] };
    end;
    plotcurve(times, RR, 'maskarray', Rboot, 'val2mask', R, 'title', 'ITC', ...
        'xlabel', [ 'Time (' timeunit ')' ], 'ylabel', 'dB', 'ylim', g.itcmax, ...
        'vert', g.vert, 'marktimes', g.marktimes, 'legend', alllegend, ...
        'linewidth', g.linewidth, 'highlightmode', g.highlightmode, 'plotmean', g.plotmean);
end;

if strcmpi(g.plotitc, 'on') | strcmpi(g.plotersp, 'on')
    %
    %%%%%%%%%%%%%%% plot a topoplot() %%%%%%%%%%%%%%%%%%%%%%%
    %
    if (~isempty(g.topovec))
        h(12) = axes('Position',[-.1 .43 .2 .14].*s+q);
        if length(g.topovec) == 1
            topoplot(g.topovec,g.elocs,'electrodes','off', ...
                'style', 'blank', 'emarkersize1chan', 10);
        else
            topoplot(g.topovec,g.elocs,'electrodes','off');
        end;
        axis('square')
    end

    try, icadefs; set(gcf, 'color', BACKCOLOR); catch, end;
    if (length(g.title) > 0) && ~iscell(g.title)
        axes('Position',pos,'Visible','Off');
        h(13) = text(-.05,1.01,g.title);
        set(h(13),'VerticalAlignment','bottom')
        set(h(13),'HorizontalAlignment','left')
        set(h(13),'FontSize',g.TITLE_FONT);
    end

    try, axcopy(gcf); catch, end;
end;