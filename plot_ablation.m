function plot_ablation(R,p,noise,folder)
labels={'N0','N1','N2','N3','N4'};
colors=[.12 .47 .71; .85 .33 .10; .49 .65 .20];
itae=zeros(5,3);
for mi=1:5
    for ci=1:3, itae(mi,ci)=R{mi,ci}.metrics.ITAE; end
end
% Fig 1: all controllers (SMC can dominate scale).
f=figure('Visible','off','Color','w','Position',[70 100 900 460]);
bar(itae,'grouped');
set(gca,'XTick',1:5,'XTickLabel',labels,'FontName','Times New Roman','FontSize',11);
xlabel('Noise-ablation mode');ylabel('ITAE (m s^2)');
legend({'SMC','STSMC','ASTSMC'},'Location','best');
grid on;box on;
save_figure(f,folder,'S3_Ablation_Fig1_All_ITAE');
% Fig 2: finer scale STSMC vs ASTSMC.
f=figure('Visible','off','Color','w','Position',[70 100 900 460]);
bar(itae(:,2:3),'grouped');
set(gca,'XTick',1:5,'XTickLabel',labels,'FontName','Times New Roman','FontSize',11);
xlabel('Noise-ablation mode');ylabel('ITAE (m s^2)');
legend({'STSMC','ASTSMC'},'Location','best');
grid on;box on;
save_figure(f,folder,'S3_Ablation_Fig2_STSMC_ASTSMC_ITAE');
% Fig 3: SAME raw measurement noise in N2/N3; pure noise filtered.
r=R{4,3}; ts=r.t;
raw=r.etaMeasured-r.etaTrue;
filtered=ablation_lpf_noise(raw,p.stage2.Ts,p.stage2.tauLPF);
window=ts>=27 & ts<=29;
if ~any(window), window=ts>=0 & ts<=min(2,ts(end)); end
f=figure('Visible','off','Color','w','Position',[70 100 900 460]);
plot(ts(window),1000*raw(window,1),'-','LineWidth',0.9,'Color',[.6 .6 .6]);hold on;
plot(ts(window),1000*filtered(window,1),'-','LineWidth',1.5,'Color',colors(1,:));
xlabel('Time (s)');ylabel('Longitudinal sensor noise (mm/s)');
legend({'Raw Gaussian sample','5-ms LPF noise component'},'Location','best');
grid on;box on;
set(gca,'FontName','Times New Roman','FontSize',11);
save_figure(f,folder,'S3_Ablation_Fig3_Sensor_Noise_LPF');
% Fig 4: isolate payload in 27-42s; same process and sensor samples.
f=figure('Visible','off','Color','w','Position',[70 100 900 460]);
for ci=2:3
    r3=R{4,ci}; r4=R{5,ci};
    idx=r3.t>=27 & r3.t<=42;
    if ~any(idx),idx=true(size(r3.t));end
    plot(r3.t(idx),1000*r3.ep(idx),'--','LineWidth',1.35,'Color',colors(ci,:));hold on;
    plot(r4.t(idx),1000*r4.ep(idx),'-','LineWidth',1.65,'Color',colors(ci,:));
end
xlabel('Time (s)');ylabel('Position error (mm)');
legend({'N3 STSMC','N4 STSMC + payload','N3 ASTSMC', ...
        'N4 ASTSMC + payload'},'Location','best');
grid on;box on;
set(gca,'FontName','Times New Roman','FontSize',11);
save_figure(f,folder,'S3_Ablation_Fig4_Payload_Effect_27to42');
% Fig 5: ASTSMC gain histories: N2 N3 N4.
f=figure('Visible','off','Color','w','Position',[70 100 900 630]);
for channel=1:2
    subplot(2,1,channel);hold on;
    for mi=3:5
        plot(R{mi,3}.t,R{mi,3}.alpha(:,channel), ...
            'LineWidth',1.4,'Color',colors(mi-2,:));
    end
    yline(p.AST.alphaMax(channel),':','Upper bound');
    ylabel(sprintf('Adaptive gain channel %d',channel));
    if channel==1
        legend({'N2: noisy/no LPF','N3: +LPF','N4: +payload'}, ...
            'Location','best');
    else
        xlabel('Time (s)');
    end
    grid on;box on;
    set(gca,'FontName','Times New Roman','FontSize',11);
end
save_figure(f,folder,'S3_Ablation_Fig5_ASTSMC_Gain_N2_N4');
end

function save_figure(f,folder,stem)
set(f,'Visible','on');
savefig(f,fullfile(folder,[stem '.fig']));
set(f,'Visible','off');
print(f,fullfile(folder,[stem '.png']),'-dpng','-r300');
close(f);
end

function out=ablation_lpf_noise(raw,Ts,tau)
% Exactly the sample-wise recursion used in simulate_gaussian.
rho=exp(-Ts./tau(:));
out=zeros(size(raw));
out(1,:)=raw(1,:);
for k=2:size(raw,1)
    out(k,:)=(rho.*out(k-1,:).' + (1-rho).*raw(k,:).').';
end
end

