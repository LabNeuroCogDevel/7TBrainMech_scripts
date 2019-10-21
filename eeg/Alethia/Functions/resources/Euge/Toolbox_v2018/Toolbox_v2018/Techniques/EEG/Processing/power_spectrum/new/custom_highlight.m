function custom_highlight(ax, times, regions, highlightmode)
color1 = [0.75 0.75 0.75];
color2 = [0 0 0];
yl  = ylim;

if ~strcmpi(highlightmode, 'background')
    yl2 = [ yl(1)-(yl(2)-yl(1))*0.15   yl(1)-(yl(2)-yl(1))*0.1 ];
    tmph = patch([times(1) times(end) times(end) times(1)], ...
        [yl2(1) yl2(1) yl2(2) yl2(2)], [1 1 1]); hold on;
    ylim([ yl2(1) yl(2)]);
    set(tmph, 'edgecolor', [1 1 1]);
end;

if ~isempty(regions)
    axes(ax);
    in_a_region = 0;
    for index=1:length(regions)
        if regions(index) && ~in_a_region
            tmpreg(1) = times(index);
            in_a_region = 1;
        end;
        if ~regions(index) && in_a_region
            tmpreg(2) = times(index);
            in_a_region = 0;
            if strcmpi(highlightmode, 'background')
                tmph = patch([tmpreg(1) tmpreg(2) tmpreg(2) tmpreg(1)], ...
                    [yl(1) yl(1) yl(2) yl(2)], color1); hold on;
                set(tmph, 'edgecolor', color1);
            else
                tmph = patch([tmpreg(1) tmpreg(2) tmpreg(2) tmpreg(1)], ...
                    [yl2(1) yl2(1) yl2(2) yl2(2)], color2); hold on;
                set(tmph, 'edgecolor', color2);
            end;
        end;
    end;
end;