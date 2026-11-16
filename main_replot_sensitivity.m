function outputFolder = main_replot_sensitivity(resultsRoot)
% MAIN_REPLOT_SENSITIVITY
% Re-export Fig. 18 from SAVED 17x17 sensitivity grids, without rerunning
% 3 x 289 simulations. Finds ITAE_Sensitivity.mat recursively, including
% nested Results/Results/... paths (no reliance on '**' wildcard).
%
% Usage:
%   main_replot_sensitivity
%   main_replot_sensitivity('results_archive')
%
% For every valid CASE_NO=1,2,3, uses the newest complete 17x17 grid.
% All figures use the SAME Z limits and colors [1.40,2.70] and NO titles.
% Original MAT/CSV/FIG/PNG/PDF files are never overwritten.

outputFolder = '';
sourceDir = fileparts(mfilename('fullpath'));
addpath(sourceDir);     % Only the export function is needed for replot.

if nargin < 1 || isempty(resultsRoot)
    resultsRoot = uigetdir(pwd, ...
        'Select extracted Results (or its parent folder)');
    if isequal(resultsRoot,0)
        disp('Cancelled.');
        return;
    end
end
resultsRoot = char(resultsRoot);
assert(isfolder(resultsRoot), ...
    'Selected path is not a folder: %s. Extract Results.zip first.',resultsRoot);

% Recursively visit directories explicitly. Some MATLAB installations do
% not find the expected files using dir(fullfile(root,'**',...)).
candidates = collect_sensitivity_mat_files(resultsRoot);
if isempty(candidates)
    error(['No ITAE_Sensitivity.mat found under: %s\n', ...
           'Extract Results(1).zip, then choose its Results folder ', ...
           '(or a parent containing it).'],resultsRoot);
end
fprintf('Found %d sensitivity MAT candidate(s).\n',numel(candidates));

files = cell(1,3);
fileDates = -inf(1,3);
for k = 1:numel(candidates)
    filePath = candidates{k};
    try
        % Read only the fields needed to accept a complete result.
        S = load(filePath,'CASE_NO','ITAE','UP','DOWN','Success');
    catch ME
        warning('Cannot load %s: %s',filePath,ME.message);
        continue;
    end
    required = {'CASE_NO','ITAE','UP','DOWN','Success'};
    if ~all(isfield(S,required))
        fprintf('Skipped incomplete MAT (missing fields): %s\n',filePath);
        continue;
    end
    c = double(S.CASE_NO);
    if ~isscalar(c) || ~ismember(c,[1 2 3])
        fprintf('Skipped MAT (CASE_NO not 1/2/3): %s\n',filePath);
        continue;
    end
    if ~isequal(size(S.ITAE),[17,17]) || ...
            ~isequal(size(S.UP),[17,17]) || ...
            ~isequal(size(S.DOWN),[17,17]) || ...
            ~isequal(size(S.Success),[17,17]) || ...
            ~all(S.Success(:)) || ~all(isfinite(S.ITAE(:)))
        fprintf('Skipped Case %d: incomplete/non-full grid: %s\n',c,filePath);
        continue;
    end
    metadata = dir(filePath);
    if isempty(metadata), continue; end
    if isempty(files{c}) || metadata(1).datenum > fileDates(c)
        files{c} = filePath;
        fileDates(c) = metadata(1).datenum;
    end
end

for c = 1:3
    if isempty(files{c})
        fprintf(2,'MISSING: Case %d (valid 17x17 MAT grid).\n',c);
    else
        fprintf('Case %d source: %s\n',c,files{c});
    end
end
missingCases = find(cellfun(@isempty,files));
if ~isempty(missingCases)
    error(['Missing valid 17x17 sensitivity MAT for Case(s): %s.\n', ...
           'Choose an extracted parent folder containing all three ', ...
           'Sensitivity_ITAE_Case1/2/3... directories.'],mat2str(missingCases));
end

% Validate every selected file BEFORE writing any output to disk.
Data = cell(1,3);
for c = 1:3
    S = load(files{c});
    assert(isfield(S,'p0') && isfield(S.p0,'AST') && ...
           isfield(S.p0.AST,'gammaUp') && isfield(S.p0.AST,'gammaDown'), ...
        'Missing nominal ASTSMC parameter data: %s',files{c});
    assert(isequal(size(S.ITAE),size(S.UP),size(S.DOWN)), ...
        'ITAE/UP/DOWN grid mismatch in Case %d.',c);
    assert(all(S.Success(:)) && all(isfinite(S.ITAE(:))), ...
        'Case %d contains failed or non-finite ITAE values.',c);
    assert(min(S.ITAE(:)) >= 1.40-1e-10 && ...
           max(S.ITAE(:)) <= 2.70+1e-10, ...
        'Case %d ITAE lies outside [1.40,2.70]; do not clip valid data.',c);
    Data{c} = S;
end

outputFolder = fullfile(resultsRoot, ...
    ['Sensitivity_Fig18_CommonScale_' datestr(now,'yyyymmdd_HHMMSS')]);
mkdir(outputFolder);
caseNumber = (1:3)';
count = zeros(3,1);
minITAE = zeros(3,1);
maxITAE = zeros(3,1);
baselineITAE = nan(3,1);
sourceMat = cell(3,1);
for c = 1:3
    S = Data{c};
    folder = fullfile(outputFolder,sprintf('Case%d',c));
    mkdir(folder);
    export_sensitivity_common_scale(S.ITAE,S.UP,S.DOWN,c,S.p0,folder,false);
    count(c) = numel(S.ITAE);
    minITAE(c) = min(S.ITAE(:));
    maxITAE(c) = max(S.ITAE(:));
    iu = find(abs(S.UP(1,:) - S.p0.AST.gammaUp(1)) < 1e-10,1);
    id = find(abs(S.DOWN(:,1) - S.p0.AST.gammaDown(1)) < 1e-10,1);
    if ~isempty(iu) && ~isempty(id)
        baselineITAE(c) = S.ITAE(id,iu);
    end
    sourceMat{c} = files{c};
end

report = table(caseNumber,count,minITAE,maxITAE,baselineITAE,sourceMat, ...
    'VariableNames',{'Case','NGridPoints','MinITAE','MaxITAE', ...
                     'NominalGainITAE','OriginalMAT'});
writetable(report,fullfile(outputFolder,'Fig18_CommonScale_Validation.csv'));
fprintf('\nSUCCESS: 3 x 289 saved sensitivity points plotted; no simulation rerun.\n');
fprintf('Output: %s\n',outputFolder);
end

function files = collect_sensitivity_mat_files(rootFolder)
% Recursive enumeration without genpath and without the ** wildcard.
% Skip previous exports to avoid selecting generated copies in later runs.
files = {};
entries = dir(rootFolder);
for i = 1:numel(entries)
    name = entries(i).name;
    if strcmp(name,'.') || strcmp(name,'..'), continue; end
    fullPath = fullfile(rootFolder,name);
    if entries(i).isdir
        if strncmpi(name,'Sensitivity_Fig18_CommonScale_',30)
            continue;
        end
        nested = collect_sensitivity_mat_files(fullPath);
        files = [files,nested]; %#ok<AGROW>
    elseif strcmpi(name,'ITAE_Sensitivity.mat')
        files{end+1} = fullPath; %#ok<AGROW>
    end
end
end
