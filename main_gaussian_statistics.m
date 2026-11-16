% MAIN_GAUSSIAN_STATISTICS - Run paired Gaussian/LPF statistics (30 seeds by default).
% Configuration: config_experiment.m. Run this script from the project folder.
addpath(fileparts(mfilename('fullpath')));
setup_project();
cfg = config_experiment();
cfg.task = 'gaussian30';
runInfo = run_experiment(cfg);
