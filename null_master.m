function null_master(createNulls, applyToSubs, doClassSetup, RunClass)

% Runs the master script for building the null atlas model classifications.
% Executes in three main sections:
%   1) Creating the template null models
%   2) Applying to individual subjects (and extracting timeseries, as needed)
%   3) Organizing data into classifier-ready files
%   4) Running classification
%
% Takes as input four flags to determine whether to run each section as noted above 
%   1 = run section
%   0 = skip


% Define global vars
p = specifyPaths();
hemstr = {'lh','rh'};

%set up subject list
% subList = [1 2 3 4 5 6 7 8 10 11]; % and add the two last ones
subList = [1 2 3 4 5 6 7 8 10 11 14 17];
% subList = [14 17];

NumSubs = length(subList);
 for s = 1:length(subList)
     subCell{s} = ['STS' num2str(subList(s))];
 end

numNulls = 1000;
% Specify the names of the null atlases
atlasList = cell(1,numNulls);
for a = 1:numNulls
    atlasList{a} = ['null_',num2str(a,'%04.f')];
end

% Call this python script to build the null atlases, if specified by the user. 
% It iterates 1000 times on its own
% cd(p.nullDir);
if createNulls == 1
    
    % create the null models
    !conda init bash
    !conda activate atlaspy
    pyrunfile('/data/home/brandon/Python/Scripts/randFragmenter.py');
    
    % Create the gcs files that map null models to fsaverage
    null_makeGCS(atlasList) %no output variables needed; loops on its own
    
    % Create template POI files for each null model
    % This gives us the XYZ coordinates of each vertex
    % Sort of redundant since verts should have the same coords across maps
    % But required by null_parcelNames
    subj = 'sub-04';
    for hemi = 1:2
        for null = 1:numNulls
            nullfNameNoHem = ['null_', num2str(null,'%04.f'),'.annot'];

            Cfg.SUBJECTS_DIR = fullfile(p.baseDataPath, subj,'fs');
            Cfg.projectDir = Cfg.SUBJECTS_DIR;
            Cfg.atlas = nullfNameNoHem;
    %         Cfg.hemis = hemstr(hemi); % just one but keep it as a cell
            % make TEMPLATE poi files - NOT looping subject yet!!
            null_makePOI(subj, Cfg); % if no output, saves to disk
        end % for null
    end % for hemi
    clear subj Cfg nullfNameNoHem
end
            

% apply the template annotations to individual subjects, extract
% timeseries and caculate betas (if needed), compute parcel metrics
if applyToSubs == 1
    % Limit the number of cores, so that others can work too
    % This script is heavier on RAM than CPU, so a handful of cores is fine
    dfltThreads = maxNumCompThreads(4);
    
    subTimer = tic;
    % Define template for per-subject output structures
    tmpPattern = struct('subID', [], 'atlas', [], 'task', []);
    tmpTask = struct('name', [], 'hem', [], 'pred', [], 'runlabels', []);
    tmpHem = struct('name', [], 'data', []);
    tmpData = struct('label', [], 'vertices', [], 'vertexCoord', [], 'ColorMap', [], 'pattern', [], 'contrast', []); 

    
    % First, get a list of parcels to keep, based on other atlases' STS.
    % This function is hyper-specific:
    % Only works if poifname is e.g. 'sub-04_lh_null_0001.annot.poi'
    % Checks for 'lh' or 'rh' at a specific position in the name string
    templatefname = 'nullTemplate.mat';
    templatePath = fullfile(p.basePath, templatefname);
    if exist(templatePath, 'file')
        load(templatePath);
    else
        % show a progress bar instead of printing a row for each null
        cntr = 0;
        progbar = waitbar(cntr,'Generating list of parcels to keep in each null model.');

        tic;
        for n = 1:numNulls
            for hemi = 1:2
                fpath = [p.baseDataPath 'sub-04/fs/sub-04-Surf2BV/'];
                poifname = ['sub-04_',hemstr{hemi},'_null_',num2str(n,'%04.f'),'.annot.poi'];
                templatePOI{n, hemi} = null_parcelNames([fpath poifname]); %compare against sub-04_lh_null_xxx1.poi

                % Increment progress bar across both hemis
                cntr = 2*(n-1) + hemi;
                waitbar(cntr/(2*numNulls), progbar);
            end % for hemi
        end % for null
        close(progbar)
        toc;

        % Export so we only need to calculate it once during debugging
        save(templatePath, 'templatePOI');
    end
    
    
    fprintf(1,'\n\nPROCESSING NULL MODELS FOR SUBJECTS\n\n')
    % Now, start processing nulls for each subject
    for sub = 1:NumSubs
        subj = subCell{sub};
        % get to proper location in individual subject folder
        subDir = fullfile(p.baseDataPath, 'deriv', subj);
        fsDir = fullfile(subDir, [subj, '-Freesurfer']);
        labelDir = fullfile(fsDir, subj, 'label');
        cd(labelDir)
        
        for null = 1:numNulls
            % Initialize output variable, one per model
            Pattern = tmpPattern;
            
