function folder = create_output_folder(base,prefix)
% CREATE_OUTPUT_FOLDER Preserve timestamp naming, avoid accidental overwrite.
if ~exist(base,'dir')
    [ok,msg]=mkdir(base); assert(ok,'Cannot create output base: %s',msg);
end
stem=[prefix '_' datestr(now,'yyyymmdd_HHMMSS')];
folder=fullfile(base,stem); k=1;
while exist(folder,'dir')
    k=k+1; folder=fullfile(base,sprintf('%s_%02d',stem,k));
end
[ok,msg]=mkdir(folder); assert(ok,'Cannot create output folder: %s',msg);
end
