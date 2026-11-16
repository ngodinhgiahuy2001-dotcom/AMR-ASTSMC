function check_noise_samples()
% CHECK_NOISE_SAMPLES Basic invariants / smoke test in MATLAB.
p=config_noise();
p.sim.tf=1.5; % Very short; before any deterministic model_external_disturbance/payload.
p.stage2.exportPlots=false; p.stage2.saveMAT=false;
p.stage2.printProgress=false;
t=(p.sim.t0:p.stage2.Ts:p.sim.tf)';
n=generate_gaussian_noise(p,numel(t));
assert(isequal(size(n.sensor),[2 numel(t)]));
assert(isequal(size(n.process),[2 numel(t)-1]));
n2=generate_gaussian_noise(p,numel(t));
assert(isequal(n.process,n2.process) && isequal(n.sensor,n2.sensor),...
 'Fixed seed did not reproduce noise.');
for ic=1:3
    names={'SMC','STSMC','ASTSMC'};name=names{ic};
    a=simulate_gaussian(p,name,1,n);
    b=simulate_gaussian(p,name,2,n);
    c=simulate_gaussian(p,name,3,n);
    assert(max(abs(a.sensorNoise(:)))==0 && all(a.processNoise(1:end-1,:)==0,'all'));
    assert(max(abs((b.etaMeasured-b.etaTrue)-b.sensorNoise),[],'all')<1e-12);
    assert(isequaln(b.sensorNoise,c.sensorNoise));
    assert(isequaln(b.processNoise,c.processNoise));
    assert(max(abs(b.x-c.x),[],'all')<1e-10,...
     'Case 2/3 must coincide before payload and disturbance windows.');
    assert(all(isfinite(b.ep)) && all(isfinite(c.ep)));
    assert(isfinite(b.metrics.ITAE));
end
% Zero-lag/no-filter regression: filtered velocity == measured velocity.
p.stage2.useLPF=false;
a=simulate_gaussian(p,'ASTSMC',2,n);
assert(max(abs(a.etaFiltered-a.etaMeasured),[],'all')<1e-14);
fprintf('PASS: Stage 2 noise, filter, paired cases, original controllers.\n');
end
