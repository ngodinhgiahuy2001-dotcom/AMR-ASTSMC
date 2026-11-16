function fileBase = export_sensitivity_common_scale(ITAE,UP,DOWN,CASE_NO,p0,outFolder,SHOW_FIGURE)
% EXPORT_SENSITIVITY_COMMON_SCALE
% Fig. 18: identical x/y/z limits, Z ticks, colors, camera angle and size
% for nominal, external disturbances, and disturbances + payload.
%
% No title is drawn; (a), (b), (c) and the condition names belong in Word.
% Crucially, Z limits and color limits BOTH use [1.4, 2.7].
% The archived combined maximum is 2.6977843908: 2.65 would clip data.
%
% This is a display-only export. ITAE, UP, DOWN and CSV/MAT values are not
% modified. Creates editable FIG, 600-dpi PNG and vector PDF.

if nargin < 7 || isempty(SHOW_FIGURE), SHOW_FIGURE=false; end
validateattributes(CASE_NO, {'numeric'}, {'scalar','integer','>=',1,'<=',3});
assert(isequal(size(ITAE),size(UP),size(DOWN)), ...
    'ITAE/UP/DOWN must be matrices of identical size.');
assert(all(isfinite(ITAE(:))), 'Incomplete ITAE grid: review failed runs first.');
if ~exist(outFolder,'dir'), mkdir(outFolder); end

Z_COMMON = [1.40, 2.70];
if min(ITAE(:)) < Z_COMMON(1)-1e-10 || max(ITAE(:)) > Z_COMMON(2)+1e-10
    error(['Common Z/color limits [1.40, 2.70] do not cover this dataset. ',...
           'Adjust the COMMON limits based on ALL three cases; do not clip results.']);
end

if SHOW_FIGURE, vis='on'; else, vis='off'; end
fig = figure('Visible',vis,'Color','w','Units','centimeters', ...
    'Position',[2 2 17.5 12.2], 'Name',sprintf('Sensitivity Case %d',CASE_NO), ...
    'NumberTitle','off');
ax = axes('Parent',fig,'Position',[0.14 0.18 0.66 0.76]);
surf(ax,UP,DOWN,ITAE,'FaceColor','interp','EdgeColor','none');
hold(ax,'on');

% Original gain pair: do not interpolate or change the surface to place it.
iu = find(abs(UP(1,:)-p0.AST.gammaUp(1))<1e-10,1);
id = find(abs(DOWN(:,1)-p0.AST.gammaDown(1))<1e-10,1);
if ~isempty(iu) && ~isempty(id) && isfinite(ITAE(id,iu))
    plot3(ax,UP(id,iu),DOWN(id,iu),ITAE(id,iu),'ko', ...
        'MarkerFaceColor','w','MarkerSize',7,'LineWidth',1.1);
end

xlabel(ax,'\gamma_{up}','Interpreter','tex');
ylabel(ax,'\gamma_{down}','Interpreter','tex');
zlabel(ax,'ITAE (m s^2)','Interpreter','tex');
% Intentionally NO title(ax,...) or sgtitle(...).
set(ax,'FontName','Times New Roman','FontSize',11, ...
    'LineWidth',0.8,'GridAlpha',0.18,'TickLabelInterpreter','tex');
set(ax,'XLim',[2 10], 'YLim',[0.03 0.27], 'ZLim',Z_COMMON);
set(ax,'XTick',2:2:10, 'YTick',[0.03 0.09 0.15 0.21 0.27], ...
    'ZTick',[1.4 1.6 1.8 2.0 2.2 2.4 2.6]);
colormap(ax,parula(256));
caxis(ax,Z_COMMON);  % Shared colors: purple/blue/yellow mean the SAME ITAE in every case.
cb = colorbar(ax,'Location','eastoutside');
cb.Ticks = [1.4 1.6 1.8 2.0 2.2 2.4 2.6];
view(ax,42,28);
grid(ax,'on'); box(ax,'on');
drawnow;

fileBase = fullfile(outFolder,sprintf('ASTSMC_Case%d_ITAE_3D',CASE_NO));
% Save .fig with Visible='on' to avoid the archived-invisible-FIG issue.
set(fig,'Visible','on');
savefig(fig,[fileBase '.fig']);

% Keep Visible='on' while exporting; saved FIG is directly viewable.
try
    exportgraphics(fig,[fileBase '.png'], 'Resolution',600, ...
        'BackgroundColor','white');
catch
    print(fig,[fileBase '.png'],'-dpng','-r600');
end
try
    exportgraphics(fig,[fileBase '.pdf'], 'ContentType','vector', ...
        'BackgroundColor','white');
catch
    set(fig,'Renderer','painters');
    print(fig,[fileBase '.pdf'],'-dpdf','-painters');
end
if ~SHOW_FIGURE, close(fig); end
fprintf('Exported Case %d (shared Z/color [%.2f, %.2f]): %s\n', ...
    CASE_NO,Z_COMMON(1),Z_COMMON(2),fileBase);
end
