function replot_zoom_figures(resultFolder)
% REPLOT_ZOOM_FIGURES
% Run this script after setting resultFolder to the confirmed archive.
% Uses ONLY saved data and the original plot style/export functions.
% If results are in a ZIP, extract the ZIP first.
%
% Example: an extracted deterministic-results directory.

if nargin<1 || isempty(resultFolder)
    resultFolder=uigetdir(pwd,'Select folder containing Case2 and Case3');
    if isequal(resultFolder,0), return; end
end
if ~isfolder(resultFolder)
    error(['Set resultFolder to the extracted deterministic results ' ...
        'directory containing Case2 and Case3 subdirectories.']);
end
S = config_plot_style();
controllers = {'SMC','STSMC','ASTSMC'};
for caseNo = [2 3]
    R = struct();
    caseFolder = fullfile(resultFolder,sprintf('Case%d',caseNo));
    for k = 1:numel(controllers)
        name = controllers{k};
        inputFile = fullfile(caseFolder,sprintf('Case%d_%s.mat',caseNo,name));
        d = load(inputFile,'result');
        R.(name) = d.result;
    end
    export_zoom_figures(R,caseNo,caseFolder,S);
end
disp('Done: four extra figures with zoomed insets exported as FIG / PNG / PDF.');

end
