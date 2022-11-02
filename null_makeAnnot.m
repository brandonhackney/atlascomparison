function null_makeAnnot(subjNames, atlasNames)
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

hemstr = {'lh','rh'};
setenv('FREESURFER_HOME','/usr/local/freesurfer');
p = specifyPaths;
atlasPath = fullfile(p.baseDataPath, 'sub-04', 'fs');

for a = 1:length(atlasNames)
    atlas = atlasNames{a};
    for s = 1:length(subjNames)
        subj = subjNames{s};
        subjpath = fullfile(p.baseDataPath, 'deriv', subj, [subj '-Freesurfer']);
        outpath = fullfile(subjpath, subj, 'label');
        for h = 1:2
            hem = hemstr{h};
            % Options
            opts = ['-sdir ' subjpath ' -t /data1/fssubdir/null174_mycolortable.txt'];
            
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