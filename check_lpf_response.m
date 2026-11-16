function [Summary, folder] = check_lpf_response(mode)
% CHECK_LPF_RESPONSE Paired control/filter study, NO controller retuning.
% Usage (after cd to folder with original source + Stage2.2 patch):
%   [Summary,folder] = check_lpf_response('full');   % 75 s x 3 cases
%   [Summary,folder] = check_lpf_response('quick');  % 30 s x Cases 1-2
%
% Tests tau = 0 (bypass), 0.005 (proposed), 0.050 (original problematic).
% Both controllers use SAME process/sensor Gaussian streams per Case.
% Does not introduce actuator saturation or any gain/antiwindup modification.
% Produces CSV, MAT, control-vs-gain plots and RECOMMENDATION_STATUS.txt.
%
% Outcome of this test is evidence, not a mathematical stability proof.
if nargin < 1 || isempty(mode), mode='full'; end
mode=lower(char(mode));
assert(strcmp(mode,'quick') || strcmp(mode,'full'),'Mode must be quick/full.');
p=config_noise();
p.stage2.exportPlots=false;
p.stage2.saveMAT=false;
p.stage2.printProgress=false;
p.stage2.exportOriginalStyle=false;
if strcmp(mode,'quick')
    p.sim.tf=30;
    cases=[1 2];
else
    p.sim.tf=75;
    cases=[1 2 3];
end
controllers={'STSMC','ASTSMC'};
tauTest=[0,0.005,0.050];
t=(p.sim.t0:p.stage2.Ts:p.sim.tf)';
noise=generate_gaussian_noise(p,numel(t));
folder=create_filter_check_folder(p.stage2.outputBase,['Stage22_Validation_' mode]);
R=cell(numel(cases),numel(controllers),numel(tauTest));
rows=cell(numel(cases)*numel(controllers)*numel(tauTest),19);ir=0;
fprintf('\nSTAGE 2.2: paired LPF full-mission validation | %s\n',mode);
fprintf('tau: 0 (bypass), 0.005 s (proposed), 0.050 s (old)\n');
fprintf('Ts %.4f s | seed %d | no torque saturation\n',p.stage2.Ts,p.stage2.seed);
for ci=1:numel(cases)
    ca=cases(ci);
    for j=1:numel(tauTest)
        tau=tauTest(j);
        pc=p;pc.stage2.useLPF=tau>0;
        pc.stage2.tauLPF=max(tau,eps)*ones(2,1);
        for ic=1:numel(controllers)
            name=controllers{ic};tic;
            a=simulate_gaussian(pc,name,ca,noise);
            R{ci,ic,j}=a;
            qa=calculate_filter_quality(a,pc);
            ir=ir+1;
            rows(ir,:)={ca,name,tau,pc.stage2.seed,a.metrics.ITAE,...
              a.metrics.IAE,a.metrics.RMSE_pos,a.metrics.RMS_uv, ...
              qa.FilterLagRMSv,qa.FilterLagRMSw,qa.GainMeanV,...
              qa.GainMeanW,qa.GainMaxV,qa.GainMaxW,...
              qa.GainAtUpperV_pct,qa.GainAtUpperW_pct,...
              qa.FirstGainUpperV_s,qa.FirstGainUpperW_s,...
              qa.TrueSlidingRMSv};
            fprintf('Case %d | %-6s | tau=%5.3f | ITAE=%9.5f | aV@max=%5.1f%% | %6.1f s\n',...
                 ca,name,tau,a.metrics.ITAE,qa.GainAtUpperV_pct,toc);
        end
    end
end
Summary=cell2table(rows,'VariableNames',{'Case','Controller','Tau_LPF_s','Seed',...
    'ITAE_m_s2','IAE_m_s','RMSE_pos_m','RMS_control_v_N',...
    'RMS_filter_lag_v_mps','RMS_filter_lag_w_radps',...
    'GainV_Mean','GainW_Mean','GainV_Max','GainW_Max',...
    'GainV_AtMax_pct','GainW_AtMax_pct',...
    'GainV_FirstMax_s','GainW_FirstMax_s','TrueSlidingRMSv_mps'});
writetable(Summary,fullfile(folder,'Stage22_Filter_Comparison.csv'));
% The full numeric trajectories are retained for subsequent technical audit.
save(fullfile(folder,'Stage22_Validation_Data.mat'),...
      'R','Summary','p','noise','cases','controllers','tauTest','-v7.3');

% Grouped plots (same paired noise realization within each case).
for ci=1:numel(cases)
    ca=cases(ci);
    f=figure('Visible','off','Color','w','Position',[70 70 1020 740]);
    subplot(2,1,1);hold on;
    for ic=1:numel(controllers)
        for j=1:numel(tauTest)
            a=R{ci,ic,j};
            if ic==1,style='--';else,style='-';end
            plot(a.t,1000*a.ep,'LineStyle',style,'LineWidth',1.1,...
              'DisplayName',sprintf('%s / %gms',controllers{ic},tauTest(j)*1000));
        end
    end
    xlabel('Time (s)');ylabel('Planar error (mm)');
    legend('Location','best');grid on;
    subplot(2,1,2);hold on;
    for j=1:numel(tauTest)
        a=R{ci,2,j};
        plot(a.t,a.alpha(:,1),'LineWidth',1.2,...
           'DisplayName',sprintf('ASTSMC alpha_v / %gms',tauTest(j)*1000));
    end
    yline(p.AST.alphaMax(1),'--','Gain bound');
    xlabel('Time (s)');ylabel('ASTSMC gain alpha_v');
    legend('Location','best');grid on;
    set(findall(f,'Type','axes'),'FontName','Times New Roman','FontSize',10);
    saveas(f,fullfile(folder,sprintf('Stage22_Case%d_Tracking_Gain.png',ca)));
    set(f,'Visible','on');
    savefig(f,fullfile(folder,sprintf('Stage22_Case%d_Tracking_Gain.fig',ca)));
    set(f,'Visible','off');
    close(f);
