function [Summary,Raw,folder] = run_gaussian_statistics_reference(nTrials,p)
% RUN_GAUSSIAN_STATISTICS_REFERENCE Optional repeatable seed study for Stage 3.
% Example: [S,R,path] = run_gaussian_statistics_reference(30);
% No figures by default. Nine controller/case runs per trial.
if nargin<1 || isempty(nTrials),nTrials=30;end
if nargin<2 || isempty(p),p=config_noise();end
assert(nTrials>0 && nTrials==floor(nTrials));
p.stage2.exportPlots=false;
controllers={'SMC','STSMC','ASTSMC'};
folder=fullfile(p.stage2.outputBase,['Repeated_Stage2_' datestr(now,'yyyymmdd_HHMMSS')]);
if exist(folder,'dir'),error('Output folder already exists.');end
mkdir(folder);
t=(p.sim.t0:p.stage2.Ts:p.sim.tf)';
rows=cell(nTrials*9,7);rr=0;
baseSeed=p.stage2.seed;
for trial=1:nTrials
    p.stage2.seed=baseSeed+trial-1;
    noise=generate_gaussian_noise(p,numel(t));
    for ca=1:3
        for ic=1:3
            r=simulate_gaussian(p,controllers{ic},ca,noise);
            rr=rr+1;m=r.metrics;
            rows(rr,:)={trial,ca,controllers{ic},p.stage2.seed,...
                m.RMSE_pos,m.IAE,m.ITAE};
        end
    end
    fprintf('Completed random seed trial %d/%d\n',trial,nTrials);
end
Raw=cell2table(rows,'VariableNames',{'Trial','Case','Controller','Seed',...
    'RMSE_pos_m','IAE_m_s','ITAE_m_s2'});
writetable(Raw,fullfile(folder,'Raw_Seed_Results.csv'));
rows2=cell(9,9);ii=0;
for ca=1:3
    for ic=1:3
        ii=ii+1;
        k=Raw.Case==ca & strcmp(Raw.Controller,controllers{ic});
        rows2(ii,:)={ca,controllers{ic},nTrials,...
            mean(Raw.RMSE_pos_m(k)),std(Raw.RMSE_pos_m(k)),...
            mean(Raw.IAE_m_s(k)),std(Raw.IAE_m_s(k)),...
            mean(Raw.ITAE_m_s2(k)),std(Raw.ITAE_m_s2(k))};
    end
end
Summary=cell2table(rows2,'VariableNames',{'Case','Controller','Trials',...
    'Mean_RMSE','Std_RMSE','Mean_IAE','Std_IAE','Mean_ITAE','Std_ITAE'});
writetable(Summary,fullfile(folder,'Summary_Seed_Results.csv'));
save(fullfile(folder,'Seed_Study_Metrics.mat'),'Raw','Summary','p');
disp(Summary);
end
