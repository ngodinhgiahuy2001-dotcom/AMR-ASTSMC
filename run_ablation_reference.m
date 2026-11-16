function [Ablation,folder] = run_ablation_reference(p)
% RUN_ABLATION_REFERENCE N0-N4, paired random innovations (no saturation).
% N0: deterministic external only, no sensor/process Gaussian, NO LPF
% N1: N0 + process Gaussian; NO LPF
% N2: N1 + sensor Gaussian; NO LPF
% N3: N2 + common LPF
% N4: N3 + original variable payload (Case 3)
% This optional experiment isolates noise contributions; it does not
% replace the three main cases or the original manuscript results.
if nargin<1 || isempty(p),p=config_noise();end
p.stage2.exportPlots=false;p.stage2.saveMAT=false;
t=(p.sim.t0:p.stage2.Ts:p.sim.tf)';
noise=generate_gaussian_noise(p,numel(t));
folder=fullfile(p.stage2.outputBase,['Ablation_Stage2_' datestr(now,'yyyymmdd_HHMMSS')]);
if exist(folder,'dir'),error('Output folder already exists, rerun later.');end
mkdir(folder);
controllers={'SMC','STSMC','ASTSMC'};
rows=cell(15,10); rr=0;
for nm=1:5
    pc=p;
    pc.stage2.useExternalDisturbance=true;
    pc.stage2.usePayload=(nm==5);
    pc.stage2.useProcessNoise=(nm>=2);
    pc.stage2.useSensorNoise=(nm>=3);
    pc.stage2.useLPF=(nm>=4);
    caseNo=2+(nm==5);
    for ci=1:3
        r=simulate_gaussian(pc,controllers{ci},caseNo,noise);
        rr=rr+1;m=r.metrics;
        rows(rr,:)={sprintf('N%d',nm-1),caseNo,controllers{ci},p.stage2.seed,...
            pc.stage2.useProcessNoise,pc.stage2.useSensorNoise,pc.stage2.useLPF,...
            m.RMSE_pos,m.IAE,m.ITAE};
    end
end
Ablation=cell2table(rows,'VariableNames',{'Mode','Case','Controller','Seed',...
 'ProcessNoise','SensorNoise','LPF','RMSE_pos_m','IAE_m_s','ITAE_m_s2'});
writetable(Ablation,fullfile(folder,'Ablation_N0_to_N4.csv'));
disp(Ablation);
end
