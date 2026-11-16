function check_dependencies()
% CHECK_DEPENDENCIES Check routing and deterministic solver consistency.
root=fileparts(mfilename('fullpath'));
expected={'config_parameters','config_noise', ...
 'controller_SMC','controller_STSMC','controller_ASTSMC','model_robot_dynamics', ...
 'model_reference_trajectory','simulate_deterministic','compute_metrics','simulate_gaussian', ...
 'run_deterministic','run_gaussian_statistics','run_sensitivity'};
for k=1:numel(expected)
    actual=which(expected{k});
    wanted=fullfile(root,[expected{k} '.m']);
    assert(strcmpi(actual,wanted), ...
        'Wrong source for %s. Change Current Folder to this project, then run again.',expected{k});
end
p=config_parameters();
assert(p.sim.dt==0.01 && p.sim.tf==75);
pn=config_noise();
assert(pn.stage2.seed==20261113 && pn.stage2.rkSubsteps==2);
assert(all(abs(pn.stage2.tauLPF-0.005)<1e-12));
% Exercise a short segment inside the high-payload interval (not a paper result).
p.sim.t0=27; p.sim.tf=27.2;
t=(p.sim.t0:p.sim.dt:p.sim.tf)';
refXY=zeros(numel(t),2);
for k=1:numel(t)
    r=model_reference_trajectory(t(k),p); refXY(k,:)=r(1:2).';
end
for ca=1:3
    r=simulate_deterministic(p,'ASTSMC',ca);
    scalarITAE=simulate_sensitivity_itae(p,ca,t,refXY);
    assert(abs(scalarITAE-r.metrics.ITAE)<1e-10, ...
        'Sensitivity and baseline integration disagree for Case %d.',ca);
end
fprintf('PASS: source paths and baseline/sensitivity RK4 consistency.\n');
end
