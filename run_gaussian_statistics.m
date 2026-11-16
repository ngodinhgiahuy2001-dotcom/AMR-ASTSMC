function [Raw,Summary,Paired,outDir] = run_gaussian_statistics(mode,nTrials,p)
% RUN_GAUSSIAN_STATISTICS 30 paired Gaussian-seed trials for ASTSMC paper.
% Operates on the VERIFIED Stage-2.2 model and ORIGINAL controllers.
%
%   [Raw,Summary,Paired,folder] = run_gaussian_statistics('quick'); % 3 seeds, 15 s
%   [Raw,Summary,Paired,folder] = run_gaussian_statistics('full');  % 30 seeds, 75 s
%   [Raw,Summary,Paired,folder] = run_gaussian_statistics('full',50);
%
% Case 1 is deterministic and is computed ONCE per controller.  Cases 2
% and 3 share EXACTLY the same process/sensor noise for each seed and
% controller.  No gain tuning, saturation, gain-freeze or anti-windup.
% The bootstrap CI is a seed-conditional inference about the simulated
% noise model; it is NOT a stability certificate.
if nargin<1 || isempty(mode), mode='full'; end
mode=lower(char(mode));
assert(ismember(mode,{'quick','full'}),'Mode must be ''quick'' or ''full''.');
if nargin<2 || isempty(nTrials)
    if strcmp(mode,'quick'), nTrials=3; else, nTrials=30; end
end
assert(isscalar(nTrials) && nTrials>=2 && nTrials==floor(nTrials),...
    'nTrials must be an integer >=2.');
assert(exist('simulate_gaussian','file')==2, ...
    'Place this file in the Stage-2.2 source folder.');
if nargin<3 || isempty(p), p=config_noise(); end
p.stage2.exportPlots=false;
p.stage2.saveMAT=false;
p.stage2.printProgress=false;
p.stage2.exportOriginalStyle=false;
if strcmp(mode,'quick'), p.sim.tf=15; else, p.sim.tf=75; end
assert(p.stage2.useLPF && p.stage2.useProcessNoise && ...
    p.stage2.useSensorNoise && p.stage2.useExternalDisturbance && ...
    p.stage2.usePayload,'Stage-3 requires the agreed Stage-2.2 settings.');
assert(all(abs(p.stage2.tauLPF(:)-0.005)<1e-12), ...
    'For this frozen Stage-3 study, tauLPF must be 0.005 s.');
assert(abs(p.stage2.Ts-0.01)<1e-12,'Frozen controller Ts must be 0.01 s.');
assert(p.sim.tf>p.sim.t0);
controllers={'SMC','STSMC','ASTSMC'};
cases=[2,3];
nt=numel(controllers);nc=numel(cases);
t=(p.sim.t0:p.stage2.Ts:p.sim.tf)';
assert(abs(t(end)-p.sim.tf)<1e-9);
outDir=create_statistics_folder(p.stage2.outputBase,['Stage3_Statistics_' mode]);
diaryFile=fullfile(outDir,'MATLAB_Run_Log.txt');
diary(diaryFile);diary on;
cleanupDiary=onCleanup(@() diary('off')); %#ok<NASGU>
fprintf('\n=== ASTSMC STAGE 3: %s | seeds=%d ===\n',mode,nTrials);
fprintf('Ts %.3f s | LPF %.3f s | duration %.1f s | seed start %d\n',...
    p.stage2.Ts,p.stage2.tauLPF(1),p.sim.tf,p.stage2.seed);
fprintf('Controller gains FIXED; baseline unchanged; no actuator constraints.\n');

% The deterministic Case-1 benchmark must NOT be replicated as n=30.
noise0=generate_gaussian_noise(p,numel(t));
nominal=cell(nt,1);nomRows=cell(nt,10);
for j=1:nt
    r=simulate_gaussian(p,controllers{j},1,noise0);
    nominal{j}=r;
    m=r.metrics;
    nomRows(j,:)={1,controllers{j},m.ITAE,m.IAE,m.RMSE_pos,...
        m.RMS_uv,m.RMS_sliding_v,m.Max_alpha_v,m.Max_alpha_w,p.stage2.seed};
    fprintf('Case 1 nominal %-6s  ITAE=%.6f (ONE run)\n',controllers{j},m.ITAE);
end
Nominal=cell2table(nomRows,'VariableNames',{'Case','Controller','ITAE_m_s2',...
    'IAE_m_s','RMSE_pos_m','RMS_uv_N','RMS_sliding_v_mps',...
    'Max_alpha_v','Max_alpha_w','Seed_UNUSED_nominal'});
