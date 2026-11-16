function export_figure(fig, outputFolder, baseName, S)
%EXPORT_FIGURE Export one figure as FIG, 600-DPI PNG and vector PDF.

if nargin < 4 || isempty(S)
    S = config_plot_style();
end

if ~exist(outputFolder,'dir')
    mkdir(outputFolder);
end

% Force the physical paper size used by exportgraphics/print.
set(fig, ...
    'Units','centimeters', ...
    'Position',[2 2 S.FigureWidthCm S.FigureHeightCm], ...
    'PaperUnits','centimeters', ...
    'PaperPosition',[0 0 S.FigureWidthCm S.FigureHeightCm], ...
    'PaperSize',[S.FigureWidthCm S.FigureHeightCm], ...
    'Color','w');

drawnow;

% Save an immediately viewable MATLAB figure without modifying plotted data.
oldVisibility = get(fig,'Visible');
set(fig,'Visible','on');
savefig(fig, fullfile(outputFolder,[baseName '.fig']));
set(fig,'Visible',oldVisibility);

% PNG - 600 DPI.
exportgraphics(fig, ...
    fullfile(outputFolder,[baseName '.png']), ...
    'Resolution',S.PNG_DPI, ...
    'BackgroundColor','white');

% Vector PDF. If the installed MATLAB release does not support
% ContentType='vector', fall back to painters/print.
try
    exportgraphics(fig, ...
        fullfile(outputFolder,[baseName '.pdf']), ...
        'ContentType','vector', ...
        'BackgroundColor','white');
catch
    set(fig,'Renderer','painters');
    print(fig, ...
        fullfile(outputFolder,[baseName '.pdf']), ...
        '-dpdf','-painters','-bestfit');
end
end
