function [Metrics,Effects,LPFcheck,outDir] = run_ablation(mode,seed,p)
% RUN_ABLATION N0-N4: matched-noise, single-seed ablation for Stage 3.
%
% USE:
%   [M,D,L,folder] = run_ablation('quick'); % 15 s, software test only
%   [M,D,L,folder] = run_ablation('full');  % 75 s, publication screening
%   [M,D,L,folder] = run_ablation('full',20261113);
%
% Reuses UNCHANGED original SMC/STSMC/ASTSMC controllers and Stage 2.2
% model_robot_dynamics. Samples Gaussian process/sensor noise ONCE with the SAME seed
% for all five modes and all three controllers. No motor saturation/AW.
%
% N0: original external sin+bias, no Gaussian noise, no LPF (Case 2)
% N1: N0 + Gaussian process acceleration, no sensor noise, no LPF
% N2: N1 + Gaussian velocity measurement, no LPF
% N3: N2 + common 5 ms LPF for all controllers
% N4: N3 + original variable payload 0/300/800/200/0 kg (Case 3)
%
% Causal contrast labels in Effects are conditional on THIS noise draw.
% One seed does not establish statistical mean improvements or LPF efficacy.

if nargin < 1 || isempty(mode), mode='full'; end
if nargin < 2 || isempty(seed), seed=20261113; end
mode=lower(char(mode));
assert(any(strcmp(mode,{'quick','full'})), 'mode must be quick or full');
assert(isscalar(seed) && isfinite(seed) && seed>=0 && seed==floor(seed), ...
    'seed must be a nonnegative integer');
assert(exist('config_noise','file')==2 && ...
       exist('simulate_gaussian','file')==2 && ...
       exist('generate_gaussian_noise','file')==2, ...
    'Run from AMR_ASTSMC_Stage3 folder containing all Stage 2 functions.');
if nargin<3 || isempty(p), p=config_noise(); end
p.stage2.seed=seed;
p.stage2.tauLPF=[0.005;0.005];
p.stage2.exportPlots=false;
p.stage2.exportOriginalStyle=false;
p.stage2.printProgress=false;
p.stage2.saveMAT=false;
p.stage2.useExternalDisturbance=true;
if strcmp(mode,'quick'), p.sim.tf=15; else, p.sim.tf=75; end
assert(abs(p.stage2.Ts-0.01)<1e-12, 'Stage 3 uses Ts=0.01 s.');
assert(all(abs(p.stage2.tauLPF-0.005)<1e-12));
t=(p.sim.t0:p.stage2.Ts:p.sim.tf)';
noise=generate_gaussian_noise(p,numel(t));
assert(size(noise.sensor,2)==numel(t));
assert(size(noise.process,2)==numel(t)-1);

outDir=ablation_new_folder(p.stage2.outputBase, ...
    ['Stage3_Ablation_' mode]);
save(fullfile(outDir,'Ablation_Configuration_and_Noise.mat'), ...
    'p','noise','t');
controllers={'SMC','STSMC','ASTSMC'};
modeLabels={'N0','N1','N2','N3','N4'};
caseNos=[2 2 2 2 3];
results=cell(5,3);
metricNames={'Mode','Condition','Case','Controller','Seed', ...
    'ExternalSinBias','ProcessGaussian','SensorGaussian','LPF_5ms', ...
    'Payload','ITAE_m_s2','IAE_m_s','ISE_m2_s','RMSE_pos_m', ...
    'Max_pos_m','RMSE_heading_rad','RMS_sliding_v_mps', ...
    'RMS_sliding_w_radps','RMS_uv_N','RMS_uw_Nm', ...
    'RMSE_pos_27to42_m','IAE_pos_27to42_m_s', ...
    'Max_gain_v','Max_gain_w','Gain_upper_v_pct','Gain_upper_w_pct'};
metricRows=cell(15,numel(metricNames));
rr=0;
fprintf('\nStage 3 N0-N4 ablation | %s | seed=%d | %.0f s\n', ...
    mode,seed,p.sim.tf);
