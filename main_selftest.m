% MAIN_SELFTEST - Check dependencies and archived regression metrics.
% Configuration: config_experiment.m. Run this script from the project folder.
addpath(fileparts(mfilename('fullpath')));
setup_project();
cfg = config_experiment();
cfg.task = 'selftest';
runInfo = run_experiment(cfg);
