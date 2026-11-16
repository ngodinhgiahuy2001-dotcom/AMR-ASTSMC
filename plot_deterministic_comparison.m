function plot_deterministic_comparison(caseResults, p, caseNo, outputFolder)
%PLOT_DETERMINISTIC_COMPARISON Plot one simulation case for SMC/STSMC/ASTSMC.
%
% EXACT INPUT CONTRACT FOR THE CURRENT PROJECT:
%   caseResults = allResults(caseNo,:)   % 1x3 cell array
%   p           = config_parameters() structure
%   caseNo      = 1, 2 or 3
%   outputFolder= Results_3Cases_yyyymmdd_HHMMSS
%
% The three cells must contain result structures created by
% postprocess_local() in main.m:
%   {SMC, STSMC, ASTSMC}
%
% This function DOES NOT alter simulation data, controller config_parameters,
% metrics, or the program flow. It only plots/export figures.

S = config_plot_style();

%% Validate the exact data received from main.m
if ~iscell(caseResults) || numel(caseResults) ~= 3
    error('plot_compare_results:InvalidInput', ...
        ['First input must be the 1x3 cell array allResults(caseNo,:) ' ...
         'containing SMC, STSMC and ASTSMC results.']);
end

R.SMC    = caseResults{1};
R.STSMC  = caseResults{2};
R.ASTSMC = caseResults{3};

requiredFields = {'t','x','ref','ep','eth','u','s','mp','alpha','controller','caseNo','metrics'};
controllers = {'SMC','STSMC','ASTSMC'};
for i = 1:numel(controllers)
    name = controllers{i};
    if ~isstruct(R.(name))
        error('plot_compare_results:InvalidResult', ...
            '%s result is not a struct.', name);
    end
    for k = 1:numel(requiredFields)
        if ~isfield(R.(name),requiredFields{k})
            error('plot_compare_results:MissingField', ...
                '%s result is missing field "%s".',name,requiredFields{k});
        end
    end
end

% All simulations in a case use the same fixed time grid.
t = R.SMC.t(:);
N = numel(t);
for i = 1:numel(controllers)
    name = controllers{i};
    if numel(R.(name).t) ~= N
        error('plot_compare_results:LengthMismatch', ...
            'Time-vector length differs between controllers.');
    end
end

caseFolder = fullfile(outputFolder,sprintf('Case%d',caseNo));
if ~exist(caseFolder,'dir')
    mkdir(caseFolder);
end

% Styling shortcuts
C1 = S.SMC.Color;    L1 = S.SMC.LineStyle;
C2 = S.STSMC.Color;  L2 = S.STSMC.LineStyle;
C3 = S.ASTSMC.Color; L3 = S.ASTSMC.LineStyle;

%% 1. Reference/actual XY model_reference_trajectory
fig = new_figure(S,'Trajectory');
ax = axes(fig); hold(ax,'on');
plot(ax,R.SMC.ref(:,1),R.SMC.ref(:,2), ...
    'Color',S.Reference.Color,'LineStyle',S.Reference.LineStyle, ...
    'LineWidth',S.RefLineWidth);
plot(ax,R.SMC.x(:,1),R.SMC.x(:,2),'Color',C1,'LineStyle',L1,'LineWidth',S.LineWidth);
plot(ax,R.STSMC.x(:,1),R.STSMC.x(:,2),'Color',C2,'LineStyle',L2,'LineWidth',S.LineWidth);
plot(ax,R.ASTSMC.x(:,1),R.ASTSMC.x(:,2),'Color',C3,'LineStyle',L3,'LineWidth',S.LineWidth);
xlabel(ax,'x [m]','Interpreter',S.Interpreter);
ylabel(ax,'y [m]','Interpreter',S.Interpreter);
axis(ax,'equal');
legend(ax,{'Reference','SMC','STSMC','ASTSMC'},'Location','best','Interpreter','none');
finish_axes(ax,S);
export_figure(fig,caseFolder,sprintf('Case%d_Trajectory',caseNo),S);

%% 2. Position tracking error
fig = new_figure(S,'Position error');
ax = axes(fig); hold(ax,'on');
plot_controller_triplet(ax,t,R.SMC.ep,R.STSMC.ep,R.ASTSMC.ep,S);
xlabel(ax,'Time [s]','Interpreter',S.Interpreter);
ylabel(ax,'Position error [m]','Interpreter',S.Interpreter);
legend(ax,{'SMC','STSMC','ASTSMC'},'Location','best','Interpreter','none');
finish_axes(ax,S);
export_figure(fig,caseFolder,sprintf('Case%d_Position_Error',caseNo),S);

