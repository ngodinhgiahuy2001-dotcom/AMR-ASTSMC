function outFolder = run_sensitivity(mode,CASE_NO,SHOW_FIGURE,p0,outputBase)
% RUN_SENSITIVITY
% ITAE sensitivity of ASTSMC to gammaUp and gammaDown (Case 3 by default).
% Uses the UNCHANGED original files: config_parameters, model_reference_trajectory, model_robot_dynamics,
% controller_ASTSMC, model_external_disturbance and model_payload_profile.
%
% After setup_project, run:
%     run_sensitivity
%
% QUICK_TEST=true  : 5 x 5 grid (25 simulations), Case 3
% QUICK_TEST=false : 17 x 17 grid (289 simulations), Case 3
%
% For each pair, both channels are set to the same adaptation rates:
% p.AST.gammaUp=[gammaUp;gammaUp]; gammaDown=[gammaDown;gammaDown].
% All other settings, including 75 s / RK4 dt=0.01 s, are unchanged.
% Outputs: ONE 3D ITAE figure (FIG, PNG 600 dpi, PDF vector), CSV and MAT.

% Defaults reproduce the original 17x17, Case-3, 75-second study.
if nargin<1 || isempty(mode), mode='full'; end
if nargin<2 || isempty(CASE_NO), CASE_NO=3; end
if nargin<3 || isempty(SHOW_FIGURE), SHOW_FIGURE=true; end
if nargin<4 || isempty(p0), p0=config_parameters(); end
if nargin<5 || isempty(outputBase)
    outputBase=fileparts(mfilename('fullpath'));
end
mode=validatestring(mode,{'quick','full'});
QUICK_TEST=strcmp(mode,'quick');

if QUICK_TEST
    nGrid = 5;
else
    nGrid = 17;
end

gammaUpValues   = linspace(2.0,10.0,nGrid);
gammaDownValues = linspace(0.03,0.27,nGrid);

%% 2) ORIGINAL MODEL AND REFERENCE PATH
% p0 is supplied by the caller or the original parameter defaults.
assert(ismember(CASE_NO,1:3),'CASE_NO must be 1, 2 or 3.');
assert(p0.sim.dt > 0 && p0.sim.tf > p0.sim.t0,'Invalid time range.');

t = (p0.sim.t0:p0.sim.dt:p0.sim.tf).';
refXY = zeros(numel(t),2);
for k = 1:numel(t)
    rr = model_reference_trajectory(t(k),p0);
    refXY(k,:) = rr(1:2).';
end

% Rows correspond to gammaDown; columns correspond to gammaUp.
[UP,DOWN] = meshgrid(gammaUpValues,gammaDownValues);
ITAE = nan(nGrid,nGrid);
Success = false(nGrid,nGrid);

outFolder = create_output_folder(outputBase,sprintf('Sensitivity_ITAE_Case%d',CASE_NO));

fprintf('\nASTSMC ITAE Sensitivity - Case %d | Grid %d x %d (%d runs)\n', ...
        CASE_NO,nGrid,nGrid,nGrid*nGrid);
fprintf('Reference: gammaUp = %.3f, gammaDown = %.3f\n\n', ...
        p0.AST.gammaUp(1),p0.AST.gammaDown(1));

%% 3) RUN ONE FULL RK4 SIMULATION PER PARAMETER PAIR
for iDown = 1:nGrid
    for iUp = 1:nGrid
        gammaUp = UP(iDown,iUp);
        gammaDown = DOWN(iDown,iUp);

        p = p0;
        p.AST.gammaUp   = [gammaUp;gammaUp];
        p.AST.gammaDown = [gammaDown;gammaDown];

        started = tic;
        try
            ITAE(iDown,iUp) = simulate_sensitivity_itae(p,CASE_NO,t,refXY);
            Success(iDown,iUp) = true;
        catch ME
            warning('gammaUp=%.4f, gammaDown=%.4f: %s', ...
                    gammaUp,gammaDown,ME.message);
        end

        fprintf('%3d/%3d | gammaUp=%6.3f gammaDown=%6.3f | ITAE=%10.6f | %.2f s\n', ...
                (iDown-1)*nGrid+iUp,nGrid*nGrid,gammaUp,gammaDown, ...
                ITAE(iDown,iUp),toc(started));
    end
end

%% 4) BASELINE CHECK: ORIGINAL ADAPTATION RATES (6, 0.15)
iu = find(abs(gammaUpValues - p0.AST.gammaUp(1)) < 1e-10,1);
id = find(abs(gammaDownValues - p0.AST.gammaDown(1)) < 1e-10,1);
if ~isempty(iu) && ~isempty(id)
    baselineITAE = ITAE(id,iu);
    fprintf('\nBASELINE (%.3f, %.3f): ITAE = %.9f m*s^2\n', ...
            gammaUpValues(iu),gammaDownValues(id),baselineITAE);
    if CASE_NO == 3 && isfinite(baselineITAE) && ...
            abs(baselineITAE - 2.471457) > 5e-4
        warning(['Baseline differs from the archived 2026-11-03 Case 3 ITAE ', ...
                 '(2.471457). Verify original source and settings.']);
    end
else
    warning('The selected grid does not contain the original parameter pair.');
end

%% 5) EXPORT EXACT GRID VALUES: CSV AND MAT
T = table(repmat(CASE_NO,numel(UP),1),UP(:),DOWN(:),ITAE(:),Success(:), ...
    'VariableNames',{'Case','GammaUp','GammaDown','ITAE_m_s2','Success'});
writetable(T,fullfile(outFolder,'ITAE_Sensitivity.csv'));
save(fullfile(outFolder,'ITAE_Sensitivity.mat'), ...
    'ITAE','UP','DOWN','gammaUpValues','gammaDownValues', ...
    'Success','CASE_NO','p0');

%% 6) EXPORT WITH COMMON Z / COLOR LIMITS AND NO TITLE
% All three conditions use ITAE limits 1.40--2.70 m*s^2. The maximum
% archived value is 2.6977843908, so this range never clips valid data.
% Plot styling only: no model, controller, or metric computation is changed.
export_sensitivity_common_scale(ITAE,UP,DOWN,CASE_NO,p0,outFolder,SHOW_FIGURE);

fprintf('\nDONE. Outputs saved in: %s\n',outFolder);
end
