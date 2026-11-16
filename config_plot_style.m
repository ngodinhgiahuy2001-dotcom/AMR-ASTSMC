function S = config_plot_style()
%CONFIG_PLOT_STYLE Common plotting style for Chapter 6 figures.
%   Figure size is fixed at 15 x 9 cm. Text is Times New Roman, 13 pt.

S.FontName = 'Times New Roman';
S.FontSize = 13;
S.LineWidth = 2;
S.RefLineWidth = 2;
S.GridAlpha = 0.18;
S.MinorGridAlpha = 0.08;
S.FigureWidthCm = 15;
S.FigureHeightCm = 9;
S.PNG_DPI = 600;

% Fixed controller styles. Line styles are intentionally different so the
% curves remain distinguishable in grayscale printing.
S.SMC.Color = [0.0000 0.4470 0.7410];
S.SMC.LineStyle = '-';
S.STSMC.Color = [0.8500 0.3250 0.0980];
S.STSMC.LineStyle = '--';
S.ASTSMC.Color = [0.9290 0.6940 0.1250];
S.ASTSMC.LineStyle = '-.';
S.Reference.Color = [0 0 0];
S.Reference.LineStyle = ':';

% Use TeX rather than LaTeX so the requested font remains Times New Roman.
S.Interpreter = 'tex';
end