%             % DEBUG LOGGING
%             profile on;
            
            for hemi = 1:2
                hem = hemstr{hemi};
                % set up proper files
                nullNum = ['null_', num2str(null, '%04.f')];
                nullfName = strcat(hemstr{hemi}, '.', nullNum, '.annot');
                nullfNameNoHem = [nullNum, '.annot'];
                gcsfName = strcat(hemstr{hemi}, '.', nullNum, '.gcs');
                
                % Print progress
                % Prefer fprintf here for logging/debugging
                fprintf(1,'%s %s %s\n',subj, hem, nullNum)
                
                
                if hemi == 1
                    % Initialize output
                    Pattern.subID = subj;
                    Pattern.atlas = nullNum;
                    Pattern.task = tmpTask;
                    Pattern.task(1).hem = tmpHem;
                end

                % make annotation file
%                 null_makeAnnot(subj,templatePOI{null, hemi}); %need gscfName here? (annots go into fs label dir)
                null_makeAnnot(subj,nullNum);
                                
                 % sanity check labeling, only continue if there are > 1 unique labels
                [~, l, ~] = read_annotation(nullfName); %might need path
                if length(unique(l)) == 1
                    fprintf(1, 'ERROR = %s has incorrect number of parcel labels. Aborting.\n', nullfName);
                    continue
                end

                % Convert annot to poi using modified version of fsSurf2BV
                Cfg.SUBJECTS_DIR = fsDir;
                Cfg.projectDir = Cfg.SUBJECTS_DIR;
                Cfg.atlas = nullfNameNoHem;
                Cfg.hemis = hemstr(hemi); % just one but keep it as a cell
                % Avoid writing POI to disk if an output var is specified
                subPOI = null_makePOI(subj, Cfg);
                
                
                % extract the subset of parcels that match the names of
                % those in the master list
                subPOI_STS = null_matchTemplatePOI(templatePOI{null, hemi}, subPOI);
                
                
                % extract the timeseries and compute betas for all possible
                % vertices, if it hasn't been done already
                if exist('betas', 'var') == 0
                    % Check whether a betas file exists
                    nullDir = fullfile(subDir, 'null_models');
                    betasfName = fullfile(nullDir, strcat(subj, '_betas.mat'));
                    if exist(betasfName, 'file')
                        fprintf(1,'\nLoading beta data from %s...', betasfName);
                        load(betasfName)
                        fprintf(1,'Done.\n')
                    else
                        % Build the betas file
                        % Check whether we have an timeseries file
                        mtcDatafName = fullfile(nullDir,strcat(subj, '_ts.mat'));
                        if exist(mtcDatafName, 'file') == 2
                            fprintf(1,'\nLoading timeseries data from %s...',mtcDatafName);
                            load(mtcDatafName);
                            fprintf(1,'Done.\n')
                        else
                            % Build the timeseries file
%                             masterVertList = ??;
                            % extract timeseries and predictors from MTCs
                            % takes a minute or two per subject
                            % Pulls data for both hemispheres
                            fprintf(1,'\nExtracting timeseries data from MTCs for %s...',subj);
                            mtcData = null_extractTS(subj); %try a whole hemi
                            fprintf(1,'Done.\n')
                            if ~exist(nullDir, 'dir')
                                mkdir(nullDir)
                            end
                            fprintf(1,'\nSaving timeseries data to %s...',mtcDatafName);
                            save(mtcDatafName, 'mtcData','-v7.3'); 
                            fprintf(1,'Done.\n')
                        end
                        % Calculate betas from timeseries data
                        % Do it for both hemispheres at once
                        % This avoids the headache of loop logic
                        fprintf(1,'\nCalculating betas for %s...',subj);
                        betas{1} = null_calcBetas(mtcData, 1);
                        betas{2} = null_calcBetas(mtcData, 2);
                        fprintf(1,'Done.\n')
                        
                        fprintf(1,'\nSaving beta data to %s...',betasfName);
                        save(betasfName, 'betas','-v7.3');
                        fprintf(1,'Done.\n')
                        clear mtcData
                    end
                end
                
                % organize vertices by parcel
                for task = 1:length(betas{hemi})
                    
                    % Initialize output struct
                    Pattern.task(task).name = betas{hemi}(task).task;
