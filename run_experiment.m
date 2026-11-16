function info = run_experiment(cfg)
% RUN_EXPERIMENT Dispatch the selected task and record its output folder.
%   run_experiment                             % use config_experiment.m
%   cfg=config_experiment(); cfg.task='gaussian30'; run_experiment(cfg);
root=setup_project();
if nargin<1 || isempty(cfg), cfg=config_experiment(); end
cfg.task=validatestring(cfg.task, ...
    {'baseline','noise','gaussian30','sensitivity','ablation','selftest'});
cfg.mode=validatestring(cfg.mode,{'quick','full'});
validateattributes(cfg.nSeeds,{'numeric'},{'scalar','integer','>=',2,'finite'});
validateattributes(cfg.sensitivityCase,{'numeric'},{'scalar','integer','>=',1,'<=',3});
validateattributes(cfg.showSensitivityFigure,{'logical'},{'scalar'});
assert(ischar(cfg.outputBase) || (isstring(cfg.outputBase) && isscalar(cfg.outputBase)), ...
    'outputBase must be a folder path or empty text.');
outputBase=char(cfg.outputBase);
if isempty(outputBase), outputBase=root; end
if ~exist(outputBase,'dir')
    [ok,msg]=mkdir(outputBase); assert(ok,'Cannot create output base: %s',msg);
end
[ok,attrs]=fileattrib(outputBase); assert(ok,'Cannot resolve output folder.');
outputBase=attrs.Name;
info=struct('task',cfg.task,'mode',cfg.mode,'outputFolder','', ...
    'settings',cfg,'matlabVersion',version,'completedAt','');
fprintf('\nAMR | task=%s | mode=%s\n',cfg.task,cfg.mode);
if ismember(cfg.task,{'baseline','noise','selftest'}) && strcmp(cfg.mode,'quick')
    fprintf('This task uses its full settings; quick applies only to ablation, gaussian30 and sensitivity.\n');
end
switch cfg.task
    case 'baseline'
        p=config_parameters();
        [~,~,folder]=run_deterministic(p,outputBase);
    case 'noise'
        p=config_noise(); p.stage2.outputBase=outputBase;
        [~,~,folder]=run_gaussian(p);
    case 'gaussian30'
        p=config_noise(); p.stage2.outputBase=outputBase;
        [~,~,~,folder]=run_gaussian_statistics(cfg.mode,cfg.nSeeds,p);
    case 'sensitivity'
        p=config_parameters();
        folder=run_sensitivity(cfg.mode,cfg.sensitivityCase, ...
            cfg.showSensitivityFigure,p,outputBase);
    case 'ablation'
        p=config_noise(); p.stage2.outputBase=outputBase;
        [~,~,~,folder]=run_ablation(cfg.mode,p.stage2.seed,p);
    case 'selftest'
        check_dependencies();
        check_noise_samples();
        Check=check_regression_metrics();
        folder=create_output_folder(outputBase,'Selftest');
        writetable(Check,fullfile(folder,'Regression_Check.csv'));
end
info.outputFolder=folder;
info.completedAt=datestr(now,31);
save(fullfile(folder,'Run_Settings.mat'),'info');
fprintf('\nCompleted. Results and plots:\n%s\n',folder);
end