writetable(Nominal,fullfile(outDir,'Case1_Nominal_Once.csv'));

varNames={'Trial','Seed','Case','Controller','ITAE_m_s2','IAE_m_s',...
    'ISE_m2_s','RMSE_pos_m','RMSE_heading_rad','MaxPos_m',...
    'RMS_sliding_v_mps','RMS_sliding_w_radps','RMS_uv_N','RMS_uw_Nm',...
    'RMSE_pos_27to42_m','IAE_pos_27to42_m_s','MaxGain_v','MaxGain_w',...
    'GainAtUpper_v_pct','GainAtUpper_w_pct','SensorErrorRMS_v_mps',...
    'FilterErrorRMS_v_mps','MeanGain_v','MeanGain_w','MaxPayload_kg'};
rows=cell(nTrials*nt*nc,numel(varNames));
Rep=cell(nc,nt);Worst_AST=cell(nc,1);
worstITAE=-inf(nc,1);
ir=0;
for trial=1:nTrials
    pTrial=p;
    pTrial.stage2.seed=p.stage2.seed+trial-1;
    noise=generate_gaussian_noise(pTrial,numel(t)); % sampled once / seed
    for icase=1:nc
        ca=cases(icase);
        for j=1:nt
            name=controllers{j};
            r=simulate_gaussian(pTrial,name,ca,noise);
            m=r.metrics;
            assert(all(isfinite([m.ITAE,m.IAE,m.ISE,m.RMSE_pos,m.RMS_uv])),...
                'Non-finite metric: seed=%d, case=%d, controller=%s',...
                pTrial.stage2.seed,ca,name);
            [localRMSE,localIAE]=calculate_statistics_window(r,27,42);
            if strcmp(name,'ASTSMC')
                hit=bsxfun(@ge,r.alpha,p.AST.alphaMax(:).'-1e-6);
                gainV=100*mean(hit(:,1));gainW=100*mean(hit(:,2));
                maxGainV=m.Max_alpha_v;maxGainW=m.Max_alpha_w;
                meanGainV=m.Mean_alpha_v;meanGainW=m.Mean_alpha_w;
                if m.ITAE>worstITAE(icase)
                    worstITAE(icase)=m.ITAE;
                    Worst_AST{icase}=r;
                end
            else
                gainV=NaN;gainW=NaN;maxGainV=NaN;maxGainW=NaN;
                meanGainV=NaN;meanGainW=NaN;
            end
            T=r.t(end)-r.t(1);
            sensorErr=r.etaMeasured(:,1)-r.etaTrue(:,1);
            filterErr=r.etaFiltered(:,1)-r.etaTrue(:,1);
            sensorRMS=sqrt(trapz(r.t,sensorErr.^2)/T);
            filterRMS=sqrt(trapz(r.t,filterErr.^2)/T);
            ir=ir+1;
            rows(ir,:)={trial,pTrial.stage2.seed,ca,name,m.ITAE,m.IAE,m.ISE,...
                m.RMSE_pos,m.RMSE_theta,m.Max_pos,m.RMS_sliding_v,...
                m.RMS_sliding_w,m.RMS_uv,m.RMS_uw,localRMSE,localIAE,...
                maxGainV,maxGainW,gainV,gainW,sensorRMS,filterRMS,...
                meanGainV,meanGainW,max(r.mp)};
            if trial==1,Rep{icase,j}=r;end
        end
    end
    % Save recoverable partial CSV after each paired seed.
    RawPartial=cell2table(rows(1:ir,:),'VariableNames',varNames);
    writetable(RawPartial,fullfile(outDir,'Stage3_Raw_Partial.csv'));
    fprintf('Completed paired seed %d/%d (seed=%d)\n',...
        trial,nTrials,pTrial.stage2.seed);
end
Raw=cell2table(rows,'VariableNames',varNames);
writetable(Raw,fullfile(outDir,'Stage3_Raw_All_Seeds.csv'));

% Paired seed comparisons and bootstrap confidence intervals.
SumRows=cell(nc*nt,15);idx=0;
for icase=1:nc
    ca=cases(icase);
    for j=1:nt
        idx=idx+1;name=controllers{j};
        mask=Raw.Case==ca & strcmp(Raw.Controller,name);
        itae=Raw.ITAE_m_s2(mask);
        iae=Raw.IAE_m_s(mask);
        rmse=Raw.RMSE_pos_m(mask);
        rmsu=Raw.RMS_uv_N(mask);
        slide=Raw.RMS_sliding_v_mps(mask);
        local=Raw.RMSE_pos_27to42_m(mask);
        hits=Raw.GainAtUpper_v_pct(mask);
        ci=calculate_bootstrap_ci(itae,2000,101000+idx);
        SumRows(idx,:)={ca,name,nTrials,mean(itae),std(itae),ci(1),ci(2),...
            mean(iae),std(iae),mean(rmse),std(rmse),mean(rmsu),...
            mean(slide),mean(local,'omitnan'),calculate_mean_finite(hits)};
    end
end
Summary=cell2table(SumRows,'VariableNames',{'Case','Controller','Trials',...
    'Mean_ITAE','SD_ITAE','CI95_Mean_ITAE_L','CI95_Mean_ITAE_U',...
    'Mean_IAE','SD_IAE','Mean_RMSE','SD_RMSE','Mean_RMS_uv',...
    'Mean_RMS_sliding_v','Mean_RMSE_27to42','Mean_GainV_AtUpper_pct'});
writetable(Summary,fullfile(outDir,'Stage3_Summary_Statistics.csv'));

pairNames={'STSMC','SMC'};
PairRows=cell(nc*numel(pairNames),13);ip=0;
for icase=1:nc
    ca=cases(icase);
    keyAst=Raw.Case==ca & strcmp(Raw.Controller,'ASTSMC');
    A=Raw(keyAst,:);
    [~,ia]=sort(A.Trial);A=A(ia,:);
    for j=1:numel(pairNames)
        name=pairNames{j};
        B=Raw(Raw.Case==ca & strcmp(Raw.Controller,name),:);
        [~,ib]=sort(B.Trial);B=B(ib,:);
        assert(isequal(A.Trial,B.Trial) && isequal(A.Seed,B.Seed),...
            'Controller sample streams are not seed paired.');
        delta=B.ITAE_m_s2-A.ITAE_m_s2; % >0 favors ASTSMC
        pct=100*delta./B.ITAE_m_s2;
        ciPct=calculate_bootstrap_ci(pct,3000,201000+ca*10+j);
        ciDelta=calculate_bootstrap_ci(delta,3000,301000+ca*10+j);
        validWin=isfinite(B.RMSE_pos_27to42_m) & B.RMSE_pos_27to42_m>0;
        localPct=100*(B.RMSE_pos_27to42_m(validWin)-...
            A.RMSE_pos_27to42_m(validWin))./B.RMSE_pos_27to42_m(validWin);
        ip=ip+1;
        PairRows(ip,:)={ca,name,'ASTSMC',nTrials,mean(pct),median(pct),...
            ciPct(1),ciPct(2),100*mean(delta>0),mean(delta),...
            ciDelta(1),ciDelta(2),calculate_mean_finite(localPct)};
    end
end
Paired=cell2table(PairRows,'VariableNames',{'Case','Comparator','Proposed',...
    'PairedTrials','Mean_ITAE_Improvement_pct','Median_Improvement_pct',...
    'CI95_Improvement_L_pct','CI95_Improvement_U_pct','ASTSMC_WinRate_pct',...
    'Mean_Delta_ITAE','CI95_Delta_ITAE_L','CI95_Delta_ITAE_U',...
    'Mean_Local_RMSE_Improvement_27to42_pct'});
writetable(Paired,fullfile(outDir,'Stage3_Paired_Comparison.csv'));

% Save ONLY 1st-seed and worst ASTSMC trajectories; avoids giant archives.
save(fullfile(outDir,'Stage3_Representative_Data.mat'),...
    'Rep','Worst_AST','Nominal','p','controllers','cases','-v7.3');
save(fullfile(outDir,'Stage3_Statistics_All.mat'),...
    'Raw','Summary','Paired','Nominal','p','nTrials','mode','-v7.3');
plot_gaussian_statistics(Raw,Summary,Paired,Rep,p,outDir);
export_statistics_review(Raw,Paired,p,mode,nTrials,outDir);
try
    delete(fullfile(outDir,'Stage3_Raw_Partial.csv'));
catch
end
fprintf('\nDONE. Stage-3 results: %s\n',outDir);
fprintf('DO NOT replace paper figures until statistics + proofs are reviewed.\n');
end

function [rmse,iae]=calculate_statistics_window(r,t1,t2)
k=r.t>=t1-1e-9 & r.t<=t2+1e-9;
if nnz(k)<2
    rmse=NaN;iae=NaN;return;
end
t=r.t(k);e=r.ep(k);
rmse=sqrt(trapz(t,e.^2)/(t(end)-t(1)));
iae=trapz(t,e);
end

function ci=calculate_bootstrap_ci(x,B,seed)
% 95% percentile bootstrap of paired-seed means, Statistics Toolbox free.
x=x(isfinite(x));x=x(:);n=numel(x);
if n<2,ci=[NaN NaN];return;end
prior=rng;
restoreRng=onCleanup(@() rng(prior)); %#ok<NASGU>
rng(seed,'twister');
means=zeros(B,1);
for b=1:B
    means(b)=mean(x(randi(n,n,1)));
end
means=sort(means);
ci=[calculate_quantile(means,0.025),calculate_quantile(means,0.975)];
end

function y=calculate_quantile(sorted,p)
n=numel(sorted);z=1+p*(n-1);a=floor(z);b=ceil(z);
y=sorted(a)+(z-a)*(sorted(b)-sorted(a));
end

function a=calculate_mean_finite(x)
x=x(isfinite(x));
if isempty(x),a=NaN;else,a=mean(x);end
end

function folder=create_statistics_folder(base,prefix)
if ~exist(base,'dir'),mkdir(base);end
stem=[prefix '_' datestr(now,'yyyymmdd_HHMMSS')];
folder=fullfile(base,stem);i=1;
while exist(folder,'dir')
    i=i+1;folder=fullfile(base,sprintf('%s_%02d',stem,i));
end
[ok,msg]=mkdir(folder);
assert(ok,'Failed to create Stage-3 output folder: %s',msg);
end

function export_statistics_review(Raw,Paired,p,mode,nTrials,folder)
f=fopen(fullfile(folder,'Stage3_Quality_Review.txt'),'w');
assert(f>=0,'Unable to create Stage-3 quality report.');
c=onCleanup(@() fclose(f)); %#ok<NASGU>
fprintf(f,'STAGE 3 -- SCIENTIFIC QUALITY REVIEW (NOT AUTOMATIC ACCEPTANCE)\n');
fprintf(f,'Mode: %s, seeds: %d, seed range: %d to %d\n',...
    mode,nTrials,p.stage2.seed,p.stage2.seed+nTrials-1);
fprintf(f,'Ts=%.4f s, tauLPF=%.4f s; RK4 substeps=%d, tf=%.1f s\n',...
    p.stage2.Ts,p.stage2.tauLPF(1),p.stage2.rkSubsteps,p.sim.tf);
fprintf(f,'Gaussian accel sigma=[%.5g %.5g]; sensor sigma=[%.5g %.5g]\n',...
    p.stage2.processSigma,p.stage2.sensorSigma);
fprintf(f,'Case 1 deterministic: once per controller. Case 2/3: paired seeds.\n');
fprintf(f,'Same original ASTSMC/STSMC/SMC gains, same measurement LPF.\n');
fprintf(f,'No actuator saturation; no gain freezing; no anti-windup.\n\n');
for ca=[2 3]
   k=Raw.Case==ca & strcmp(Raw.Controller,'ASTSMC');
   vv=Raw.GainAtUpper_v_pct(k);ww=Raw.GainAtUpper_w_pct(k);
   fprintf(f,'Case %d ASTSMC: maximum alphaV cap fraction %.3f%%, alphaW %.3f%%\n',...
       ca,max(vv),max(ww));
   if max([vv;ww])>5
       fprintf(f,'WARNING: Gain at upper projection bound >5%% on some seeds.\n');
   end
end
fprintf(f,'\nPAIRED ITAE COMPARISONS (positive favors ASTSMC)\n');
for i=1:height(Paired)
    fprintf(f,'Case %d vs %s: mean improvement %.3f%%; bootstrap 95%% CI [%.3f,%.3f]; win rate %.1f%%\n',...
        Paired.Case(i),Paired.Comparator{i},Paired.Mean_ITAE_Improvement_pct(i),...
        Paired.CI95_Improvement_L_pct(i),...
        Paired.CI95_Improvement_U_pct(i),Paired.ASTSMC_WinRate_pct(i));
end
fprintf(f,'\nBefore publication:\n');
fprintf(f,'[ ] Confirm ALL 30 full-length paired seeds completed (quick is not publishable).\n');
fprintf(f,'[ ] Check input effort, sliding RMS, peak errors, 27-42s RMS, gain projection.\n');
fprintf(f,'[ ] Compare N0-N4 ablation with same seed separately, not as a 30-seed claim.\n');
fprintf(f,'[ ] Report process noise as sample-held Gaussian acceleration (not ideal Wiener noise).\n');
fprintf(f,'[ ] Treat LPF 5ms as provisional; Ts=10ms; do not call it optimal.\n');
fprintf(f,'[ ] Lyapunov proof for bounded deterministic disturbances does not certify noisy sampled dynamics.\n');
fprintf(f,'[ ] Do not overwrite archived manuscript Table 2 until reviewed.\n');
end
