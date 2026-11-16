function [allResults,Metrics,outputFolder] = run_gaussian(p)
% RUN_GAUSSIAN  Main entry point for Stage 2 Gaussian-noise + LPF study.
% USAGE:
%   [R,M,folder] = run_gaussian;
%   p=config_noise; p.stage2.exportPlots=false; run_gaussian(p);
% The numerical baseline model is retained after function renaming.
% Warning: not identical to archived continuous-feedback RK4 experiments.
if nargin<1 || isempty(p),p=config_noise();end
check_noise_settings(p);
Ts=p.stage2.Ts;
t=(p.sim.t0:Ts:p.sim.tf)';
noise=generate_gaussian_noise(p,numel(t));
outputFolder=create_noise_folder(p.stage2.outputBase,'Results_Stage2_Gaussian_LPF');
save(fullfile(outputFolder,'Stage2_Parameters_and_Noise.mat'),'p','noise','t');

names={'SMC','STSMC','ASTSMC'};
allResults=cell(3,3);
rows=cell(9,16); ir=0;
fprintf('\nSTAGE 2: sampled Gaussian process + sensor noise + common LPF\n');
fprintf('Output folder: %s\n',outputFolder);
fprintf('Ts=%.4f s, RK4 substeps=%d, seed=%d; NO actuator saturation.\n', ...
    Ts,p.stage2.rkSubsteps,p.stage2.seed);
for ca=1:3
    caseDir=fullfile(outputFolder,sprintf('Case%d',ca));
    if ~exist(caseDir,'dir'),mkdir(caseDir);end
    for ic=1:3
        name=names{ic}; tic;
        r=simulate_gaussian(p,name,ca,noise);
        allResults{ca,ic}=r;
        if p.stage2.saveMAT
            result=r; %#ok<NASGU>
            save(fullfile(caseDir,sprintf('Case%d_%s.mat',ca,name)),'result');
        end
        m=r.metrics; ir=ir+1;
        rows(ir,:)={ca,name,p.stage2.seed,m.RMSE_pos,m.Max_pos,...
            m.RMSE_theta,m.IAE,m.ISE,m.ITAE,m.RMS_uv,m.RMS_uw, ...
            m.RMS_sliding_v,m.RMS_sliding_w,m.Max_alpha_v, ...
            m.Mean_alpha_v,m.Mean_alpha_w};
        if p.stage2.printProgress
            fprintf('Case %d - %-6s | ITAE=%10.6f | RMSE=%9.6f m | %.2f s\n',...
                ca,name,m.ITAE,m.RMSE_pos,toc);
        end
    end
    if p.stage2.exportPlots
        plot_gaussian_results(allResults(ca,:),ca,caseDir);
    end
    if p.stage2.exportOriginalStyle
        % Historical plotting functions operate on the SAME stage-2 result
        % structure but these figures are new, NOT the manuscript archive.
        originalDir=fullfile(outputFolder,'Original_Style_Plots');
        if ~exist(originalDir,'dir'),mkdir(originalDir);end
        plot_deterministic_comparison(allResults(ca,:),p,ca,originalDir);
    end
end
Metrics=cell2table(rows,'VariableNames',{'Case','Controller','Seed', ...
    'RMSE_pos_m','Max_pos_m','RMSE_heading_rad','IAE_m_s','ISE_m2_s',...
    'ITAE_m_s2','RMS_uv_N','RMS_uw_Nm','RMS_sliding_v_mps',...
    'RMS_sliding_w_radps','Max_alpha_v','Mean_alpha_v','Mean_alpha_w'});
disp(Metrics);
writetable(Metrics,fullfile(outputFolder,'Metrics_3Cases_Stage2.csv'));
if p.stage2.saveMAT
    save(fullfile(outputFolder,'All_Stage2_Results.mat'),'allResults','Metrics','p','noise','-v7.3');
end
fprintf('Done. CSV, logs and figures saved to:\n%s\n',outputFolder);
end

function check_noise_settings(p)
assert(p.stage2.Ts>0 && isfinite(p.stage2.Ts));
assert(p.sim.tf>p.sim.t0);
assert(p.stage2.rkSubsteps>=1 && p.stage2.rkSubsteps==floor(p.stage2.rkSubsteps));
assert(numel(p.stage2.processSigma)==2 && all(p.stage2.processSigma>=0));
assert(numel(p.stage2.sensorSigma)==2 && all(p.stage2.sensorSigma>=0));
assert(numel(p.stage2.tauLPF)==2 && all(p.stage2.tauLPF>0));
assert(p.stage2.seed>=0 && p.stage2.seed==floor(p.stage2.seed));
end

function folder=create_noise_folder(base,prefix)
if ~exist(base,'dir'),mkdir(base);end
name=[prefix '_' datestr(now,'yyyymmdd_HHMMSS')];
folder=fullfile(base,name);
i=1;
while exist(folder,'dir')
    i=i+1;folder=fullfile(base,sprintf('%s_%02d',name,i));
end
[ok,msg]=mkdir(folder);
if ~ok,error('Cannot make result folder: %s',msg);end
end
