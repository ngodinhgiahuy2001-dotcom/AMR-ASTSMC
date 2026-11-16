function p = config_noise()
% CONFIG_NOISE Extend ORIGINAL config_parameters.m without changing it.
% All values below are INITIAL STUDY ASSUMPTIONS; not measured sensor specs.
p = config_parameters();

% Stage 1 document: sampled noise, sampled feedback, common 1st-order LPF.
p.stage2.Ts = p.sim.dt;              % controller sample period [s], 0.01
p.stage2.rkSubsteps = 2;             % RK4 plant substeps per controller tick
p.stage2.processSigma = [0.02;0.02];% [m/s^2;rad/s^2] sample-held Gaussian accel
p.stage2.sensorSigma  = [1e-4;1e-4];% [m/s;rad/s] Gaussian velocity measurement
% Stage-2.1 diagnostics (2026-11-13): 50 ms LPF caused persistent lag,
% ASTSMC gains pinned at 8 and distorted full-mission ITAE. A paired 0-30s
% sweep at Ts=0.01s identified tau=5ms as an initial conservative option:
% Case-2 ITAE ASTSMC 1.454 at 5ms versus 3.344 at 50ms (30-s horizon).
% IMPORTANT: 5ms yields only modest suppression of white sensor noise;
% full 75-s and multi-seed validation required before publication.
p.stage2.tauLPF = [0.005;0.005];   % [s] provisional LPF for BOTH v and w
p.stage2.seed = 20261113;           % repeatable paired realizations

% Same sensor/filter model for all SMC/STSMC/ASTSMC.
p.stage2.useLPF = true;
p.stage2.useProcessNoise = true;     % only Cases 2 and 3
p.stage2.useSensorNoise = true;      % only Cases 2 and 3
p.stage2.useExternalDisturbance = true; % original model_external_disturbance.m; Cases 2/3
p.stage2.usePayload = true;          % original payload formula; Case 3

% No actuator saturation, gain freezing, or anti-windup in Stage 2.
p.stage2.exportPlots = true;
p.stage2.exportOriginalStyle = false; % set true for extensive original figures
p.stage2.saveMAT = true;
p.stage2.printProgress = true;
p.stage2.outputBase = fileparts(mfilename('fullpath'));
end