fprintf('Frozen Ts=%.3f s, LPF tau=%.3f s; no saturation/anti-windup.\n', ...
    p.stage2.Ts,p.stage2.tauLPF(1));
for mi=1:5
    pm=p;
    pm.stage2.useExternalDisturbance=true;
    pm.stage2.useProcessNoise=(mi>=2);
    pm.stage2.useSensorNoise=(mi>=3);
    pm.stage2.useLPF=(mi>=4);
    pm.stage2.usePayload=(mi==5);
    % External sine+bias is always enabled in this N0-N4 contrast.
    for ci=1:3
        controller=controllers{ci};
        r=simulate_gaussian(pm,controller,caseNos(mi),noise);
        results{mi,ci}=r;
        m=r.metrics;
        assert(all(isfinite([m.ITAE,m.IAE,m.ISE,m.RMSE_pos, ...
             m.RMS_sliding_v,m.RMS_uv])), ...
             'Non-finite result for %s/%s',modeLabels{mi},controller);
        [winRmse,winIAE]=window_metrics(r,27,42);
        [capV,capW]=gain_upper_percent(r,p);
        rr=rr+1;
        metricRows(rr,:)={modeLabels{mi},ablation_condition(mi), ...
            caseNos(mi),controller,seed,true,pm.stage2.useProcessNoise, ...
            pm.stage2.useSensorNoise,pm.stage2.useLPF,pm.stage2.usePayload, ...
            m.ITAE,m.IAE,m.ISE,m.RMSE_pos,m.Max_pos,m.RMSE_theta, ...
            m.RMS_sliding_v,m.RMS_sliding_w,m.RMS_uv,m.RMS_uw, ...
            winRmse,winIAE,m.Max_alpha_v,m.Max_alpha_w,capV,capW};
        fprintf('  %s %-6s | ITAE=%9.5f | RMSE=%8.5f m', ...
            modeLabels{mi},controller,m.ITAE,m.RMSE_pos);
        if strcmp(controller,'ASTSMC')
            fprintf(' | max gains %.3f / %.3f',m.Max_alpha_v,m.Max_alpha_w);
        end
        fprintf('\n');
    end
end
Metrics=cell2table(metricRows,'VariableNames',metricNames);
writetable(Metrics,fullfile(outDir,'Stage3_Ablation_N0_N4_Metrics.csv'));

% Per-controller signed sequential effects. Delta positive => metric worse.
effectNames={'Controller','Comparison','Change','Seed','ITAE_before_m_s2', ...
    'ITAE_after_m_s2','DeltaITAE_m_s2','DeltaITAE_pct', ...
    'DeltaRMSE_pos_mm','DeltaRMS_uv_N','DeltaRMS_sliding_v_mmps'};
effectRows=cell(3*4,numel(effectNames));
e=0;
for ci=1:3
    for mi=2:5
        before=results{mi-1,ci}.metrics;
        after=results{mi,ci}.metrics;
        e=e+1;
        effectRows(e,:)={controllers{ci}, ...
            sprintf('N%d to N%d',mi-2,mi-1),ablation_change(mi),seed, ...
            before.ITAE,after.ITAE,after.ITAE-before.ITAE, ...
            100*(after.ITAE-before.ITAE)/max(abs(before.ITAE),eps), ...
            1000*(after.RMSE_pos-before.RMSE_pos), ...
            after.RMS_uv-before.RMS_uv, ...
            1000*(after.RMS_sliding_v-before.RMS_sliding_v)};
    end
end
Effects=cell2table(effectRows,'VariableNames',effectNames);
writetable(Effects,fullfile(outDir,'Stage3_Ablation_Sequential_Effects.csv'));

% Quantify only the PURE SENSOR NOISE attenuation, avoiding contamination
% by real velocity model_robot_dynamics and LPF lag. Mathematically:
% LPF(etaTrue+n)-LPF(etaTrue) = LPF(n), with same initialization.
lpfNames={'Mode','Controller','Seed','RawNoiseRMS_v_mps', ...
    'FilteredNoiseRMS_v_mps','NoiseReduction_v_pct','RawNoiseRMS_w_radps', ...
    'FilteredNoiseRMS_w_radps','NoiseReduction_w_pct', ...
    'FeedbackErrorRMS_v_mps','FeedbackErrorRMS_w_radps'};