%                     Pattern.task(task).pred = betas{hemi}(task).pred;
                    Pattern.task(task).runlabels = betas{hemi}(task).labels;
                    
                    if task == 1
                        % Initialize this part once, not on each loop
                        % Necessary because loop structure doesn't match
                        Pattern.task(task).hem(hemi).name = hem;
                        Pattern.task(task).hem(hemi).data = tmpData;
                    end
                    
                    for parcel = 1:size(subPOI_STS, 2)
                        % Require name, vert ind, vert coord, and colormap
                        % Pattern is actually not needed at this point
                        Pattern.task(task).hem(hemi).data(parcel).label = subPOI_STS(parcel).Name;
                        Pattern.task(task).hem(hemi).data(parcel).vertices = subPOI_STS(parcel).Vertices;
                        Pattern.task(task).hem(hemi).data(parcel).vertexCoord = betas{hemi}(task).vertexCoords(subPOI_STS(parcel).Vertices);
                        Pattern.task(task).hem(hemi).data(parcel).ColorMap = subPOI_STS(task).Color;
%                         Pattern.task(task).hem(hemi).data(parcel).pattern = betas{hemi}(task).pattern(:, subPOI_STS(parcel).Vertices);
                        Pattern.task(task).hem(hemi).data(parcel).betaHat = betas{hemi}(task).betaHat(:,subPOI_STS(parcel).Vertices);
                        
                    end
                    % calculate metrics - Brandon can you verify these are
                    % reasonable
                    [colInd,negInd] = getConditionFromFilename(betas{hemi}(task).task);
%                     output{hemi}(task) = statSD(betas{hemi}(task),colInd,negInd);
                    Pattern.task(task).hem(hemi).data = statSD(Pattern.task(task).hem(hemi).data, colInd, negInd);
                    % Can't write back into 'betas' bc we added fields
    %                 [input] = statSD(input,posInd,negInd);
                end
                
                % OUTPUT STAGE - don't make a new loop just do it now
                if hemi == 2
                % Write the output variable to
                % ~/analysis/ROIs/STSX_atlas.mat
                % Needs to be in your old format, named Pattern
                % i.e. Pattern.task.hem.data
                % incl fields label vertices vertexCoord ColorMap
                
                outfname = [subj, '_', nullNum, '.mat'];
                outPath = fullfile(p.basePath, 'ROIs', outfname);
                
                fprintf(1,'\nWriting output file %s...',outfname);
                save(outPath, 'Pattern', '-v7.3');
                fprintf(1,'Done.\n');

                % Then just call the existing functions
                % ...except the loops on classSetup need to get flipped
                % bc it loads each subject's file for each atlas

                end

            end % for hemi
            
%             % DEBUG LOGGING
%             profinfo = profile('info');
%             profileoutput = fullfile(nullDir,nullNum);
%             profsave(profinfo, profileoutput);
%             profile('resume');
            
        end % for null
        clear betas % to ensure you don't use them for the next sub
    end % for sub
    
% Return max comp power for next stage, which needs parfor
maxNumCompThreads(dfltThreads); clear dfltThreads
toc(subTimer);
end


if doClassSetup == 1

    
    % Set up for classification analysis
    classSetup(subList, atlasList); % generate class files for beta metrics
    null_batchGLM(subList); % calculate whole-brain GLM
    subsetGLM(subList,atlasList); % index above with just the STS parcels
    diceBatch2(subList,atlasList); calculate "Dice", export to class file
% insert line for stdFC here
%     generateOmnibus(atlasList); aggregate all metrics into a single file
end


 % Once all subject metrics are computed, then you can run the classification
if RunClass == 1

    %run omnibus classification & save output somehow
    null_atlasClassify_Batch;


    % save overall classification accuracy distribution
    
    % Compare null accuracy to regular atlas accuract
end

