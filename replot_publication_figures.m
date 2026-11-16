function replot_publication_figures(matFile)
%REPLOT_PUBLICATION_FIGURES Re-export figures without rerunning RK4.
% Usage:
%   replot_publication_figures('Results_3Cases_20261111_002258/Results_3Cases_Factory.mat')
% Without input, a file selection window will open.
%
% This uses existing .mat arrays. It does not change any simulated data.
if nargin<1 || isempty(matFile)
    [name,path]=uigetfile('*.mat','Select Results_3Cases_Factory.mat');
    if isequal(name,0), return; end
    matFile=fullfile(path,name);
end
file=load(matFile,'allResults','p');
assert(isfield(file,'allResults') && isfield(file,'p'), ...
    'MAT file must contain allResults and p.');
outputFolder=fileparts(matFile);
for caseNo=1:3
    plot_deterministic_comparison(file.allResults(caseNo,:),file.p,caseNo,outputFolder);
end
plot_gain_adaptation_law(file.p,outputFolder);
export_deterministic_figures(file.allResults,outputFolder);
fprintf('All publication figures exported to: %s\n',outputFolder);
end
