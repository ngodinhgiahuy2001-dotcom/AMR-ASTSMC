function export_deterministic_figures(allResults,outputFolder)
%EXPORT_DETERMINISTIC_FIGURES Export manuscript Figs. 14-18 from stored results.
%
% INPUT CONTRACT:
%   allResults{caseNo,controllerNo} = result from main.m
%   controller order: 1=SMC, 2=STSMC, 3=ASTSMC
%   Case 3: external model_external_disturbance + equivalent variable-payload uncertainty
%
% No controller is rerun, no parameter is changed. Every curve and bar
% comes from an existing result vector or result.metrics field.
% Exports .fig, 600-DPI .png and vector .pdf with LineWidth 2 pt.

assert(iscell(allResults) && isequal(size(allResults),[3 3]), ...
    'Expected allResults as a 3x3 cell array.');

S=config_plot_style();
S.FigureWidthCm=16.5;
S.FigureHeightCm=9.5;
S.FontSize=11;
S.LineWidth=2;
S.RefLineWidth=2;
folder=fullfile(outputFolder,'Publication_Figures');
if ~exist(folder,'dir'),mkdir(folder);end

ST=allResults{3,2};
AST=allResults{3,3};
SMC=allResults{3,1};
t=AST.t(:);
mask800=(t>=27 & t<=42);
maskPayload=(t>=23 & t<=61);
assert(nnz(mask800)>2 && nnz(maskPayload)>2, ...
    'Saved simulation contains insufficient samples for payload zooms.');

% Fig. 14: Cartesian position-error magnitude, 800 kg travel plateau.
fig=new_figure(S,'Fig. 14 - Position error 800 kg');
ax=axes('Parent',fig);hold(ax,'on');
plot(ax,t(mask800),ST.ep(mask800)*1000,'--', ...
    'Color',S.STSMC.Color,'LineWidth',S.LineWidth);
plot(ax,t(mask800),AST.ep(mask800)*1000,'-.', ...
    'Color',S.ASTSMC.Color,'LineWidth',S.LineWidth);
format_axes(ax,S);
xlim(ax,[27 42]);
ylim(ax,[0 1.10*max([ST.ep(mask800);AST.ep(mask800)])*1000]);
xlabel(ax,'Time (s)');ylabel(ax,'Position error (mm)');
legend_outside(ax,{'STSMC','ASTSMC'},S);
export_figure(fig,folder,'Fig14_Position_Error_800kg',S);

% Fig. 15: longitudinal sliding variable in the same 800 kg window.
fig=new_figure(S,'Fig. 15 - Sliding error 800 kg');
ax=axes('Parent',fig);hold(ax,'on');
plot(ax,t(mask800),ST.s(mask800,1)*1000,'--', ...
    'Color',S.STSMC.Color,'LineWidth',S.LineWidth);
plot(ax,t(mask800),AST.s(mask800,1)*1000,'-.', ...
    'Color',S.ASTSMC.Color,'LineWidth',S.LineWidth);
format_axes(ax,S);
xlim(ax,[27 42]);
xlabel(ax,'Time (s)');ylabel(ax,'s_v (mm/s)');
legend_outside(ax,{'STSMC','ASTSMC'},S);
export_figure(fig,folder,'Fig15_Sliding_sv_800kg',S);

% Fig. 16: adaptive gains (left Y) and payload mass (right Y).
% The payload curve is visual context, NOT measured by the controller.
fig=new_figure(S,'Fig. 16 - Gains versus payload');
ax=axes('Parent',fig);
yyaxis(ax,'left');hold(ax,'on');
hv=plot(ax,t(maskPayload),AST.alpha(maskPayload,1),'-', ...
    'Color',S.SMC.Color,'LineWidth',S.LineWidth);
hw=plot(ax,t(maskPayload),AST.alpha(maskPayload,2),'--', ...
    'Color',S.STSMC.Color,'LineWidth',S.LineWidth);
ylabel(ax,'Adaptive gain');
yyaxis(ax,'right');
hm=plot(ax,t(maskPayload),AST.mp(maskPayload),':', ...
    'Color',[0.35 0.35 0.35],'LineWidth',S.LineWidth);
