function export_zoom_figures(R, caseNo, caseFolder, S)
%EXPORT_ZOOM_FIGURES  Four publication-style zoomed inset figures.
%
%   Fig. 9     : Case 2, longitudinal sliding variable s_v
%   Fig. 10    : Case 2, ASTSMC adaptive gains
%   Fig. 11(a) : Case 3, position error (full mission + 800 kg segment)
%   Fig. 12    : Case 3, longitudinal sliding variable s_v
%
%   SAME FIGURE: a large overview axes and a small inset axes inside it.
%   The inset is placed in a low-data-density region. Legends are moved to
%   a separate empty part of the MAIN axes. The inset's x ticks and label
%   cannot overlap the main axes' x ticks/label. A solid ROI box
%   and ONE thin connector indicate the zoom source (not two crossing lines).
%
%   Plot only: does NOT change controller code, integration, signal data,
%   smoothing, initial conditions, uncertainties or performance metrics.
%   The inset reuses EXACTLY the stored STSMC/ASTSMC samples, t=27..42 s.
%   Output file names use the new suffix '_Inset'.
%
%   Replace only this file. The existing plot_deterministic_comparison.m already
%   calls export_zoom_figures(R,caseNo,caseFolder,S).

if nargin < 4 || isempty(S)
    S = config_plot_style();
end
if ~ismember(caseNo, [2 3])
    return;
end

S = normalize_style(S);
t = R.SMC.t(:);
window = [27 42];
mask = t >= window(1) & t <= window(2);
if nnz(mask) < 2
    error('export_zoom_figures:ZoomSamples', ...
        'Need at least 2 saved samples inside 27..42 s.');
end

if caseNo == 2
    create_inset(R,t,mask,window,S,caseFolder, ...
        'sliding','Case2_Fig09_Sliding_sv_Inset', ...
        'Fig. 9 - Sliding variable');
    create_inset(R,t,mask,window,S,caseFolder, ...
        'gains','Case2_Fig10_ASTSMC_Gains_Inset', ...
        'Fig. 10 - Adaptive gains');
else
    create_inset(R,t,mask,window,S,caseFolder, ...
        'position','Case3_Fig11a_Position_Error_Inset', ...
        'Fig. 11(a) - Position error');
    create_inset(R,t,mask,window,S,caseFolder, ...
        'sliding','Case3_Fig12_Sliding_sv_Inset', ...
        'Fig. 12 - Sliding variable');
end
end

function S = normalize_style(S)
% Only the 4 optional zoom figures are made slightly wider for readability.
S.FigureWidthCm  = max(S.FigureWidthCm,16.0);
S.FigureHeightCm = max(S.FigureHeightCm,9.5);
S.LineWidth = 2;                    % Data curves in BOTH axes: 2 pt
S.ZoomMainFont  = 11;
S.ZoomSmallFont = 9;
S.ZoomLegendFont = 10;
end

function create_inset(R,t,mask,window,S,folder,mode,fileBase,figureName)
fig = figure('Name',figureName,'NumberTitle','off','Color','w', ...
    'Units','centimeters','Position',[2 2 S.FigureWidthCm S.FigureHeightCm], ...
    'PaperUnits','centimeters', ...
    'PaperPosition',[0 0 S.FigureWidthCm S.FigureHeightCm], ...
    'PaperSize',[S.FigureWidthCm S.FigureHeightCm]);

% Normalized positions: [left bottom width height].
% Inset bottom >= 0.34 (main axis bottom = 0.16): the inset tick labels
% remain WELL ABOVE the main axis tick labels and the main x-axis title.
mainPos = [0.12 0.16 0.81 0.77];

