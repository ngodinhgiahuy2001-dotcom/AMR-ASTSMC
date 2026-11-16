function plot_gain_adaptation_law(p, outputFolder)
%PLOT_GAIN_ADAPTATION_LAW Export Fig. 5(a) and Fig. 5(b) SEPARATELY.
%
% Replaces the original two-panel version without changing the ASTSMC law.
% Sources: config_parameters.m and controller_ASTSMC.m.
% Outputs (in outputFolder/Publication_Figures):
%   Fig05a_mu_projection.png/.pdf/.fig
%   Fig05b_beta_alpha.png/.pdf/.fig
%
% Figure 5(a): unconstrained gain-update rate h (before projection)
% Figure 5(b): beta = kappa^2 * alpha + beta0
%
% Both plots use the v-channel config_parameters. Here v and yaw channels have
% identical adaptation config_parameters, as specified in config_parameters.m.

if nargin < 1 || isempty(p)
    p = config_parameters();
end
if nargin < 2 || isempty(outputFolder)
    outputFolder = pwd;
end

S = config_plot_style();
S.LineWidth = 2;
S.RefLineWidth = 2;
S.FontName = 'Times New Roman';
S.FontSize = 10;
S.FigureWidthCm  = 9.0;
S.FigureHeightCm = 11.5;
S.PNG_DPI = 600;

folder = fullfile(outputFolder,'Publication_Figures');
if ~exist(folder,'dir')
    mkdir(folder);
end

%% ---- Fig. 5(a): Unprojected gain-adaptation rate ----
sAbs = linspace(0,0.006,500);  % sliding magnitude in m/s
muL   = p.AST.muL(1);
muH   = p.AST.muH(1);
delta = p.AST.delta(1);
gammaUp   = p.AST.gammaUp(1);
gammaDown = p.AST.gammaDown(1);
alphaMin  = p.AST.alphaMin(1);

% SAME gates and rate as controller_ASTSMC.m (without projection).
gUp   = 0.5 .* (1 + tanh((sAbs - muH) ./ delta));
gDown = 0.5 .* (1 + tanh((muL - sAbs) ./ delta));
alphaTest = [1 3 6];
colors = [S.SMC.Color; S.STSMC.Color; S.ASTSMC.Color];

figA = new_fig('Fig. 5(a) - Unprojected gain rate', S);
axA = axes('Parent',figA,'Position',[0.25 0.14 0.70 0.80]);
hold(axA,'on');
for k = 1:numel(alphaTest)
    alphaFixed = alphaTest(k);
    h = gammaUp .* gUp - gammaDown .* gDown .* (alphaFixed - alphaMin);
    plot(axA,sAbs*1000,h, ...
        'LineWidth',S.LineWidth,'Color',colors(k,:));
end
style_axes(axA,S);
axA.XLim = [0 6];
xlabel(axA,'|s_v| (mm/s)','Interpreter','tex');
ylabel(axA,'Unprojected gain rate (s^{-1})','Interpreter','tex');
legend(axA,{'\alpha = 1','\alpha = 3','\alpha = 6'}, ...
    'Location','northwest','Interpreter','tex', ...
    'FontName',S.FontName,'FontSize',9,'Box','on');
% Panel labels are added in Word, avoiding duplicate (a)/(b) on the plot.
export_figure(figA,folder,'Fig05a_mu_projection',S);
close(figA);

%% ---- Fig. 5(b): ASTSMC coupled second gain ----
alpha = linspace(p.AST.alphaMin(1),p.AST.alphaMax(1),300);
beta  = (p.AST.kappa(1)^2).*alpha + p.AST.beta0(1);

figB = new_fig('Fig. 5(b) - Coupled gain', S);
axB = axes('Parent',figB,'Position',[0.25 0.14 0.70 0.80]);
hold(axB,'on');
plot(axB,alpha,beta,'Color',[0.38 0.25 0.57], ...
    'LineWidth',S.LineWidth);
style_axes(axB,S);
axB.XLim = [alpha(1),alpha(end)];
xlabel(axB,'\alpha','Interpreter','tex');
ylabel(axB,'\beta = \kappa^2\alpha + \beta_0','Interpreter','tex');
export_figure(figB,folder,'Fig05b_beta_alpha',S);
close(figB);
end

function fig = new_fig(name,S)
fig = figure('Color','w','Name',name,'NumberTitle','off', ...
    'Units','centimeters', ...
    'Position',[2 2 S.FigureWidthCm S.FigureHeightCm]);
end

function style_axes(ax,S)
set(ax,'FontName',S.FontName,'FontSize',S.FontSize, ...
    'LineWidth',0.8,'Box','on', ...
    'TickLabelInterpreter','tex');
grid(ax,'on');
ax.GridAlpha = S.GridAlpha;
end
