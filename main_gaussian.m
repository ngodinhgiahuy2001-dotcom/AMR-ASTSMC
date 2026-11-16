% MAIN_GAUSSIAN - Run sampled Gaussian/LPF experiments for one fixed seed.
% Configuration: config_experiment.m. Run this script from the project folder.
addpath(fileparts(mfilename('fullpath')));
setup_project();
cfg = config_experiment();
cfg.task = 'noise';
runInfo = run_experiment(cfg);