switch mode
    case 'sliding'
        % Bottom 30-45%% of the main graph is clear of the large SMC swings.
        insetPos = [0.595 0.34 0.320 0.255];
        legendPos = [0.155 0.285 0.205 0.145];
        y1 = R.SMC.s(:,1);  y2 = R.STSMC.s(:,1);  y3 = R.ASTSMC.s(:,1);
        yOverview = {y1(:),y2(:),y3(:)};
        yInset = {y2(mask)*1000, y3(mask)*1000};
        colors = {S.SMC.Color,S.STSMC.Color,S.ASTSMC.Color};
        styles = {S.SMC.LineStyle,S.STSMC.LineStyle,S.ASTSMC.LineStyle};
        names = {'SMC','STSMC','ASTSMC'};
        mainLabel = 's_v (m/s)'; insetLabel = 's_v (mm/s)';
        % Extra lower space is intentional: inset + legend never obscure
        % SMC transients after t > 10 s. It changes axes only, not data.
        yMainLimits = [min(-0.135,1.07*min(y1)), ...
                       max(0.040,1.05*max(y1))];
        scaling = 1000;

    case 'position'
        insetPos = [0.595 0.46 0.320 0.27];
        legendPos = [0.270 0.300 0.205 0.145];
        y1 = R.SMC.ep(:);  y2 = R.STSMC.ep(:);  y3 = R.ASTSMC.ep(:);
        yOverview = {y1,y2,y3};
        yInset = {y2(mask)*1000, y3(mask)*1000};
        colors = {S.SMC.Color,S.STSMC.Color,S.ASTSMC.Color};
        styles = {S.SMC.LineStyle,S.STSMC.LineStyle,S.ASTSMC.LineStyle};
        names = {'SMC','STSMC','ASTSMC'};
        mainLabel = 'Position error (m)';
        insetLabel = 'Position error (mm)';
        yMainLimits = [-0.008,1.07*max([y1;y2;y3])];
        scaling = 1000;

    case 'gains'
        % Plot a blank region above gain~=1 at late times; legend below.
        insetPos = [0.595 0.49 0.320 0.265];
        legendPos = [0.705 0.275 0.200 0.120];
        a1 = R.ASTSMC.alpha(:,1); a2 = R.ASTSMC.alpha(:,2);
        yOverview = {a1(:),a2(:)};
        yInset = {a1(mask),a2(mask)};
        colors = {S.SMC.Color,S.STSMC.Color};
        styles = {'-','--'};
        names = {'\alpha_v','\alpha_\omega'};
        mainLabel = 'Adaptive gain'; insetLabel = 'Adaptive gain';
        yMainLimits = [0.9,1.08*max([a1(:);a2(:)])];
        scaling = 1;

    otherwise
        error('export_zoom_figures:UnknownMode','Unknown mode: %s',mode);
end

% --- Overview axes ---
ax = axes('Parent',fig,'Units','normalized','Position',mainPos);
hold(ax,'on');
lines = gobjects(1,numel(yOverview));
for k=1:numel(yOverview)
    lines(k)=plot(ax,t,yOverview{k}, ...
        'Color',colors{k},'LineStyle',styles{k},'LineWidth',S.LineWidth);
end
style_axes(ax,S,S.ZoomMainFont);
xlim(ax,[t(1),t(end)]);
ylim(ax,yMainLimits);
xticks(ax,0:10:70);
xlabel(ax,'Time (s)','FontName',S.FontName,'FontSize',S.ZoomMainFont);
ylabel(ax,mainLabel,'FontName',S.FontName,'FontSize',S.ZoomMainFont);

% Fixed-position legend, inside an EMPTY area of the overview axes.
% Creation of the legend precedes the inset; restore the axes position to
% stop MATLAB's automatic legend-position adjustment.
lgd=legend(ax,lines,names,'Location','none','Orientation','vertical', ...
    'Interpreter','tex','FontName',S.FontName, ...
    'FontSize',S.ZoomLegendFont,'Box','on','AutoUpdate','off');
set(lgd,'Units','normalized','Position',legendPos, ...
    'Color','white','EdgeColor',[0.34 0.34 0.34]);
set(ax,'Units','normalized','Position',mainPos);

% --- True zoom axes, still INSIDE the same MATLAB Figure ---
axSmall=axes('Parent',fig,'Units','normalized', ...
    'Position',insetPos,'Color','white','Box','on');
hold(axSmall,'on');
if strcmp(mode,'gains')
    selected = [1 2];
else
    selected = [2 3];
end
for k=1:2
    c = selected(k);
    plot(axSmall,t(mask),yInset{k}, ...
        'Color',colors{c},'LineStyle',styles{c},'LineWidth',S.LineWidth);
end
style_axes(axSmall,S,S.ZoomSmallFont);
xlim(axSmall,window);
zoomLimits=padded_limits([yInset{1}(:);yInset{2}(:)]);
if strcmp(mode,'position')
    zoomLimits(1)=0;
