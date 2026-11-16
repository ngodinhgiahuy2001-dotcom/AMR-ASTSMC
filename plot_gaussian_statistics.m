function plot_gaussian_statistics(Raw,Summary,Paired,Rep,p,folder)
% PLOT_GAUSSIAN_STATISTICS Publishable-format descriptive plots (not a proof).
% No Statistics Toolbox needed. Plain MATLAB figure/plot/errorbar/scatter.
controllers={'SMC','STSMC','ASTSMC'};
colors=[.13 .45 .72;.84 .39 .16;.20 .62 .44];
caList=[2 3];

% Fig S3-1: per-seed ITAE, group means and standard deviations.
f=figure('Visible','off','Color','w','Position',[70 70 1080 470]);
for ci=1:2
    ca=caList(ci);
    subplot(1,2,ci);hold on;
    for j=1:3
        k=Raw.Case==ca & strcmp(Raw.Controller,controllers{j});
        y=Raw.ITAE_m_s2(k);
        scatter(j+linspace(-.12,.12,numel(y))',y,18,colors(j,:),'filled');
        errorbar(j,mean(y),std(y),'k','LineWidth',1.3,'CapSize',9);
        plot(j,mean(y),'ko','MarkerFaceColor','w','MarkerSize',6);
    end
    xlim([.5 3.5]);xticks(1:3);xticklabels(controllers);
    ylabel('Full-mission ITAE (m s^2)');
    grid on;box on;
end
plot_statistics_style(f);
export_statistics_figure(f,folder,'S3_Fig1_Seedwise_ITAE');

% Fig S3-2: paired per-seed percentage improvement relative to STSMC.
f=figure('Visible','off','Color','w','Position',[80 80 950 470]);hold on;
for ci=1:2
    ca=caList(ci);
    s=Raw(Raw.Case==ca & strcmp(Raw.Controller,'STSMC'),:);
    a=Raw(Raw.Case==ca & strcmp(Raw.Controller,'ASTSMC'),:);
    [~,is]=sort(s.Trial);s=s(is,:);
    [~,ia]=sort(a.Trial);a=a(ia,:);
    pct=100*(s.ITAE_m_s2-a.ITAE_m_s2)./s.ITAE_m_s2;
    scatter(ci+linspace(-.15,.15,numel(pct))',pct,27,colors(ci+1,:),'filled');
    row=Paired.Case==ca & strcmp(Paired.Comparator,'STSMC');
    mu=Paired.Mean_ITAE_Improvement_pct(row);
    low=Paired.CI95_Improvement_L_pct(row);
    high=Paired.CI95_Improvement_U_pct(row);
    errorbar(ci,mu,mu-low,high-mu,'k','LineWidth',2,'CapSize',12);
    plot(ci,mu,'ko','MarkerSize',8,'MarkerFaceColor','w');
end
plot([.5 2.5],[0 0],'k:','LineWidth',1.2);
xlim([.5 2.5]);xticks([1,2]);xticklabels({'Case 2','Case 3'});
ylabel('Paired ITAE improvement over STSMC (%)');
grid on;box on;
plot_statistics_style(f);export_statistics_figure(f,folder,'S3_Fig2_Paired_ITAE_Improvement');

% Fig S3-3: representative FIRST-seed tracking and adaptive gains for Case 3.
for ci=1:2
    ca=caList(ci);
    a=Rep{ci,3};s=Rep{ci,2};
    f=figure('Visible','off','Color','w','Position',[70 70 980 640]);
    if a.t(end)>=42
        mask=a.t>=27 & a.t<=42;
    else
        mask=true(size(a.t));
    end
    subplot(2,1,1);hold on;
    plot(a.t(mask),1000*s.ep(mask),'--','Color',colors(2,:),'LineWidth',1.6);
    plot(a.t(mask),1000*a.ep(mask),'-','Color',colors(3,:),'LineWidth',1.6);
    ylabel('Position error (mm)');
    legend({'STSMC','ASTSMC'},'Location','best');
    grid on;
    subplot(2,1,2);hold on;
    plot(a.t,a.alpha(:,1),'-','Color',colors(1,:),'LineWidth',1.35);
    plot(a.t,a.alpha(:,2),'--','Color',colors(2,:),'LineWidth',1.35);
    plot([a.t(1),a.t(end)],[p.AST.alphaMax(1),p.AST.alphaMax(1)],...
        'k:','LineWidth',.9);
    xlabel('Time (s)');ylabel('Adaptive gains');
    legend({'alpha_v','alpha_w','alpha upper bound'},'Location','best');
    grid on;
    plot_statistics_style(f);
    export_statistics_figure(f,folder,sprintf('S3_Fig3_Case%d_Tracking_Gains',ca));
end

% Fig S3-4: sensor noise vs LPF tracking error, the SAME actual plant state.
a=Rep{1,3};
if a.t(end)>28,tlo=27;tup=28;else,tlo=5;tup=min(6,a.t(end));end
mask=a.t>=tlo & a.t<=tup;
if nnz(mask)<5,mask=true(size(a.t));end
f=figure('Visible','off','Color','w','Position',[70 70 920 450]);hold on;
plot(a.t(mask),1000*(a.etaMeasured(mask,1)-a.etaTrue(mask,1)),...
    'Color',[.65 .65 .65],'LineWidth',1);
plot(a.t(mask),1000*(a.etaFiltered(mask,1)-a.etaTrue(mask,1)),...
    'Color',colors(1,:),'LineWidth',1.5);
xlabel('Time (s)');ylabel('Velocity measurement error (mm/s)');
legend({'Raw sensor minus true velocity','Filtered minus true velocity'},...
    'Location','best');
grid on;plot_statistics_style(f);
export_statistics_figure(f,folder,'S3_Fig4_Sensor_vs_Filter_Error');
end

function plot_statistics_style(fig)
a=findall(fig,'Type','axes');
for i=1:numel(a)
    set(a(i),'FontName','Times New Roman','FontSize',11,'LineWidth',.8);
end
end

function export_statistics_figure(fig,folder,name)
try
   print(fig,fullfile(folder,[name '.png']),'-dpng','-r600');
   set(fig,'Visible','on');
   savefig(fig,fullfile(folder,[name '.fig']));
   set(fig,'Visible','off');
catch err
   warning('Stage3:PlotExport','Figure export failed: %s',err.message);
end
close(fig);
end
