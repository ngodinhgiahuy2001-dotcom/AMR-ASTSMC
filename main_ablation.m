% MAIN_ABLATION - Run the N0-N4 sampled noise/filter/payload ablation.
% Configuration: config_experiment.m. Run this script from the project folder.
addpath(fileparts(mfilename('fullpath')));
setup_project();
cfg = config_experiment();
cfg.task = 'ablation';
runInfo = run_experiment(cfg);
