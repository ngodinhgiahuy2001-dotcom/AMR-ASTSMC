% MAIN - Run the archived deterministic comparison for all three physical conditions.
% Uses configuration from config_experiment.m; see README.md for workflows.
addpath(fileparts(mfilename('fullpath')));
setup_project();
cfg = config_experiment();
cfg.task = 'baseline';
runInfo = run_experiment(cfg);