%% 3. Heading tracking error
fig = new_figure(S,'Heading error');
ax = axes(fig); hold(ax,'on');
plot_controller_triplet(ax,t,R.SMC.eth,R.STSMC.eth,R.ASTSMC.eth,S);
xlabel(ax,'Time [s]','Interpreter',S.Interpreter);
ylabel(ax,'e_\theta [rad]','Interpreter',S.Interpreter);
legend(ax,{'SMC','STSMC','ASTSMC'},'Location','best','Interpreter','none');
finish_axes(ax,S);
export_figure(fig,caseFolder,sprintf('Case%d_Heading_Error',caseNo),S);

%% 4. Longitudinal sliding variable s_v
fig = new_figure(S,'Sliding s_v');
ax = axes(fig); hold(ax,'on');
plot_controller_triplet(ax,t,R.SMC.s(:,1),R.STSMC.s(:,1),R.ASTSMC.s(:,1),S);
xlabel(ax,'Time [s]','Interpreter',S.Interpreter);
ylabel(ax,'s_v [m/s]','Interpreter',S.Interpreter);
legend(ax,{'SMC','STSMC','ASTSMC'},'Location','best','Interpreter','none');
finish_axes(ax,S);
export_figure(fig,caseFolder,sprintf('Case%d_Sliding_sv',caseNo),S);

%% 5. Yaw sliding variable s_omega
fig = new_figure(S,'Sliding s_omega');
ax = axes(fig); hold(ax,'on');
plot_controller_triplet(ax,t,R.SMC.s(:,2),R.STSMC.s(:,2),R.ASTSMC.s(:,2),S);
xlabel(ax,'Time [s]','Interpreter',S.Interpreter);
ylabel(ax,'s_\omega [rad/s]','Interpreter',S.Interpreter);
legend(ax,{'SMC','STSMC','ASTSMC'},'Location','best','Interpreter','none');
finish_axes(ax,S);
export_figure(fig,caseFolder,sprintf('Case%d_Sliding_somega',caseNo),S);

%% 6. Longitudinal generalized input u_v
fig = new_figure(S,'Control u_v');
ax = axes(fig); hold(ax,'on');
plot_controller_triplet(ax,t,R.SMC.u(:,1),R.STSMC.u(:,1),R.ASTSMC.u(:,1),S);
xlabel(ax,'Time [s]','Interpreter',S.Interpreter);
ylabel(ax,'u_v [N]','Interpreter',S.Interpreter);
legend(ax,{'SMC','STSMC','ASTSMC'},'Location','best','Interpreter','none');
finish_axes(ax,S);
export_figure(fig,caseFolder,sprintf('Case%d_Control_uv',caseNo),S);

%% 7. Yaw generalized input u_omega
fig = new_figure(S,'Control u_omega');
ax = axes(fig); hold(ax,'on');
plot_controller_triplet(ax,t,R.SMC.u(:,2),R.STSMC.u(:,2),R.ASTSMC.u(:,2),S);
xlabel(ax,'Time [s]','Interpreter',S.Interpreter);
ylabel(ax,'u_\omega [N\cdot m]','Interpreter',S.Interpreter);
legend(ax,{'SMC','STSMC','ASTSMC'},'Location','best','Interpreter','none');
finish_axes(ax,S);
export_figure(fig,caseFolder,sprintf('Case%d_Control_uomega',caseNo),S);

%% 8. ASTSMC adaptive gains alpha_v and alpha_omega
% alpha exists for every result but is NaN for SMC/STSMC by design.
% Fig. 7 is a single figure with a 0-1 s inset. Do not export a
% separate initial-transient panel 7(b).
if caseNo ~= 1 && any(isfinite(R.ASTSMC.alpha(:)))
    fig = new_figure(S,'ASTSMC gains');
    ax = axes(fig); hold(ax,'on');
    plot(ax,t,R.ASTSMC.alpha(:,1),'Color',C1,'LineStyle','-','LineWidth',S.LineWidth);
    plot(ax,t,R.ASTSMC.alpha(:,2),'Color',C2,'LineStyle','--','LineWidth',S.LineWidth);
    xlabel(ax,'Time [s]','Interpreter',S.Interpreter);
    ylabel(ax,'Adaptive gain','Interpreter',S.Interpreter);
    legend(ax,{'\alpha_v','\alpha_\omega'},'Location','best','Interpreter',S.Interpreter);
    finish_axes(ax,S);
    export_figure(fig,caseFolder,sprintf('Case%d_ASTSMC_Gains',caseNo),S);
