function export_nominal_gain_inset(result,caseFolder,S)
%EXPORT_NOMINAL_GAIN_INSET Manuscript Fig. 7 (Case 1), one figure only.
% Full 0-75 s adaptive gains with an inset of the first 0-1 s.
% Uses SAVED data and does not create a separate Fig. 7(b).
%
% Inputs: result = ASTSMC result from main.m; S = config_plot_style().

if nargin < 3 || isempty(S), S = config_plot_style(); end
assert(isfield(result,'t') && isfield(result,'alpha'), ...
    'Expected a simulation result with fields t and alpha.');

t = result.t(:);
a = result.alpha;
assert(size(a,1)==numel(t) && size(a,2)>=2, ...
    'Invalid adaptive gain dimensions.');
zoomWindow = [0 1];
idx = t>=zoomWindow(1) & t<=zoomWindow(2);
assert(nnz(idx)>2,'No saved transient samples available for Fig. 7.');

S.FigureWidthCm = max(16,S.FigureWidthCm);
S.FigureHeightCm = max(9.5,S.FigureHeightCm);
S.LineWidth = 2;

fig = figure('Name','Fig. 7 - Nominal adaptive gains with startup inset', ...
    'NumberTitle','off','Color','w','Units','centimeters', ...
    'Position',[2 2 S.FigureWidthCm S.FigureHeightCm], ...
    'PaperUnits','centimeters', ...
    'PaperPosition',[0 0 S.FigureWidthCm S.FigureHeightCm], ...
    'PaperSize',[S.FigureWidthCm S.FigureHeightCm]);

mainPos  = [0.12 0.16 0.81 0.77];
insetPos = [0.585 0.42 0.325 0.285];

% Main axes: full 75 seconds
ax = axes('Parent',fig,'Units','normalized','Position',mainPos);
hold(ax,'on');
h1 = plot(ax,t,a(:,1),'-', 'Color',S.SMC.Color, ...
    'LineWidth',S.LineWidth);
h2 = plot(ax,t,a(:,2),'--','Color',S.STSMC.Color, ...
    'LineWidth',S.LineWidth);
format_axes(ax,S,11);
xlim(ax,[t(1) t(end)]);
amin = min(a(:)); amax = max(a(:));
ylim(ax,[min(0.9,amin-0.1) amax+0.35]);
xlabel(ax,'Time (s)','FontName',S.FontName,'FontSize',11);
ylabel(ax,'Adaptive gain','FontName',S.FontName,'FontSize',11);

% Place legend in blank upper-right area, ABOVE the zoom inset.
lgd = legend(ax,[h1 h2],{'\alpha_v','\alpha_\omega'}, ...
    'Location','none','Interpreter','tex','FontName',S.FontName, ...
    'FontSize',10,'Box','on','AutoUpdate','off');
set(lgd,'Units','normalized','Position',[0.692 0.785 0.205 0.107], ...
    'Color','white');
set(ax,'Units','normalized','Position',mainPos);

% Small inset axes: exactly the same recorded gains (0-1 s).
az = axes('Parent',fig,'Units','normalized','Position',insetPos, ...
    'Color','white');
hold(az,'on');
plot(az,t(idx),a(idx,1),'-','Color',S.SMC.Color, ...
    'LineWidth',S.LineWidth);
plot(az,t(idx),a(idx,2),'--','Color',S.STSMC.Color, ...
    'LineWidth',S.LineWidth);
format_axes(az,S,9);
xlim(az,zoomWindow);
rangeValues = a(idx,1:2);
lo=min(rangeValues(:)); hi=max(rangeValues(:));
padding=max((hi-lo)*0.12,0.1);
ylim(az,[lo-padding hi+padding]);
xticks(az,[0 0.25 0.50 0.75 1]);
xlabel(az,'Time (s)','FontName',S.FontName,'FontSize',9);
ylabel(az,'Adaptive gain','FontName',S.FontName,'FontSize',9);
text(az,0.97,0.07,'Zoom: 0-1 s', ...
    'Units','normalized','HorizontalAlignment','right', ...
    'FontName',S.FontName,'FontSize',8, ...
    'BackgroundColor','white','Margin',1, ...
    'HandleVisibility','off');

% Solid source region, matching the main axes frame width and color.
rectangle(ax,'Position',[zoomWindow(1),lo-padding, ...
    diff(zoomWindow),hi-lo+2*padding], ...
    'LineStyle','-','LineWidth',ax.LineWidth, ...
    'EdgeColor',ax.XColor, ...
    'FaceColor','none','HandleVisibility','off');

% One solid connector exactly from the ROI top-right corner to the inset top-left corner.
% The connector stays above the gain trajectories after the initial peak,
% avoids both the legend and the inset data, and marks the zoom source.
mainXL = xlim(ax); mainYL = ylim(ax);
roiAnchorX = mainPos(1) + mainPos(3) * ...
    (zoomWindow(2)-mainXL(1)) / diff(mainXL);
roiAnchorY = mainPos(2) + mainPos(4) * ...
    (hi+padding-mainYL(1)) / diff(mainYL);
insetCornerX = insetPos(1);
insetCornerY = insetPos(2) + insetPos(4);
annotation(fig,'line',[roiAnchorX insetCornerX], ...
    [roiAnchorY insetCornerY], ...
    'LineStyle','-','Color',ax.XColor, ...
    'LineWidth',ax.LineWidth);

set(ax,'Units','normalized','Position',mainPos);
set(az,'Units','normalized','Position',insetPos);

drawnow;
export_figure(fig,caseFolder,'Case1_Fig07_ASTSMC_Gains_Inset',S);
end

function format_axes(ax,S,fontSize)
set(ax,'FontName',S.FontName,'FontSize',fontSize, ...
    'LineWidth',0.8,'Box','on','TickLabelInterpreter','tex','Layer','top');
grid(ax,'on');
ax.GridAlpha=S.GridAlpha;
end
