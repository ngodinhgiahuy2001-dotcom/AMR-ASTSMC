% MAIN_SENSITIVITY - Run full 17x17 parameter sweeps for three deterministic conditions.
% Select this file and press Run, or type main_sensitivity in Command Window.
% 3 x (17 x 17) = 867 complete 75-s RK4 runs.
% Keep the controller gains and all physical simulation settings unchanged.

addpath(fileparts(mfilename('fullpath')));
setup_project();
cfg = config_experiment();
cfg.task = 'sensitivity';
cfg.mode = 'full';       % 17 x 17. Change to 'quick' only for a 5 x 5 test.
cfg.showSensitivityFigure = false;  % FIG/PNG/PDF still exported.

for caseNo = 1:3
    cfg.sensitivityCase = caseNo;
    fprintf('\n======= Sensitivity %d of 3 =======\n',caseNo);
    runInfo = run_experiment(cfg);
    fprintf('Condition %d saved to: %s\n',caseNo,runInfo.outputFolder);
end
fprintf('\nAll three sensitivity conditions finished.\n');
