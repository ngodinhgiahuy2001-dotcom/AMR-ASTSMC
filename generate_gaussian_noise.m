function noise = generate_gaussian_noise(p, N)
% GENERATE_GAUSSIAN_NOISE Draw independent noise realizations ONCE per trial.
% Indexed by controller sample, never redrawn at RK4 intermediate stages.
% Both Case 2 and Case 3, all controller types reuse this same struct.
assert(isfield(p,'stage2'),'Call stage2_parameters() first.');
assert(N>=2 && N == floor(N),'N must be an integer >=2.');
assert(all(p.stage2.processSigma(:)>=0) && all(p.stage2.sensorSigma(:)>=0));
previousRng = rng; %#ok<RNGR>
restoreRng = onCleanup(@() rng(previousRng)); %#ok<NASGU>
rng(p.stage2.seed,'twister');
noise.process = bsxfun(@times, p.stage2.processSigma(:), randn(2,N-1));
noise.sensor  = bsxfun(@times, p.stage2.sensorSigma(:), randn(2,N));
noise.seed = p.stage2.seed;
noise.sampleTime = p.stage2.Ts;
end