lpfRows=cell(3*3,numel(lpfNames));
ll=0;
for mi=3:5
    for ci=1:3
        r=results{mi,ci};
        raw=r.etaMeasured-r.etaTrue;
        if mi==3 % N2 = no LPF
            pure=raw;
        else
            pure=ablation_lpf_noise(raw,p.stage2.Ts,p.stage2.tauLPF);
        end
        rawRms=sqrt(mean(raw.^2,1));
        filteredRms=sqrt(mean(pure.^2,1));
        pct=100*(1-filteredRms./max(rawRms,eps));
        feedbackRms=sqrt(mean((r.etaFiltered-r.etaTrue).^2,1));
        ll=ll+1;
        lpfRows(ll,:)={modeLabels{mi},controllers{ci},seed, ...
            rawRms(1),filteredRms(1),pct(1), ...
            rawRms(2),filteredRms(2),pct(2), ...
            feedbackRms(1),feedbackRms(2)};
    end
end
LPFcheck=cell2table(lpfRows,'VariableNames',lpfNames);
writetable(LPFcheck,fullfile(outDir,'Stage3_LPF_Noise_Attenuation.csv'));

% Keep every model_reference_trajectory for exact regeneration; no results are invented.
save(fullfile(outDir,'Stage3_Ablation_All_Results.mat'), ...
    'results','Metrics','Effects','LPFcheck','p','noise','-v7.3');
if strcmp(mode,'full')
    plot_ablation(results,p,noise,outDir);
end
write_quality_review(results,Metrics,Effects,LPFcheck,p,seed,mode,outDir);
disp(Metrics(:,{'Mode','Controller','ITAE_m_s2','RMSE_pos_m', ...
     'RMSE_pos_27to42_m','Max_gain_v'}));
fprintf('\nAblation complete. Output:\n%s\n',outDir);
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

function [rmse,iae]=window_metrics(r,t0,t1)
idx=(r.t>=t0 & r.t<=t1);
if nnz(idx)<2
    rmse=NaN;iae=NaN;return;
end
t=r.t(idx); e=r.ep(idx);
rmse=sqrt(trapz(t,e.^2)/(t(end)-t(1)));
iae=trapz(t,e);
end

function [v,w]=gain_upper_percent(r,p)
v=NaN;w=NaN;
if strcmpi(r.controller,'ASTSMC')
    a=r.alpha;
    v=100*mean(a(:,1)>=p.AST.alphaMax(1)-1e-6);
    w=100*mean(a(:,2)>=p.AST.alphaMax(2)-1e-6);
end
end

function x=ablation_condition(i)
names={'External only, no LPF', ...
       'External + process Gaussian, no LPF', ...
       'External + process + sensor Gaussian, no LPF', ...
       'External + both Gaussian + 5ms LPF', ...
       'Previous + variable payload (Case 3)'};
x=names{i};
end
function x=ablation_change(i)
names={'','Added process Gaussian', ...
       'Added sensor Gaussian','Enabled common 5ms LPF', ...
       'Added variable payload'};
x=names{i};
end

function write_quality_review(R,M,Effects,L,p,seed,mode,folder)
fid=fopen(fullfile(folder,'Stage3_Ablation_Quality_Review.txt'),'w');
if fid<0,error('Cannot write review');end
cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'STAGE 3 N0-N4 ABLATION QUALITY REVIEW\n');
fprintf(fid,'Mode: %s; seed=%d; duration=%.0f s\n',mode,seed,p.sim.tf);
fprintf(fid,'Ts=%.4f s; tauLPF=%.4f s; RK4 substeps=%d\n', ...
    p.stage2.Ts,p.stage2.tauLPF(1),p.stage2.rkSubsteps);
fprintf(fid,'Gaussian acceleration sigma=[%.6g %.6g]; measurement sigma=[%.6g %.6g]\n', ...
    p.stage2.processSigma,p.stage2.sensorSigma);
