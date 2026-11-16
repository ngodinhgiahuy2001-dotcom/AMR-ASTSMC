function root = setup_project()
% SETUP_PROJECT All MATLAB files share this single folder.
% No recursive path setup is required.
root=fileparts(mfilename('fullpath'));
addpath(root,'-begin');
end
