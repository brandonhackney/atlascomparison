function null_FCstd_byParcel(varargin)

% null_FCstd_byParcel([annotPrefix, subID])
%
% a revision of the data-based version, which started from Brandon's .mat
% files of timeseries. However, those patterns were lost as part of the
% streamlining for the null process. So this code goes back to extracts
% the timeseries again, then reorganizes by parcel for for each atlas.
% Saves it in a .mat file organized for classification analysis (without preprocessing).
%
% Optional inputs for the atlas annotation prefix (single or list) and
% subIDs to run (single or list). Both optional parameters should be
% entered as cells.

startTime = tic;
p = specifyPaths;


% figure out which atlases to use
if nargin > 0
    atlasList= varargin{1};
    numAtlas = length(atlasList);
else
    numNull = 1000; % set up number of null iterations
    for n = 1:numNull
        atlasList{n} = sprintf('null_%04.f',n);
    end
end
numAtlas = length(atlasList);
% figure out which subjects are being analyzed
if nargin > 1
    subList  = varargin{2};
else
    subList = {'STS1', 'STS2', 'STS3', 'STS4', 'STS5', 'STS6', 'STS7', 'STS8', 'STS10', 'STS11', 'STS14', 'STS17'};
end
% decide whether to randomize the timseries (quality check)
if nargin > 2
    assert(islogical(varargin{3}),'Third input must be logical true/false!')
    randomizer = varargin{3};
else
    randomizer = false;
end

% poi = cell(numAtlas, 2);
hemistr = {'lh', 'rh'};

% set up template file for STS parcel selection
% Relies on having run within null_master
templatePath = fullfile(p.basePath, 'nullTemplate.mat');
if exist(templatePath, 'file')
    templatePOI = importdata(templatePath);
    if ~isequal(size(templatePOI), [numAtlas 2])
        error('nullTemplate.mat does not match the requested atlasList; Try running null_master again.')
    end
else
    fprintf(1, '\nERROR: TEMPLATE FILE %s NOT FOUND \n', templatePath);
end

% set up output structure
hemiStruct = struct('parcelInfo', [], 'data', [], 'labels', []);


% BEGIN LOOPS

for atlas = 1:numAtlas

    atlasTimer = tic;
    atlasID = atlasList{atlas};
    
out = struct('subID', [], 'taskNames', [], 'hemi', hemiStruct);
% out = repmat(out, numAtlas, 1);
numSub = length(subList);
for sub = 1:size(subList, 2)
    
    subTimer = tic;
    
    % get the data
    % returns a numTasks x 2 cell with data structures within each one
    % inside the data structures are fields pattern, pred, contrast and task,
    % among others
    subID = subList{sub};
    fprintf(1, '\nLoading all the relevant timeseries. This will take about 20 sec...\n')
    subData = extractTS(subID);
    
    % This changes for each subject
%     poi = cell(numAtlas, 2);
    poi = cell(numSub, 2);
    
    %iterate through each task
    for task = 1:size(subData, 1)

        % iterate through hemis
        for h = 1:2

            hemi = hemistr{h};
            taskName = subData(task, h).task; %get the full text task name, just in case

            

            % get the timeseries out of the larger structure
            data = subData(task, h).pattern;

            % iterate through the atlases, for one hemi
%             for atlas = 1:numAtlas
% 
%                 atlasID = atlasList{atlas};

                %give minimal feedback
                if mod(atlas, 50) == 1, fprintf(1, '\tTask %i: %s (%s) iter %i... )\n', task, taskName, hemi, atlas); end

                % set up output
                if  sub == 1 & h == 1
%                     out(atlas).taskNames = strvcat(out(atlas).taskNames, taskName);
                    out.taskNames = strvcat(out.taskNames, taskName);
                end
                if task == 1 && h == 1
%                     out(atlas).subID = strvcat(out(atlas).subID, subID);
                    out.subID = strvcat(out.subID, subID);
                end



                % set up atlas, create poi from annot
                % This is different for each subject, so need to do each
                % time
%                 if isempty(poi{atlas, h})
                if isempty(poi{sub, h})
                    nullfName_nohemi = [atlasID, '.annot'];
                    Cfg.SUBJECTS_DIR = fullfile(p.deriv, subID, [subID, '-Freesurfer']);
                    Cfg.projectDir = Cfg.SUBJECTS_DIR;
                    Cfg.hemis = {hemi};
                    Cfg.atlas = nullfName_nohemi;
%                     poi{atlas, h} = null_makePOI(subID, Cfg); % nice function
                    poi{sub, h} = null_makePOI(subID, Cfg); % nice function
                end


                % select out the STS parcels
%                 poiSTS = matchTemplatePOI(templatePOI{atlas, h}, poi{atlas, h});
                poiSTS = matchTemplatePOI(templatePOI{atlas, h}, poi{sub, h});
                if task == 1
%                     out(atlas).hemi(h).parcelInfo = poiSTS;
                    out.hemi(h).parcelInfo = poiSTS;
                end
                numParcels = size(poiSTS, 2);


                stdFC = [];
                for parcel = 1:numParcels

                    %get timeseries and relevant preds
                    ts = data(:, poiSTS(parcel).Vertices);
                    if randomizer
                        % Randomize the timeseries, as a quality check
                        ts = random('Normal',mean(ts,'all'),std(ts,0,'all'),size(ts));
                    end
                    preds = subData(task,h).pred(:, subData(task, h).contrast{1});


                    % compute FC -- need to specify which preds to use
                    [~, stdFC(parcel)] = ComputeFC_byCond(ts, preds);

                end % for parcel

                % save to output structure
%                 out(atlas).hemi(h).data = [out(atlas).hemi(h).data; stdFC];
%                 out(atlas).hemi(h).labels = [out(atlas).hemi(h).labels; [sub task]];
                thisRow = nestedPosition(task,sub,numSub);
                out.hemi(h).data = [out.hemi(h).data; stdFC];
                out.hemi(h).labels = [out.hemi(h).labels; [sub task]];
                
%             end % for null
        end % for hem

    end % for task
    fprintf(1, '\n\n Subject %s finished! Time elapsed: %0.2f minutes\n', subID, toc(subTimer)/60);
    xff(0,'clearallobjects'); % prevent runaway memory usage
end % for sub


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%       save results
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% cd(p.classifyDataPath);
fprintf(1, 'Saving output files...')
% for atlas = 1:numAtlas
%     atlasName = atlasList{atlas};
    if randomizer
        atlasID = strcat(atlasID, 'RAND');
    end
    fOut = strcat('Classify_stdFC_', atlasID);
%     Data = out(atlas);
    Data = out;
    save(fullfile(p.classifyDataPath,fOut), 'Data');
    fprintf(1, '\n\nAtlas %s finished! Time elapsed: %0.2f hours\n', atlasID, toc(atlasTimer)/3600);
    
end % for atlas

fprintf(1, 'Done! (%0.2f hours)\n', toc(startTime)/3600);

