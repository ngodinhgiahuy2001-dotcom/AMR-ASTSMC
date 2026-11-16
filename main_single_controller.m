% MAIN_SINGLE_CONTROLLER - Run one deterministic controller and condition.
% Select singleController and singleCase in config_experiment.m.
addpath(fileparts(mfilename('fullpath')));
setup_project();
cfg = config_experiment();
[result, outputFile] = run_single_controller(config_parameters(), ...
    cfg.singleController, cfg.singleCase, cfg.outputBase);