ylabel(ax,'Payload mass (kg)');
ylim(ax,[0 max(AST.mp)*1.08]);
ax.YAxis(1).Color=[0.15 0.15 0.15];
ax.YAxis(2).Color=[0.15 0.15 0.15];
format_axes(ax,S);
xlim(ax,[23 61]);xlabel(ax,'Time (s)');
lg=legend(ax,[hv hw hm],{'\alpha_v','\alpha_\omega','Payload'}, ...
    'Location','northoutside','Orientation','horizontal', ...
    'Interpreter','tex','AutoUpdate','off');
set(lg,'FontName',S.FontName,'FontSize',10);
export_figure(fig,folder,'Fig16_Adaptive_Gains_Payload_23to61s',S);

% Fig. 17: cumulative ITAE of position tracking from original saved ep.
% The rightmost point MUST reproduce the full-run scalar ITAE metric.
fig=new_figure(S,'Fig. 17 - Cumulative ITAE');
ax=axes('Parent',fig);hold(ax,'on');
res={SMC,ST,AST};
col={S.SMC.Color,S.STSMC.Color,S.ASTSMC.Color};
linestyles={S.SMC.LineStyle,S.STSMC.LineStyle,S.ASTSMC.LineStyle};
for k=1:3
    rk=res{k};
    tk=rk.t(:);
    ep=rk.ep(:);
    cumulativeITAE=cumtrapz(tk,tk.*abs(ep));
    % Numerical consistency check: same formula used for the paper's ITAE.
    if abs(cumulativeITAE(end)-rk.metrics.ITAE)>1e-5
        error('Cumulative ITAE does not agree with saved Case 3 metrics.');
    end
    plot(ax,tk,cumulativeITAE,'Color',col{k}, ...
        'LineStyle',linestyles{k},'LineWidth',S.LineWidth);
end
format_axes(ax,S);
xlim(ax,[0 75]);ylim(ax,[0 1.06*max([SMC.metrics.ITAE ST.metrics.ITAE AST.metrics.ITAE])]);
xlabel(ax,'Time (s)');ylabel(ax,'Cumulative ITAE (m.s^2)');
legend_outside(ax,{'SMC','STSMC','ASTSMC'},S);
export_figure(fig,folder,'Fig17_Cumulative_ITAE_Case3',S);

% Fig. 18: ITAE comparison for all three controllers and all three cases.
fig=new_figure(S,'Fig. 18 - ITAE across 3 cases');
ax=axes('Parent',fig);hold(ax,'on');
itae=zeros(3,3);
for c=1:3
    for k=1:3
        itae(c,k)=allResults{c,k}.metrics.ITAE;
    end
end
b=bar(ax,1:3,itae,'grouped');
for k=1:3
    b(k).FaceColor=col{k};
    b(k).EdgeColor='none';
end
format_axes(ax,S);
xticks(ax,[1 2 3]);
xticklabels(ax,{'Nominal','External disturbance', ...
    'Combined + payload'});
xtickangle(ax,0);
xlim(ax,[0.5 3.5]);ylim(ax,[0 1.15*max(itae(:))]);
ylabel(ax,'ITAE (m.s^2)');
legend_outside(ax,{'SMC','STSMC','ASTSMC'},S);
export_figure(fig,folder,'Fig18_ITAE_3Cases',S);
end

function fig=new_figure(S,name)
fig=figure('Color','w','Name',name,'NumberTitle','off', ...
    'Units','centimeters','Position',[2 2 S.FigureWidthCm S.FigureHeightCm], ...
    'PaperUnits','centimeters', ...
    'PaperPosition',[0 0 S.FigureWidthCm S.FigureHeightCm], ...
    'PaperSize',[S.FigureWidthCm S.FigureHeightCm]);
end

function format_axes(ax,S)
set(ax,'FontName',S.FontName,'FontSize',S.FontSize, ...
    'LineWidth',0.8,'Box','on','TickLabelInterpreter','tex');
grid(ax,'on');ax.GridAlpha=S.GridAlpha;
end

function legend_outside(ax,labels,S)
lg=legend(ax,labels,'Location','northoutside', ...
    'Orientation','horizontal','Interpreter','none','AutoUpdate','off');
set(lg,'FontName',S.FontName,'FontSize',10,'Box','on');
end