fprintf(fid,'Original controllers, external disturbance and payload dynamics unchanged.\n');
fprintf(fid,'NO actuator saturation, gain freezing, or anti-windup.\n');
fprintf(fid,'N0 external only. N1 + process. N2 + sensor. N3 + LPF. N4 + payload.\n\n');
for mi=1:5
    fprintf(fid,'N%d ITAE: SMC=%.6f STSMC=%.6f ASTSMC=%.6f\n',mi-1, ...
        R{mi,1}.metrics.ITAE,R{mi,2}.metrics.ITAE,R{mi,3}.metrics.ITAE);
end
fprintf(fid,'\nASTSMC gain upper bound occupancy (N3/N4):\n');
for mi=4:5
    [g1,g2]=gain_upper_percent(R{mi,3},p);
    fprintf(fid,'N%d: alpha_v=%.3f%% alpha_w=%.3f%%\n',mi-1,g1,g2);
end
fprintf(fid,'\nLPF CHECK: N3 ASTSMC\n');
idx=strcmp(L.Mode,'N3') & strcmp(L.Controller,'ASTSMC');
if nnz(idx)==1
    fprintf(fid,'Pure longitudinal measurement-noise RMS: raw %.8g -> LPF %.8g m/s (%.2f%% reduction)\n', ...
        L.RawNoiseRMS_v_mps(idx),L.FilteredNoiseRMS_v_mps(idx), ...
        L.NoiseReduction_v_pct(idx));
    fprintf(fid,'Feedback error RMS (includes delay): %.8g m/s\n', ...
        L.FeedbackErrorRMS_v_mps(idx));
end
fprintf(fid,'\nN4 vs frozen Stage-3 seed 20261113 regression check:\n');
if seed==20261113 && strcmp(mode,'full')
    refST=5.313152; refAST=2.827808;
    deltaST=R{5,2}.metrics.ITAE-refST;
    deltaAST=R{5,3}.metrics.ITAE-refAST;
    fprintf(fid,'STSMC delta ITAE from archived Stage3 seed: %+.7f\n',deltaST);
    fprintf(fid,'ASTSMC delta ITAE from archived Stage3 seed: %+.7f\n',deltaAST);
    if abs(deltaST)>0.0005 || abs(deltaAST)>0.0005
        fprintf(fid,'WARNING: N4 regression mismatch. Check source version, Ts, sigma, seed.\n');
    else
        fprintf(fid,'PASS: N4 matches archived Stage3 first-seed results within 0.0005.\n');
    end
else
    fprintf(fid,'Not applicable (non-reference seed or quick run).\n');
end
fprintf(fid,'\nINTERPRETATION BOUNDARIES:\n');
fprintf(fid,'- Sequential N0-N4 effects are from ONE selected seed, not CI estimates.\n');
fprintf(fid,'- N4 adds payload AND changes case label 2->3, with SAME external/process/sensor models.\n');
fprintf(fid,'- 5ms LPF with 10ms sampling yields modest random-noise reduction.\n');
fprintf(fid,'- LPF can increase tracking error through lag; noise attenuation alone does not prove benefit.\n');
fprintf(fid,'- Gaussian acceleration is sample-held, not ideal continuous-time white noise.\n');
fprintf(fid,'- These results do not certify the previous Lyapunov proof for stochastic sampled feedback.\n');
fprintf(fid,'- Quick (15s) results MUST NOT be used to assess 800kg interval (27-42s).\n');
fprintf(fid,'- Archived paper Table 2 is unchanged; do not overwrite without review.\n');
end

function folder=ablation_new_folder(base,prefix)
if ~exist(base,'dir'), [ok,msg]=mkdir(base);assert(ok,'%s',msg);end
stem=[prefix '_' datestr(now,'yyyymmdd_HHMMSS')];
folder=fullfile(base,stem);
k=0;
while exist(folder,'dir')
    k=k+1;folder=fullfile(base,sprintf('%s_%02d',stem,k));
end
[ok,msg]=mkdir(folder);assert(ok,'Cannot create folder: %s',msg);
end
