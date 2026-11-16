function plot_gaussian_results(caseResults,ca,folder)
% Publication-friendly Stage 2 plots; does not overwrite archival figures.
S=config_plot_style();
A=caseResults{3}; t=A.t;
C={S.SMC.Color,S.STSMC.Color,S.ASTSMC.Color};
L={S.SMC.LineStyle,S.STSMC.LineStyle,S.ASTSMC.LineStyle};
labels={'SMC','STSMC','ASTSMC'};

% A. Reference/actual trajectories
fig=newFig(S); ax=axes('Parent',fig);hold(ax,'on');
plot(ax,A.ref(:,1),A.ref(:,2),':','Color',[0 0 0],'LineWidth',1.5);
for j=1:3
   r=caseResults{j};plot(ax,r.x(:,1),r.x(:,2),L{j},'Color',C{j},'LineWidth',S.LineWidth);
end
xlabel(ax,'x (m)');ylabel(ax,'y (m)');axis(ax,'equal');grid(ax,'on');
legend(ax,[{'Reference'},labels],'Location','best','Interpreter','none');
export_figure(fig,folder,sprintf('Case%d_Stage2_Trajectory',ca),S);close(fig);

% B. Position error (entire mission)
fig=newFig(S);ax=axes('Parent',fig);hold(ax,'on');
for j=1:3,plot(ax,t,caseResults{j}.ep,L{j},'Color',C{j},'LineWidth',S.LineWidth);end
xlabel(ax,'Time (s)');ylabel(ax,'Position error (m)');grid(ax,'on');
legend(ax,labels,'Location','best');
export_figure(fig,folder,sprintf('Case%d_Stage2_Position_Error',ca),S);close(fig);

% C. Position error in 800-kg interval (no payload for Case 1/2)
idx=t>=27 & t<=42;
if any(idx)
 fig=newFig(S);ax=axes('Parent',fig);hold(ax,'on');
 for j=1:3,plot(ax,t(idx),1000*caseResults{j}.ep(idx),L{j},'Color',C{j},'LineWidth',S.LineWidth);end
 xlabel(ax,'Time (s)');ylabel(ax,'Position error (mm)');grid(ax,'on');
 legend(ax,labels,'Location','best');
 export_figure(fig,folder,sprintf('Case%d_Stage2_PosError_27to42',ca),S);close(fig);
end

% D. TRUE longitudinal velocity sliding variable; not filtered
fig=newFig(S);ax=axes('Parent',fig);hold(ax,'on');
for j=1:3,plot(ax,t,caseResults{j}.s(:,1),L{j},'Color',C{j},'LineWidth',S.LineWidth);end
xlabel(ax,'Time (s)');ylabel(ax,'True s_v (m/s)');grid(ax,'on');
legend(ax,labels,'Location','best');
export_figure(fig,folder,sprintf('Case%d_Stage2_TrueSliding_v',ca),S);close(fig);

% E. Sampled commanded longitudinal generalized input; no torque clamp
fig=newFig(S);ax=axes('Parent',fig);hold(ax,'on');
for j=1:3,plot(ax,t,caseResults{j}.u(:,1),L{j},'Color',C{j},'LineWidth',S.LineWidth);end
xlabel(ax,'Time (s)');ylabel(ax,'Requested u_v (N)');grid(ax,'on');
legend(ax,labels,'Location','best');
export_figure(fig,folder,sprintf('Case%d_Stage2_Control_uv',ca),S);close(fig);

% F. ASTSMC gains (not valid for SMC and STSMC)
fig=newFig(S);ax=axes('Parent',fig);hold(ax,'on');
plot(ax,t,A.alpha(:,1),'-','Color',C{1},'LineWidth',S.LineWidth);
plot(ax,t,A.alpha(:,2),'--','Color',C{2},'LineWidth',S.LineWidth);
xlabel(ax,'Time (s)');ylabel(ax,'Adaptive gain');grid(ax,'on');
legend(ax,{'alpha_v','alpha_omega'},'Location','best','Interpreter','none');
export_figure(fig,folder,sprintf('Case%d_Stage2_ASTSMC_Gains',ca),S);close(fig);

% G. True, measured, filtered velocity over selected window (ASTSMC)
idx=t>=27 & t<=30;
if ~any(idx),idx=t>=t(1)&t<=min(t(1)+2,t(end));end
fig=newFig(S);ax=axes('Parent',fig);hold(ax,'on');
plot(ax,t(idx),A.etaTrue(idx,1),'k:','LineWidth',1.5);
plot(ax,t(idx),A.etaMeasured(idx,1),'-','Color',[.62 .62 .62],'LineWidth',.9);
plot(ax,t(idx),A.etaFiltered(idx,1),'-','Color',[.1 .5 .65],'LineWidth',S.LineWidth);
xlabel(ax,'Time (s)');ylabel(ax,'Longitudinal velocity (m/s)');grid(ax,'on');
legend(ax,{'True','Noisy sensor','Filtered'},'Location','best');
export_figure(fig,folder,sprintf('Case%d_Stage2_Sensor_LPF',ca),S);close(fig);
end

function fig=newFig(S)
fig=figure('Color','w','Visible','off','Units','centimeters',...
 'Position',[2 2 S.FigureWidthCm S.FigureHeightCm]);
end