end
ylim(axSmall,zoomLimits);
xticks(axSmall,[27 32 37 42]);
xlabel(axSmall,'Time (s)','FontName',S.FontName,'FontSize',S.ZoomSmallFont);
ylabel(axSmall,insetLabel,'FontName',S.FontName, ...
    'FontSize',S.ZoomSmallFont);

% A tiny inset label replaces the old long inset title, freeing space.
if ~strcmp(mode,'gains')
    % For the gain figure, the top-left corner contains real data;
    % suppressing the label keeps every gain sample visible.
    text(axSmall,0.035,0.95,'Zoom: 27-42 s', ...
        'Units','normalized','HorizontalAlignment','left', ...
        'VerticalAlignment','top','FontName',S.FontName, ...
        'FontSize',8,'Color',[0.20 0.20 0.20], ...
        'BackgroundColor','white','Margin',1, ...
        'HandleVisibility','off');
end

% Solid source rectangle in the overview coordinates; Y values change
% units only for the inset, never the underlying data vectors.
outlineY=zoomLimits/scaling;
if strcmp(mode,'position')
    outlineY(1)=0;
end
r=rectangle(ax,'Position',[window(1),outlineY(1), ...
    diff(window),diff(outlineY)], ...
    'LineStyle','-','LineWidth',ax.LineWidth, ...
    'EdgeColor',ax.XColor, ...
    'FaceColor','none','HandleVisibility','off'); %#ok<NASGU>

% Only ONE thin solid connector, ending at the INSET FRAME. It cannot cross
% inset data, axis tick labels or the legend. Removing the second leader
% also prevents the 'X' crossing seen in the old figure.
add_single_connector(fig,ax,axSmall,window,outlineY,mode);

% Preserve axes dimensions after annotations; export original data.
set(ax,'Units','normalized','Position',mainPos);
set(axSmall,'Units','normalized','Position',insetPos);
drawnow;
export_figure(fig,folder,fileBase,S);
end

function style_axes(ax,S,fontSize)
set(ax,'FontName',S.FontName,'FontSize',fontSize, ...
    'LineWidth',0.8,'Box','on','TickLabelInterpreter','tex', ...
    'XColor',[0.14 0.14 0.14],'YColor',[0.14 0.14 0.14], ...
    'Layer','top');
grid(ax,'on');
ax.GridAlpha = S.GridAlpha;
ax.MinorGridAlpha = S.MinorGridAlpha;
end

function lim = padded_limits(y)
y=y(isfinite(y));
if isempty(y)
    lim=[-1 1]; return;
end
lo=min(y); hi=max(y);
range=hi-lo;
if range < 1e-8
    range = max(1e-3,abs(hi)*0.08);
end
lim=[lo-0.15*range,hi+0.15*range];
end

function add_single_connector(fig,axMain,axInset,window,yWindow,mode)
% Draw ONE solid leader from the selected ROI corner directly to the
% corresponding INNER inset frame corner (in normalized figure units).
% It must NEVER terminate in the inset plot area or be omitted due to
% distance. Width/color match the main axes frame, not the 2-pt data lines.
q = get(axInset,'Position'); % [left bottom width height], normalized
if strcmp(mode,'gains') || strcmp(mode,'position')
    % ROI is below inset: upper-right ROI -> lower-left inset frame.
    anchor = data_to_fig(axMain,window(2),yWindow(2));
    target = [q(1), q(2)];
else
    % ROI is above inset: lower-right ROI -> upper-left inset frame.
    anchor = data_to_fig(axMain,window(2),yWindow(1));
    target = [q(1), q(2)+q(4)];
end
% Both endpoints are computed from their REAL bounding boxes; no ad-hoc
% offset, and no threshold that might silently omit the connection.
annotation(fig,'line',[anchor(1) target(1)], ...
    [anchor(2) target(2)],'LineStyle','-', ...
    'Color',axMain.XColor,'LineWidth',axMain.LineWidth);
end

function xy=data_to_fig(ax,x,y)
% Numeric conversion only; axis labels/data remain unchanged.
position=get(ax,'Position');
xl=xlim(ax); yl=ylim(ax);
xy=[position(1)+position(3)*(x-xl(1))/diff(xl), ...
    position(2)+position(4)*(y-yl(1))/diff(yl)];
end