end

% Full-mission decision table relative to BYPASS; no hidden retuning.
decisionRows=cell(numel(cases)*numel(controllers),10);rr=0;
for ci=1:numel(cases)
 for ic=1:numel(controllers)
    a0=R{ci,ic,1};a5=R{ci,ic,2};a50=R{ci,ic,3};
    qa=calculate_filter_quality(a5,p);
    rr=rr+1;
    decisionRows(rr,:)={cases(ci),controllers{ic},...
        a0.metrics.ITAE,a5.metrics.ITAE,a50.metrics.ITAE,...
        a5.metrics.ITAE/a0.metrics.ITAE,...
        100*(a5.metrics.ITAE/a0.metrics.ITAE-1),...
        qa.GainAtUpperV_pct,qa.GainAtUpperW_pct,qa.FilterLagRMSv};
 end
end
Decision=cell2table(decisionRows,'VariableNames',{'Case','Controller',...
 'ITAE_bypass','ITAE_5ms','ITAE_50ms','Ratio_5ms_to_bypass',...
 'ITAE_increase_5ms_pct','GainV_AtMax_5ms_pct','GainW_AtMax_5ms_pct',...
 'RMS_filter_lag_5ms_mps'});
writetable(Decision,fullfile(folder,'Stage22_Decision_Summary.csv'));

% Engineering alarms only: a warning is not automatic rejection/proof.
file=fopen(fullfile(folder,'RECOMMENDATION_STATUS.txt'),'w');
if file>=0
 fprintf(file,'STAGE 2.2 - PRELIMINARY ENGINEERING QUALITY CHECK\n');
 fprintf(file,'This is a new sampled-feedback experiment; do not replace archived manuscript metrics.\n');
 fprintf(file,'Full horizon = %.1f s, Ts=%.4f, RNG seed=%d\n',p.sim.tf,p.stage2.Ts,p.stage2.seed);
 fprintf(file,'Controller gains and algorithm unchanged. No torque saturation.\n\n');
 for k=1:height(Decision)
  c=Decision.Case(k);name=Decision.Controller{k};
  if strcmp(name,'ASTSMC')
   gainHit=max(Decision.GainV_AtMax_5ms_pct(k),Decision.GainW_AtMax_5ms_pct(k));
   if gainHit>5,flag='REVIEW_GAIN_BOUND';else,flag='NO_GAIN_BOUND_WARNING';end
  else
   flag='NOT_APPLICABLE';
  end
  fprintf(file,'Case %d %s: ITAE_0ms=%.6f, ITAE_5ms=%.6f, ITAE_50ms=%.6f, ratio5/0=%.3f, %s\n',...
    c,name,Decision.ITAE_bypass(k),Decision.ITAE_5ms(k),...
    Decision.ITAE_50ms(k),Decision.Ratio_5ms_to_bypass(k),flag);
 end
 fprintf(file,'\nNo stability or publication acceptance automatically certified.\n');
 fclose(file);
end
fprintf('Stage 2.2 diagnostic complete. Inspect:\n  %s\n',folder);
end

function qa=calculate_filter_quality(r,p)
lag=r.etaFiltered-r.etaTrue;
qa.FilterLagRMSv=sqrt(mean(lag(:,1).^2));
qa.FilterLagRMSw=sqrt(mean(lag(:,2).^2));
qa.TrueSlidingRMSv=sqrt(mean(r.s(:,1).^2));
if strcmpi(r.controller,'ASTSMC')
 a=r.alpha;
 hit=bsxfun(@ge,a,p.AST.alphaMax(:).'-1e-6);
 qa.GainMeanV=mean(a(:,1));qa.GainMeanW=mean(a(:,2));
 qa.GainMaxV=max(a(:,1));qa.GainMaxW=max(a(:,2));
 qa.GainAtUpperV_pct=100*mean(hit(:,1));
 qa.GainAtUpperW_pct=100*mean(hit(:,2));
 qa.FirstGainUpperV_s=NaN;qa.FirstGainUpperW_s=NaN;
 k=find(hit(:,1),1,'first');if ~isempty(k),qa.FirstGainUpperV_s=r.t(k);end
 k=find(hit(:,2),1,'first');if ~isempty(k),qa.FirstGainUpperW_s=r.t(k);end
else
 qa.GainMeanV=NaN;qa.GainMeanW=NaN;
 qa.GainMaxV=NaN;qa.GainMaxW=NaN;
 qa.GainAtUpperV_pct=NaN;qa.GainAtUpperW_pct=NaN;
 qa.FirstGainUpperV_s=NaN;qa.FirstGainUpperW_s=NaN;
end
end

function folder=create_filter_check_folder(base,prefix)
if ~exist(base,'dir'),mkdir(base);end
baseName=[prefix '_' datestr(now,'yyyymmdd_HHMMSS')];
folder=fullfile(base,baseName);
i=1;
while exist(folder,'dir')
 i=i+1;folder=fullfile(base,sprintf('%s_%02d',baseName,i));
end
[ok,msg]=mkdir(folder);assert(ok,'Cannot create folder: %s',msg);
end
