function [allResults,Metrics,outputFolder] = run_deterministic(p,outputBase)
% RUN_DETERMINISTIC Original 3 cases x 3 controllers; unchanged RK4 equations.
if nargin<1 || isempty(p), p=config_parameters(); end
if nargin<2 || isempty(outputBase)
    outputBase=fileparts(mfilename('fullpath'));
end


%% =========================================================
%  Output folder
% ==========================================================

outputFolder = create_output_folder(outputBase,'Results_3Cases');

fprintf('\n');
fprintf('=============================================\n');
fprintf('OUTPUT FOLDER\n');
fprintf('=============================================\n');
fprintf('%s\n',outputFolder);


%% =========================================================
%  Controllers
% ==========================================================

controllers = { ...
    'SMC', ...
    'STSMC', ...
    'ASTSMC'};


%% =========================================================
%  Storage
% ==========================================================

allResults = cell(3,3);

metricRows = cell(0,14);


%% =========================================================
%  Simulation information
% ==========================================================

fprintf('\n');
fprintf('=============================================\n');
fprintf('SMC / STSMC / ASTSMC COMPARISON\n');
fprintf('=============================================\n');

fprintf('Solver       : Fixed-step RK4\n');

fprintf( ...
    'dt           : %.4f s\n', ...
    p.sim.dt);

fprintf( ...
    'Sample rate  : %.2f Hz\n', ...
    1/p.sim.dt);

fprintf( ...
    'Simulation   : %.1f s\n', ...
    p.sim.tf-p.sim.t0);

fprintf('=============================================\n');


totalTimer = tic;


%% =========================================================
%  Run Case 1 -> Case 3
% ==========================================================

for caseNo = 1:3

    fprintf('\n');
    fprintf('=============================================\n');
    fprintf('CASE %d\n',caseNo);
    fprintf('=============================================\n');


    for ic = 1:numel(controllers)

        controller = controllers{ic};


        fprintf( ...
            'Running %-7s ... ', ...
            controller);


        runTimer = tic;


        %% Simulation

        result = simulate_deterministic( ...
            p, ...
            controller, ...
            caseNo);


        runTime = toc(runTimer);


        fprintf( ...
            '%.3f s\n', ...
            runTime);


        %% Store

        allResults{caseNo,ic} = result;


        %% Save individual controller result

        caseFolder = fullfile( ...
            outputFolder, ...
            sprintf('Case%d',caseNo));


        if ~exist(caseFolder,'dir')
            mkdir(caseFolder);
        end


        resultFile = fullfile( ...
            caseFolder, ...
            sprintf( ...
                'Case%d_%s.mat', ...
                caseNo, ...
                controller));


        save( ...
            resultFile, ...
            'result');


        %% Metrics

        m = result.metrics;


        metricRows(end+1,:) = { ...
            caseNo, ...
            controller, ...
            m.RMSE_pos, ...
            m.Max_pos, ...
            m.RMSE_theta, ...
            m.IAE, ...
            m.ISE, ...
            m.ITAE, ...
            m.RMS_uv, ...
            m.RMS_uw, ...
            m.Max_alpha_v, ...
            m.Max_alpha_w, ...
            m.Mean_alpha_v, ...
            m.Mean_alpha_w};

    end


    %% =====================================================
    %  Export all figures for current case
    % ======================================================

    plot_deterministic_comparison( ...
        allResults(caseNo,:), ...
        p, ...
        caseNo, ...
        outputFolder);

end


%% =========================================================
%  Metrics table
% ==========================================================

Metrics = cell2table( ...
    metricRows, ...
    'VariableNames',{ ...
        'Case', ...
        'Controller', ...
        'RMSE_pos', ...
        'Max_pos', ...
        'RMSE_theta', ...
        'IAE', ...
        'ISE', ...
        'ITAE', ...
        'RMS_uv', ...
        'RMS_uw', ...
        'Max_alpha_v', ...
        'Max_alpha_w', ...
        'Mean_alpha_v', ...
        'Mean_alpha_w'});


%% Display
fprintf('\n');
fprintf('=============================================\n');
fprintf('FINAL METRICS\n');
fprintf('=============================================\n');

disp(Metrics);


%% =========================================================
%  Save metrics CSV
% ==========================================================

metricsCSV = fullfile( ...
    outputFolder, ...
    'Metrics_3Cases.csv');


writetable( ...
    Metrics, ...
    metricsCSV);


%% =========================================================
%  Save complete results
% ==========================================================

matFile = fullfile( ...
    outputFolder, ...
    'Results_3Cases_Factory.mat');


save( ...
    matFile, ...
    'allResults', ...
    'Metrics', ...
    'p');


%% =========================================================
%  Save config_parameters separately
% ==========================================================

parameterFile = fullfile( ...
    outputFolder, ...
    'Simulation_Parameters.mat');


save( ...
    parameterFile, ...
    'p');

%% =========================================================
%  Manuscript-only reproducible figures (plotting, no reruns)
%  Fig. 5: adaptation law from config_parameters.m
%  Figs. 14-18: the already-computed 9 controller results
%  Fig. 7 was already exported in plot_deterministic_comparison (Case 1).
%  Fig. 10 is the existing Case-2 zoomed-inset export.
%  Fig. 13 is the existing Case-3 payload/gains export.
% ==========================================================
plot_gain_adaptation_law(p,outputFolder);
export_deterministic_figures(allResults,outputFolder);


%% =========================================================
%  Total runtime
% ==========================================================

totalElapsed = toc(totalTimer);


fprintf('\n');
fprintf('=============================================\n');
fprintf('SIMULATION COMPLETE\n');
fprintf('=============================================\n');

fprintf( ...
    'Runtime       : %.3f s\n', ...
    totalElapsed);

fprintf( ...
    'Output folder : %s\n', ...
    outputFolder);

fprintf('=============================================\n');
end