end

%% 9. Payload + ASTSMC gains (principally useful for Case 3)
if caseNo == 3 && any(abs(R.ASTSMC.mp) > 1e-12) && any(isfinite(R.ASTSMC.alpha(:)))
    fig = new_figure(S,'Payload and gains');
    ax = axes(fig);
    yyaxis(ax,'left');
    plot(ax,t,R.ASTSMC.mp,'k:','LineWidth',S.LineWidth);
    ylabel(ax,'Payload mass [kg]','Interpreter',S.Interpreter);
    yyaxis(ax,'right'); hold(ax,'on');
    plot(ax,t,R.ASTSMC.alpha(:,1),'Color',C1,'LineStyle','-','LineWidth',S.LineWidth);
    plot(ax,t,R.ASTSMC.alpha(:,2),'Color',C2,'LineStyle','--','LineWidth',S.LineWidth);
    ylabel(ax,'Adaptive gain','Interpreter',S.Interpreter);
    xlabel(ax,'Time [s]','Interpreter',S.Interpreter);
    legend(ax,{'Payload','\alpha_v','\alpha_\omega'},'Location','best','Interpreter',S.Interpreter);
    finish_axes(ax,S);
    export_figure(fig,caseFolder,sprintf('Case%d_Payload_ASTSMC_Gains',caseNo),S);
end


%% Additional zoom figures for technical reporting (plotting only)
% Adds a 27-42 s zoomed inset to manuscript Figs. 9, 10, 11(a) and 12.
% Original exports and controller data remain unchanged.
if caseNo == 1
    % Fig. 7: gain histories + the 0-1 s startup inset, ONE exported image.
    export_nominal_gain_inset(R.ASTSMC,caseFolder,S);
elseif caseNo == 2 || caseNo == 3
    % Keep the detailed inset views for Figs. 9, 10, 11, and 12.
    export_zoom_figures(R, caseNo, caseFolder, S);
end

end

%% ========================================================================
% Local helpers
% =========================================================================
function fig = new_figure(S,figName)
fig = figure( ...
    'Name',figName, ...
    'NumberTitle','off', ...
    'Color','w', ...
    'Units','centimeters', ...
    'Position',[2 2 S.FigureWidthCm S.FigureHeightCm], ...
    'PaperUnits','centimeters', ...
    'PaperPosition',[0 0 S.FigureWidthCm S.FigureHeightCm], ...
    'PaperSize',[S.FigureWidthCm S.FigureHeightCm]);
end

function plot_controller_triplet(ax,t,y1,y2,y3,S)
plot(ax,t,y1,'Color',S.SMC.Color,'LineStyle',S.SMC.LineStyle,'LineWidth',S.LineWidth);
plot(ax,t,y2,'Color',S.STSMC.Color,'LineStyle',S.STSMC.LineStyle,'LineWidth',S.LineWidth);
plot(ax,t,y3,'Color',S.ASTSMC.Color,'LineStyle',S.ASTSMC.LineStyle,'LineWidth',S.LineWidth);
end

function finish_axes(ax,S)
set(ax, ...
    'FontName',S.FontName, ...
    'FontSize',S.FontSize, ...
    'LineWidth',0.8, ...
    'Box','on', ...
    'TickLabelInterpreter','tex');
grid(ax,'on');
ax.GridAlpha = S.GridAlpha;
ax.MinorGridAlpha = S.MinorGridAlpha;

% Apply Times New Roman and 13 pt to labels and legend as well.
if ~isempty(ax.XLabel)
    set(ax.XLabel,'FontName',S.FontName,'FontSize',S.FontSize,'FontWeight','normal');
end
if ~isempty(ax.YLabel)
    set(ax.YLabel,'FontName',S.FontName,'FontSize',S.FontSize,'FontWeight','normal');
end
lgd = legend(ax);
if ~isempty(lgd) && isvalid(lgd)
    set(lgd,'FontName',S.FontName,'FontSize',S.FontSize,'Box','on');
end
end
