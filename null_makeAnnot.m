function null_makeAnnot(subjNames, atlasNames, varargin)
% null_makeAnnot(subjNames, atlasNames)
% Calls mris_ca_label to generate a .annot file for the given subj & atlas
% Can take an array of subjects and atlases, if you want to loop
% Atlas name is JUST the name of an atlas, e.g. schaefer400
% Used implicitly to search for a GCS file, e.g. lh.schaefer400.gcs

% Check whether inputs are cells, convert if not. Makes looping simpler.
stype = whos('subjNames');
atype = whos('atlasNames');
if strcmp(stype.class,'char') % if it's just one subject
    subjNames = {subjNames};
end
if strcmp(atype.class,'char')
    atlasNames = {atlasNames};
end

% Do both hemispheres? Or just one?
if nargin > 2
    assert(ischar(varargin{1}),'Hemisphere label (in3) must be type char')
    hemstr = varargin(1);
else
    hemstr = {'lh','rh'};
end

setenv('FREESURFER_HOME','/usr/local/freesurfer');
p = specifyPaths;
atlasPath = fullfile(p.baseDataPath, 'sub-04', 'fs');

for a = 1:length(atlasNames)
    atlas = atlasNames{a};
    for s = 1:length(subjNames)
        subj = subjNames{s};
        subjpath = fullfile(p.baseDataPath, 'deriv', subj, [subj '-Freesurfer']);
        outpath = fullfile(subjpath, subj, 'label');
        for h = 1:length(hemstr)
            hem = hemstr{h};
            % Options
            opts = ['-sdir ' subjpath ];
            if strcmp(atlas(1:5),'null_')
                % hardcode this colortable in
                opts = [opts ' -t /data1/fssubdir/null174_mycolortable.txt'];
                % Anything else should have one baked in or linked to
            end
            % Arguments
            canonsrf = 'sphere.reg';
            atlasFile = [atlasPath filesep hem '.' atlas '.gcs'];
            fname = [hem, '.', atlas, '.annot'];
            fout = [outpath filesep fname]; % path and name of annot file
            args = strjoin({subj, hem, canonsrf, atlasFile, fout});
            cmdstr = ['mris_ca_label', ' ', opts, ' ', args];
            
            % Execute command
            runstatus = system(cmdstr);
            if runstatus % 0 means no problem
                error('Error calling mris_ca_label\nReview: %s\n',cmdstr);
            end
        end % for hem
    end % for subj
end % for atlas

end